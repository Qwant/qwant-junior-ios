// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

// New keys should follow the name: "[nameOfTheFeature]Key" written with camel case
public struct PrefsKeys {
    // When this pref is set (by the user) it overrides default behaviour which is just based on app locale.
    public static let KeyEnableChinaSyncService = "useChinaSyncService"
    public static let KeyLastRemoteTabSyncTime = "lastRemoteTabSyncTime"
    public static let KeyLastSyncFinishTime = "lastSyncFinishTime"
    public static let KeyDefaultHomePageURL = "KeyDefaultHomePageURL"
    public static let KeyNoImageModeStatus = "NoImageModeStatus"
    public static let KeyMailToOption = "MailToOption"
    public static let HasFocusInstalled = "HasFocusInstalled"
    public static let HasPocketInstalled = "HasPocketInstalled"
    public static let IntroSeen = "IntroViewControllerSeenv2"
    public static let HomePageTab = "HomePageTab"
    public static let HomeButtonHomePageURL = "HomeButtonHomepageURL"
    public static let NumberOfTopSiteRows = "NumberOfTopSiteRows"
    public static let LoginsSaveEnabled = "saveLogins"
    public static let LoginsShowShortcutMenuItem = "showLoginsInAppMenu"
    public static let KeyInstallSession = "installSessionNumber"
    public static let KeyDefaultBrowserCardShowType = "defaultBrowserCardShowType"
    public static let DidDismissDefaultBrowserMessage = "DidDismissDefaultBrowserCard"
    public static let KeyDidShowDefaultBrowserOnboarding = "didShowDefaultBrowserOnboarding"
    public static let ContextMenuShowLinkPreviews = "showLinkPreviews"
    public static let NewTabCustomUrlPrefKey = "HomePageURLPref"
    public static let GoogleTopSiteAddedKey = "googleTopSiteAddedKey"
    public static let GoogleTopSiteHideKey = "googleTopSiteHideKey"
    public static let QwantTopSiteAddedKey = "qwantTopSiteAddedKey"
    public static let QwantTopSiteHideKey = "qwantTopSiteHideKey"
    public static let SessionCount = "sessionCount"
    public static let InstallType = "InstallType"
    public static let KeyCurrentInstallVersion = "KeyCurrentInstallVersion"
    public static let KeySecondRun = "SecondRun"

    public struct AppVersion {
        public static let Latest = "latestAppVersion"
    }

    public struct Wallpapers {
        public static let MetadataLastCheckedDate = "WallpaperMetadataLastCheckedUserPrefsKey"
        public static let CurrentWallpaper = "CurrentWallpaperUserPrefsKey"
        public static let ThumbnailsAvailable = "ThumbnailsAvailableUserPrefsKey"
        public static let OnboardingSeenKey = "WallpaperOnboardingSeenKeyUserPrefsKey"

        public static let legacyAssetMigrationCheck = "legacyAssetMigrationCheckUserPrefsKey"
        public static let v1MigrationCheck = "v1MigrationCheckUserPrefsKey"
    }

    // For ease of use, please list keys alphabetically.
    public struct FeatureFlags {
        public static let ASPocketStories = "ASPocketStoriesUserPrefsKey"
        public static let ASSponsoredPocketStories = "ASSponsoredPocketStoriesUserPrefsKey"
        public static let CustomWallpaper = "CustomWallpaperUserPrefsKey"
        public static let HistoryHighlightsSection = "HistoryHighlightsSectionUserPrefsKey"
        public static let HistoryGroups = "HistoryGroupsUserPrefsKey"
        public static let InactiveTabs = "InactiveTabsUserPrefsKey"
        public static let JumpBackInSection = "JumpBackInSectionUserPrefsKey"
        public static let PullToRefresh = "PullToRefreshUserPrefsKey"
        public static let RecentlySavedSection = "RecentlySavedSectionUserPrefsKey"
        public static let SearchBarPosition = "SearchBarPositionUsersPrefsKey"
        public static let StartAtHome = "StartAtHomeUserPrefsKey"
        public static let SponsoredShortcuts = "SponsoredShortcutsUserPrefsKey"
        public static let TabTrayGroups = "TabTrayGroupsUserPrefsKey"
        public static let TopSiteSection = "TopSitesUserPrefsKey"
    }

    public struct LegacyFeatureFlags {
        public static let ASPocketStories = "ASPocketStoriesVisible"
        public static let CustomWallpaper = "customWallpaperPrefKey"
        public static let HistoryHighlightsSection = "historyHighlightsSectionEnabled"
        public static let HistoryGroups = "historyGroupsEnabled"
        public static let InactiveTabs = "KeyInactiveTabs"
        public static let JumpBackInSection = "jumpBackInSectionEnabled"
        public static let PullToRefresh = "pullToRefresh"
        public static let RecentlySavedSection = "recentlySavedSectionEnabled"
        public static let KeySearchBarPosition = "SearchBarPosition"
        public static let StartAtHome = "startAtHome"
        public static let TabTrayGroups = "KeyEnableGroupedTabsKey"
        public static let SponsoredShortcuts = "sponsoredShortcutsKey"
        public static let TopSiteSection = "topSitesKey"

        public static let MigrationCheck = "MigrationCheck"
        public static let WallpaperDirectoryMigrationCheck = "WallpaperDirectoryMigrationCheck"
    }

    // Firefox contextual hint
    public enum ContextualHints: String, CaseIterable {
        case jumpBackinKey = "ContextualHintJumpBackin"
        case jumpBackInConfiguredKey = "JumpBackInConfigured"
        case jumpBackInSyncedTabKey = "ContextualHintJumpBackInSyncedTab"
        case jumpBackInSyncedTabConfiguredKey = "JumpBackInSyncedTabConfigured"
        case inactiveTabsKey = "ContextualHintInactiveTabs"
        case toolbarOnboardingKey = "ContextualHintToolbarOnboardingKey"
    }

    // Activity Stream
    public static let KeyTopSitesCacheIsValid = "topSitesCacheIsValid"
    public static let KeyTopSitesCacheSize = "topSitesCacheSize"
    public static let KeyNewTab = "NewTabPrefKey"
    public static let ASLastInvalidation = "ASLastInvalidation"
    public static let KeyUseCustomSyncTokenServerOverride = "useCustomSyncTokenServerOverride"
    public static let KeyCustomSyncTokenServerOverride = "customSyncTokenServerOverride"
    public static let KeyUseCustomFxAContentServer = "useCustomFxAContentServer"
    public static let KeyCustomFxAContentServer = "customFxAContentServer"
    public static let UseStageServer = "useStageSyncService"
    public static let KeyFxALastCommandIndex = "FxALastCommandIndex"
    public static let KeyFxAHandledCommands = "FxAHandledCommands"
    public static let AppExtensionTelemetryOpenUrl = "AppExtensionTelemetryOpenUrl"
    public static let AppExtensionTelemetryEventArray = "AppExtensionTelemetryEvents"
    public static let KeyBlockPopups = "blockPopups"

    // Tabs Tray
    public static let KeyInactiveTabsModel = "KeyInactiveTabsModelKey"
    public static let KeyInactiveTabsFirstTimeRun = "KeyInactiveTabsFirstTimeRunKey"
    public static let KeyTabDisplayOrder = "KeyTabDisplayOrderKey"

    // Widgetkit Key
    public static let WidgetKitSimpleTabKey = "WidgetKitSimpleTabKey"
    public static let WidgetKitSimpleTopTab = "WidgetKitSimpleTopTab"

    // WallpaperManager Keys - Legacy
    public static let WallpaperManagerCurrentWallpaperObject = "WallpaperManagerCurrentWallpaperObject"
    public static let WallpaperManagerCurrentWallpaperImage = "WallpaperManagerCurrentWallpaperImage"
    public static let WallpaperManagerCurrentWallpaperImageLandscape = "WallpaperManagerCurrentWallpaperImageLandscape"
    public static let WallpaperManagerLogoSwitchPreference = "WallpaperManagerLogoSwitchPreference"

    // Application Services migrated to Places DB Successfully
    public static let PlacesHistoryMigrationSucceeded = "PlacesHistoryMigrationSucceeded"

    // The number of times we have attempted the Application Services to Places DB migration
    public static let HistoryMigrationAttemptNumber = "HistoryMigrationAttemptNumber"

    // The last timestamp we polled FxA for missing send tabs
    public static let PollCommandsTimestamp = "PollCommandsTimestamp"
}

public struct PrefsDefaults {
    public static let ChineseHomePageURL = "https://mobile.firefoxchina.cn/?ios"
    public static let ChineseNewTabDefault = "HomePage"
}

public protocol Prefs {
    func getBranchPrefix() -> String
    func branch(_ branch: String) -> Prefs
    func setTimestamp(_ value: Timestamp, forKey defaultName: String)
    func setLong(_ value: UInt64, forKey defaultName: String)
    func setLong(_ value: Int64, forKey defaultName: String)
    func setInt(_ value: Int32, forKey defaultName: String)
    func setString(_ value: String, forKey defaultName: String)
    func setBool(_ value: Bool, forKey defaultName: String)
    func setObject(_ value: Any?, forKey defaultName: String)
    func stringForKey(_ defaultName: String) -> String?
    func objectForKey<T: Any>(_ defaultName: String) -> T?
    func boolForKey(_ defaultName: String) -> Bool?
    func intForKey(_ defaultName: String) -> Int32?
    func timestampForKey(_ defaultName: String) -> Timestamp?
    func longForKey(_ defaultName: String) -> Int64?
    func unsignedLongForKey(_ defaultName: String) -> UInt64?
    func stringArrayForKey(_ defaultName: String) -> [String]?
    func arrayForKey(_ defaultName: String) -> [Any]?
    func dictionaryForKey(_ defaultName: String) -> [String: Any]?
    func removeObjectForKey(_ defaultName: String)
    func clearAll()
}

open class MockProfilePrefs: Prefs {
    let prefix: String

    open func getBranchPrefix() -> String {
        return self.prefix
    }

    // Public for testing.
    open var things = NSMutableDictionary()

    public init(things: NSMutableDictionary, prefix: String) {
        self.things = things
        self.prefix = prefix
    }

    public init() {
        self.prefix = ""
    }

    open func branch(_ branch: String) -> Prefs {
        return MockProfilePrefs(things: self.things, prefix: self.prefix + branch + ".")
    }

    private func name(_ name: String) -> String {
        return self.prefix + name
    }

    open func setTimestamp(_ value: Timestamp, forKey defaultName: String) {
        self.setLong(value, forKey: defaultName)
    }

    open func setLong(_ value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(value: value as UInt64), forKey: defaultName)
    }

    open func setLong(_ value: Int64, forKey defaultName: String) {
        setObject(NSNumber(value: value as Int64), forKey: defaultName)
    }

    open func setInt(_ value: Int32, forKey defaultName: String) {
        things[name(defaultName)] = NSNumber(value: value as Int32)
    }

    open func setString(_ value: String, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func setBool(_ value: Bool, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func setObject(_ value: Any?, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func stringForKey(_ defaultName: String) -> String? {
        return things[name(defaultName)] as? String
    }

    open func boolForKey(_ defaultName: String) -> Bool? {
        return things[name(defaultName)] as? Bool
    }

    open func objectForKey<T: Any>(_ defaultName: String) -> T? {
        return things[name(defaultName)] as? T
    }

    open func timestampForKey(_ defaultName: String) -> Timestamp? {
        return unsignedLongForKey(defaultName)
    }

    open func unsignedLongForKey(_ defaultName: String) -> UInt64? {
        return things[name(defaultName)] as? UInt64
    }

    open func longForKey(_ defaultName: String) -> Int64? {
        return things[name(defaultName)] as? Int64
    }

    open func intForKey(_ defaultName: String) -> Int32? {
        return things[name(defaultName)] as? Int32
    }

    open func stringArrayForKey(_ defaultName: String) -> [String]? {
        if let arr = self.arrayForKey(defaultName) {
            if let arr = arr as? [String] {
                return arr
            }
        }
        return nil
    }

    open func arrayForKey(_ defaultName: String) -> [Any]? {
        let r: Any? = things.object(forKey: name(defaultName)) as Any?
        if r == nil {
            return nil
        }
        if let arr = r as? [Any] {
            return arr
        }
        return nil
    }

    open func dictionaryForKey(_ defaultName: String) -> [String: Any]? {
        return things.object(forKey: name(defaultName)) as? [String: Any]
    }

    open func removeObjectForKey(_ defaultName: String) {
        self.things.removeObject(forKey: name(defaultName))
    }

    open func clearAll() {
        let dictionary = things as! [String: Any]
        let keysToDelete: [String] = dictionary.keys.filter { $0.hasPrefix(self.prefix) }
        things.removeObjects(forKeys: keysToDelete)
    }
}
