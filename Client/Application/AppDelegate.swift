// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import CoreSpotlight
import UIKit
import Common

class AppDelegate: UIResponder, UIApplicationDelegate {
    private let log = Logger.browserLogger

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var orientationLock = UIInterfaceOrientationMask.all

    lazy var profile: Profile = BrowserProfile(
        localName: "profile",
        syncDelegate: UIApplication.shared.syncDelegate
    )
    lazy var tabManager: TabManager = TabManager(
        profile: profile,
        imageStore: DiskImageStore(
            files: profile.files,
            namespace: "TabManagerScreenshots",
            quality: UIConstants.ScreenshotQuality)
    )

    lazy var themeManager: ThemeManager = DefaultThemeManager()
    lazy var ratingPromptManager = RatingPromptManager(profile: profile)
    lazy var appSessionManager: AppSessionProvider = AppSessionManager()

    private var shutdownWebServer: DispatchSourceTimer?
    private var webServerUtil: WebServerUtil?
    private var appLaunchUtil: AppLaunchUtil?
    private var backgroundSyncUtil: BackgroundSyncUtil?
    private var widgetManager: TopSitesWidgetManager?
    private var menuBuilderHelper: MenuBuilderHelper?

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // It's important this is the first thing that happens when the app is run
        DependencyHelper().bootstrapDependencies()

        log.info("startApplication begin")

        appLaunchUtil = AppLaunchUtil(profile: profile)
        appLaunchUtil?.setUpPreLaunchDependencies()

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        webServerUtil = WebServerUtil(profile: profile)
        webServerUtil?.setUpWebServer()

        menuBuilderHelper = MenuBuilderHelper()

        log.info("startApplication end")

        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        pushNotificationSetup()
        appLaunchUtil?.setUpPostLaunchDependencies()
        backgroundSyncUtil = BackgroundSyncUtil(profile: profile, application: application)

        // Widgets are available on iOS 14 and up only.
        if #available(iOS 14.0, *) {
            let topSitesProvider = TopSitesProviderImplementation(
                placesFetcher: profile.places,
                pinnedSiteFetcher: profile.pinnedSites,
                prefs: profile.prefs
            )

            widgetManager = TopSitesWidgetManager(topSitesProvider: topSitesProvider)
        }

        addObservers()

        return true
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(_ application: UIApplication) {
        shutdownWebServer?.cancel()
        shutdownWebServer = nil

        profile.reopen()

        if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
            profile.removeAccount()
        }

        profile.syncManager.applicationDidBecomeActive()
        webServerUtil?.setUpWebServer()

        TelemetryWrapper.recordEvent(category: .action, method: .foreground, object: .app)

        // update top sites widget
        updateTopSitesWidget()

        // Cleanup can be a heavy operation, take it out of the startup path. Instead check after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.profile.cleanupHistoryIfNeeded()
            self?.ratingPromptManager.updateData()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        updateTopSitesWidget()

        UserDefaults.standard.setValue(Date(), forKey: "LastActiveTimestamp")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        TelemetryWrapper.recordEvent(category: .action, method: .background, object: .app)
        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        profile.syncManager.applicationDidEnterBackground()

        let singleShotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer. <500ms is expected on newer devices.
        singleShotTimer.schedule(deadline: .now() + 2.0, repeating: .never)
        singleShotTimer.setEventHandler {
            WebServer.sharedInstance.server.stop()
            self.shutdownWebServer = nil
        }
        singleShotTimer.resume()
        shutdownWebServer = singleShotTimer
        backgroundSyncUtil?.scheduleSyncOnAppBackground()
        tabManager.preserveTabs()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        profile.shutdown()
    }

    private func updateTopSitesWidget() {
        // Since we only need the topSites data in the archiver, let's write it
        // only if iOS 14 is available.
        if #available(iOS 14.0, *) {
            widgetManager?.writeWidgetKitTopSites()
        }
    }
}

extension AppDelegate: Notifiable {
    private func addObservers() {
        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification,
                                                          UIApplication.willResignActiveNotification,
                                                          UIApplication.didEnterBackgroundNotification])
    }

    /// When migrated to Scenes, these methods aren't called. Consider this a tempoary solution to calling into those methods.
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            applicationDidBecomeActive(UIApplication.shared)
        case UIApplication.willResignActiveNotification:
            applicationWillResignActive(UIApplication.shared)
        case UIApplication.didEnterBackgroundNotification:
            applicationDidEnterBackground(UIApplication.shared)

        default: break
        }
    }
}

// This functionality will need to be moved to the SceneDelegate when the time comes
extension AppDelegate {
    // Orientation lock for views that use new modal presenter
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
}

// MARK: - Key Commands

extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .main else { return }

        menuBuilderHelper?.mainMenu(for: builder)
    }
}

// MARK: - Scenes related methods
extension AppDelegate {
    /// UIKit is responsible for creating & vending Scene instances. This method is especially useful when there
    /// are multiple scene configurations to choose from.  With this method, we can select a configuration
    /// to create a new scene with dynamically (outside of what's in the pList).
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )

        configuration.sceneClass = connectingSceneSession.configuration.sceneClass
        configuration.delegateClass = connectingSceneSession.configuration.delegateClass

        return configuration
    }
}

extension UIApplication {
    static var isInPrivateMode: Bool {
        return BrowserViewController.foregroundBVC()?.tabManager.selectedTab?.isPrivate ?? false
    }
}
