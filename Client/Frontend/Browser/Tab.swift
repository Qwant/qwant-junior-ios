// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Storage
import Shared
import XCGLogger

fileprivate var debugTabCount = 0
fileprivate let log = Logger.browserLogger

func mostRecentTab(inTabs tabs: [Tab]) -> Tab? {
    var recent = tabs.first
    tabs.forEach { tab in
        if let time = tab.lastExecutedTime, time > (recent?.lastExecutedTime ?? 0) {
            recent = tab
        }
    }
    return recent
}

protocol TabContentScript {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String)
    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String)
    @objc optional func tab(_ tab: Tab, didCreateWebView webView: WKWebView)
    @objc optional func tab(_ tab: Tab, willDeleteWebView webView: WKWebView)
}

@objc
protocol URLChangeDelegate {
    func tab(_ tab: Tab, urlDidChangeTo url: URL)
}

struct TabState {
    var isPrivate: Bool = false
    var url: URL?
    var title: String?
    var favicon: Favicon?
}

public enum TabGroupTimerState: String, Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case none
}

enum TabUrlType: String {
    case regular
    case search
    case followOnSearch
    case organicSearch
    case googleTopSite
    case googleTopSiteFollowOn
}

class Tab: NSObject {

    static let privateModeKey = "PrivateModeKey"
    fileprivate var _isPrivate: Bool = false
    internal fileprivate(set) var isPrivate: Bool {
        get {
            return _isPrivate
        }
        set {
            if _isPrivate != newValue {
                _isPrivate = newValue
            }
        }
    }
    var urlType: TabUrlType = .regular
    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, url: url, title: displayTitle, favicon: displayFavicon)
    }
    
    var timerPerWebsite: [String: StopWatchTimer] = [:]
    
    // Tab Groups
    var tabGroupData: TabGroupData = TabGroupData(searchTerm: "", searchUrl: "", nextReferralUrl: "", tabHistoryCurrentState: TabGroupTimerState.none.rawValue , tabGroupTimerState: TabGroupTimerState.none.rawValue)
    
    struct TabGroupLastUpdatedObservation {
        var keyUrl: String?
        var referrerUrl: String?
        var searchTerm: String?
    }
    
    var lastObservation: TabGroupLastUpdatedObservation = TabGroupLastUpdatedObservation()
    var tabGroupsTimerHelper = StopWatchTimer()
    var shouldResetTabGroupData: Bool = false
    
    // PageMetadata is derived from the page content itself, and as such lags behind the
    // rest of the tab.
    var pageMetadata: PageMetadata?

    var readabilityResult: ReadabilityResult?

    var consecutiveCrashes: UInt = 0
    
    // Setting default page as topsites
    var newTabPageType: NewTabPage = .topSites
    var tabUUID: String = UUID().uuidString
    private var screenshotUUIDString: String?
    
    var screenshotUUID: UUID? {
        get {
            guard let uuidString = screenshotUUIDString else { return nil }
            return UUID(uuidString: uuidString)
        } set(value) {
            screenshotUUIDString = value?.uuidString ?? ""
        }
    }
    
    var adsTelemetryUrlList: [String] = [String]() {
        didSet {
            startingSearchUrlWithAds = url
        }
    }
    var adsTelemetryRedirectUrlList: [URL] = [URL]()
    var startingSearchUrlWithAds: URL?
    var adsProviderName: String = ""
    var hasHomeScreenshot: Bool = false

    // To check if current URL is the starting page i.e. either blank page or internal page like topsites
    var isURLStartingPage: Bool {
        guard url != nil else { return true }
        if url!.absoluteString.hasPrefix("internal://") {
            return true
        }
        return false
    }

    var canonicalURL: URL? {
        if let string = pageMetadata?.siteURL,
            let siteURL = URL(string: string) {

            // If the canonical URL from the page metadata doesn't contain the
            // "#" fragment, check if the tab's URL has a fragment and if so,
            // append it to the canonical URL.
            if siteURL.fragment == nil,
                let fragment = self.url?.fragment,
                let siteURLWithFragment = URL(string: "\(string)#\(fragment)") {
                return siteURLWithFragment
            }

            return siteURL
        }
        return self.url
    }

    var userActivity: NSUserActivity?
    var webView: WKWebView?
    var tabDelegate: TabDelegate?
    weak var urlDidChangeDelegate: URLChangeDelegate?     // TODO: generalize this.
    var bars = [SnackBar]()
    var favicons = [Favicon]() {
        didSet {
            updateFaviconCache()
        }
    }
    var lastExecutedTime: Timestamp?
    var firstCreatedTime: Timestamp?
    var sessionData: SessionData?
    fileprivate var lastRequest: URLRequest?
    var restoring: Bool = false
    var pendingScreenshot = false
    var url: URL? {
        didSet {
            if let _url = url, let internalUrl = InternalURL(_url), internalUrl.isAuthorized {
                url = URL(string: internalUrl.stripAuthorization)
            }
        }
    }
    var lastKnownUrl: URL? {
        // Tab url can be nil when user cold starts the app
        // thus we check session data for last known url
        guard self.url != nil else {
            return self.sessionData?.urls.last
        }
        return self.url
    }

    var isFxHomeTab: Bool {
        if let url = url, url.absoluteString.hasPrefix("internal://") { return true }
        return false
    }
    
    var isCustomHomeTab: Bool {
        guard let profile = self.browserViewController?.profile else { return false }
        
        if let customHomeUrl = HomeButtonHomePageAccessors.getHomePage(profile.prefs),
           let customHomeBaseDomain = customHomeUrl.baseDomain,
           let url = url,
           let baseDomain = url.baseDomain,
           baseDomain.hasPrefix(customHomeBaseDomain) {
            return true
        }
        return false
    }

    var mimeType: String?
    var isEditing: Bool = false
    var currentFaviconUrl: URL?
    // When viewing a non-HTML content type in the webview (like a PDF document), this URL will
    // point to a tempfile containing the content so it can be shared to external applications.
    var temporaryDocument: TemporaryDocument?

    /// Returns true if this tab's URL is known, and it's longer than we want to store.
    var urlIsTooLong: Bool {
        guard let url = self.url else {
            return false
        }
        return url.absoluteString.lengthOfBytes(using: .utf8) > AppConstants.DB_URL_LENGTH_MAX
    }

    // Use computed property so @available can be used to guard `noImageMode`.
    var noImageMode: Bool {
        didSet {
            guard noImageMode != oldValue else {
                return
            }

            contentBlocker?.noImageMode(enabled: noImageMode)

            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
        }
    }

    var nightMode: Bool {
        didSet {
            guard nightMode != oldValue else {
                return
            }

            webView?.evaluateJavascriptInDefaultContentWorld("window.__firefox__.NightMode.setEnabled(\(nightMode))")
            // For WKWebView background color to take effect, isOpaque must be false,
            // which is counter-intuitive. Default is true. The color is previously
            // set to black in the WKWebView init.
            webView?.isOpaque = !nightMode

            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
        }
    }

    var contentBlocker: FirefoxTabContentBlocker?

    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation.
    var changedUserAgent: Bool = false {
        didSet {
            if changedUserAgent != oldValue {
                TabEvent.post(.didToggleDesktopMode, for: self)
            }
        }
    }
    
    var readerModeAvailableOrActive: Bool {
        if let readerMode = self.getContentScript(name: "ReaderMode") as? ReaderMode {
            return readerMode.state != .unavailable
        }
        return false
    }

    fileprivate(set) var pageZoom: CGFloat = 1.0 {
        didSet {
            webView?.setValue(pageZoom, forKey: "viewScale")
        }
    }

    fileprivate(set) var screenshot: UIImage?

    // If this tab has been opened from another, its parent will point to the tab from which it was opened
    weak var parent: Tab?

    fileprivate var contentScriptManager = TabContentScriptManager()

    fileprivate let configuration: WKWebViewConfiguration

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    fileprivate var alertQueue = [JSAlertInfo]()

    weak var browserViewController: BrowserViewController?

    init(bvc: BrowserViewController, configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        self.configuration = configuration
        self.nightMode = false
        self.noImageMode = false
        self.browserViewController = bvc
        super.init()
        self.isPrivate = isPrivate
        debugTabCount += 1

        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .tab, value: isPrivate ? .privateTab : .normalTab)
    }
    
    func updateObservationForKey(key: HistoryMetadataKey, observation: HistoryMetadataObservation) {
        if let profile = self.browserViewController?.profile {
            _ = profile.places.noteHistoryMetadataObservation(key: key, observation: observation)
        }
    }

    func updateTimerAndObserving(state: TabGroupTimerState, searchTerm: String? = nil, searchProviderUrl: String? = nil, nextUrl: String = "") {
        switch state {
        case .navSearchLoaded:
            shouldResetTabGroupData = false
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabAssociatedSearchUrl = searchProviderUrl ?? ""
            tabGroupData.tabAssociatedSearchTerm = searchTerm ?? ""
            tabGroupData.tabAssociatedNextUrl = nextUrl
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .newTab:
            shouldResetTabGroupData = false
            tabGroupsTimerHelper.resetTimer()
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .tabNavigatedToDifferentUrl:
            if !tabGroupData.tabAssociatedNextUrl.isEmpty && tabGroupData.tabAssociatedSearchUrl.isEmpty || shouldResetTabGroupData {
                // reset tab group
                tabGroupData = TabGroupData(searchTerm: "", searchUrl: "", nextReferralUrl: "", tabHistoryCurrentState: TabGroupTimerState.none.rawValue , tabGroupTimerState: TabGroupTimerState.none.rawValue)
                shouldResetTabGroupData = true
            // To also capture any server redirects we check if user spent less than 7 sec on the same website before moving to another one
            } else if tabGroupData.tabAssociatedNextUrl.isEmpty || tabGroupsTimerHelper.elapsedTime < 7 {
                let key = tabGroupData.tabHistoryMetadatakey()
                if key.referrerUrl != nextUrl {
                    let observation = HistoryMetadataObservation(url: key.url, referrerUrl: key.referrerUrl, searchTerm: key.searchTerm, viewTime: tabGroupsTimerHelper.elapsedTime, documentType: nil, title: nil)
                    updateObservationForKey(key: key, observation: observation)
                    tabGroupData.tabAssociatedNextUrl = nextUrl
                }
                tabGroupsTimerHelper.resetTimer()
                tabGroupsTimerHelper.startOrResume()
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .tabSelected:
            if !shouldResetTabGroupData {
                if tabGroupsTimerHelper.isPaused {
                    tabGroupsTimerHelper.startOrResume()
                }
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .tabSwitched:
            if !shouldResetTabGroupData {
                let key = tabGroupData.tabHistoryMetadatakey()
                let observation = HistoryMetadataObservation(url: key.url, referrerUrl: key.referrerUrl, searchTerm: key.searchTerm, viewTime: tabGroupsTimerHelper.elapsedTime, documentType: nil, title: nil)
                updateObservationForKey(key: key, observation: observation)
                tabGroupsTimerHelper.pauseOrStop()
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .openInNewTab:
            shouldResetTabGroupData = false
            if let searchUrl = searchProviderUrl {
                tabGroupData.tabAssociatedSearchUrl = searchUrl
                tabGroupData.tabAssociatedSearchTerm = searchTerm ?? ""
                tabGroupData.tabAssociatedNextUrl = nextUrl
            }
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .none:
            tabGroupData.tabHistoryCurrentState = state.rawValue
        }
    }

    class func toRemoteTab(_ tab: Tab) -> RemoteTab? {
        if tab.isPrivate {
            return nil
        }

        if let displayURL = tab.url?.displayURL, RemoteTab.shouldIncludeURL(displayURL) {
            let history = Array(tab.historyList.filter(RemoteTab.shouldIncludeURL).reversed())
            return RemoteTab(clientGUID: nil,
                URL: displayURL,
                title: tab.displayTitle,
                history: history,
                lastUsed: Date.now(),
                icon: nil)
        } else if let sessionData = tab.sessionData, !sessionData.urls.isEmpty {
            let history = Array(sessionData.urls.filter(RemoteTab.shouldIncludeURL).reversed())
            if let displayURL = history.first {
                return RemoteTab(clientGUID: nil,
                    URL: displayURL,
                    title: tab.displayTitle,
                    history: history,
                    lastUsed: sessionData.lastUsedTime,
                    icon: nil)
            }
        }

        return nil
    }

    weak var navigationDelegate: WKNavigationDelegate? {
        didSet {
            if let webView = webView {
                webView.navigationDelegate = navigationDelegate
            }
        }
    }

    func createWebview() {
        if webView == nil {
            configuration.userContentController = WKUserContentController()
            configuration.allowsInlineMediaPlayback = true
            let webView = TabWebView(frame: .zero, configuration: configuration)
            webView.delegate = self

            webView.accessibilityLabel = .WebViewAccessibilityLabel
            webView.allowsBackForwardNavigationGestures = true
            webView.allowsLinkPreview = true

            // Night mode enables this by toggling WKWebView.isOpaque, otherwise this has no effect.
            webView.backgroundColor = .black

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            webView.navigationDelegate = navigationDelegate

            restore(webView)

            self.webView = webView
            configureEdgeSwipeGestureRecognizers()
            self.webView?.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
            tabDelegate?.tab?(self, didCreateWebView: webView)
        }
    }

    func restore(_ webView: WKWebView) {
        // Pulls restored session data from a previous SavedTab to load into the Tab. If it's nil, a session restore
        // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
        // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
        // to trigger the session restore via custom handlers
        if let sessionData = self.sessionData {
            restoring = true

            var urls = [String]()
            for url in sessionData.urls {
                urls.append(url.absoluteString)
            }

            let currentPage = sessionData.currentPage
            self.sessionData = nil
            var jsonDict = [String: AnyObject]()
            jsonDict["history"] = urls as AnyObject?
            jsonDict["currentPage"] = currentPage as AnyObject?
            
            guard let json = jsonDict.asString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return
            }

            if let restoreURL = URL(string: "\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)?history=\(json)") {
                let request = PrivilegedRequest(url: restoreURL) as URLRequest
                webView.load(request)
                lastRequest = request
            }
        } else if let request = lastRequest {
            webView.load(request)
        } else {
            print("creating webview with no lastRequest and no session data: \(self.url?.description ?? "nil")")
        }
    }

    deinit {
        debugTabCount -= 1

        #if DEBUG
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        func checkTabCount(failures: Int) {
            // Need delay for pool to drain.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if appDelegate.tabManager.remoteTabs.count == debugTabCount {
                    return
                }

                // If this assert has false positives, remove it and just log an error.
                assert(failures < 3, "Tab init/deinit imbalance, possible memory leak.")
                checkTabCount(failures: failures + 1)
            }
        }
        checkTabCount(failures: 0)
        #endif
    }
    
    /// When a user clears ALL history, `sessionData` and `historyList` need to be purged, and close the webView.
    func clearAndResetTabHistory() {
        guard let currentlyOpenUrl = lastKnownUrl ?? historyList.last else { return }
        
        url = currentlyOpenUrl
        sessionData = SessionData(currentPage: 0, urls: [currentlyOpenUrl], lastUsedTime: Date.now())
        historyList = [currentlyOpenUrl]
        webView = nil
        
        close()
    }

    func close() {
        contentScriptManager.uninstall(tab: self)

        webView?.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)

        if let webView = webView {
            tabDelegate?.tab?(self, willDeleteWebView: webView)
        }

        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }

    var loading: Bool {
        return webView?.isLoading ?? false
    }

    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }

    var backList: [WKBackForwardListItem]? {
        return webView?.backForwardList.backList
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView?.backForwardList.forwardList
    }

    var historyList: [URL] {
        get {
            func listToUrl(_ item: WKBackForwardListItem) -> URL { return item.url }
            
            var historyUrls = self.backList?.map(listToUrl) ?? [URL]()
            if let url = url {
                historyUrls.append(url)
            }
            return historyUrls
        }
        
        set { }
        
    }

    var title: String? {
        return webView?.title
    }

    var displayTitle: String {
        if let title = webView?.title, !title.isEmpty {
            let key = tabGroupData.tabHistoryMetadatakey()
            if lastObservation.keyUrl == key.url &&
                lastObservation.referrerUrl == key.referrerUrl &&
                lastObservation.searchTerm == key.searchTerm {
                return title
                
            } else if shouldUpdateObservation {
                let observation = HistoryMetadataObservation(url: key.url, referrerUrl: key.referrerUrl, searchTerm: key.searchTerm, viewTime: nil, documentType: nil, title: title)
                updateObservationForKey(key: key, observation: observation)
                lastObservation.keyUrl = key.url
                lastObservation.referrerUrl = key.referrerUrl
                lastObservation.searchTerm = key.searchTerm
            }
            return title
        }
        
        // When picking a display title. Tabs with sessionData are pending a restore so show their old title.
        // To prevent flickering of the display title. If a tab is restoring make sure to use its lastTitle.
        if let url = self.url, InternalURL(url)?.isAboutHomeURL ?? false, sessionData == nil, !restoring {
            return .AppMenuOpenHomePageTitleString
        }

        //lets double check the sessionData in case this is a non-restored new tab
        if let firstURL = sessionData?.urls.first, sessionData?.urls.count == 1, InternalURL(firstURL)?.isAboutHomeURL ?? false {
            return .AppMenuOpenHomePageTitleString
        }

        if let url = self.url, !InternalURL.isValid(url: url), let shownUrl = url.displayURL?.absoluteString {
            return shownUrl
        }

        guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
            return self.url?.displayURL?.absoluteString ??  ""
        }

        return lastTitle
    }
    
    var shouldUpdateObservation: Bool {
        tabGroupData.tabHistoryCurrentState == TabGroupTimerState.navSearchLoaded.rawValue ||
            tabGroupData.tabHistoryCurrentState == TabGroupTimerState.tabNavigatedToDifferentUrl.rawValue ||
            tabGroupData.tabHistoryCurrentState == TabGroupTimerState.openInNewTab.rawValue
    }

    var displayFavicon: Favicon? {
        return favicons.max { $0.width! < $1.width! }
    }

    var canGoBack: Bool {
        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        return webView?.canGoForward ?? false
    }

    func goBack() {
        _ = webView?.goBack()
    }

    func goForward() {
        _ = webView?.goForward()
    }

    func goToBackForwardListItem(_ item: WKBackForwardListItem) {
        _ = webView?.go(to: item)
    }

    @discardableResult func loadRequest(_ request: URLRequest) -> WKNavigation? {
        if let webView = webView {
            // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
            if let url = request.url, let syncedReaderModeURL = url.decodeReaderModeURL, let localReaderModeURL = syncedReaderModeURL.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
                let readerModeRequest = PrivilegedRequest(url: localReaderModeURL) as URLRequest
                lastRequest = readerModeRequest
                return webView.load(readerModeRequest)
            }
            lastRequest = request
            if let url = request.url, url.isFileURL, request.isPrivileged {
                return webView.loadFileURL(url, allowingReadAccessTo: url)
            }
            return webView.load(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        // If the current page is an error page, and the reload button is tapped, load the original URL
        if let url = webView?.url, let internalUrl = InternalURL(url), let page = internalUrl.originalURLFromErrorPage {
            webView?.replaceLocation(with: page)
            return
        }
        
        if let _ = webView?.reloadFromOrigin() {
            print("reloaded zombified tab from origin")
            return
        }

        if let webView = self.webView {
            print("restoring webView from scratch")
            restore(webView)
        }
    }
    
    @objc func reloadPage() {
        reload()
        self.webView?.scrollView.refreshControl?.endRefreshing()
    }
    

    @objc func zoomIn() {
        switch pageZoom {
        case 0.75:
            pageZoom = 0.85
        case 0.85:
            pageZoom = 1.0
        case 1.0:
            pageZoom = 1.15
        case 1.15:
            pageZoom = 1.25
        case 3.0:
            return
        default:
            pageZoom += 0.25
        }
    }

    @objc func zoomOut() {
        switch pageZoom {
        case 0.5:
            return
        case 0.85:
            pageZoom = 0.75
        case 1.0:
            pageZoom = 0.85
        case 1.15:
            pageZoom = 1.0
        case 1.25:
            pageZoom = 1.15
        default:
            pageZoom -= 0.25
        }
    }

    func resetZoom() {
        pageZoom = 1.0
    }

    func addContentScript(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScript(helper, name: name, forTab: self)
    }

    func addContentScriptToPage(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScriptToPage(helper, name: name, forTab: self)
    }

    func getContentScript(name: String) -> TabContentScript? {
        return contentScriptManager.getContentScript(name)
    }

    func hideContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = false
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 0.0
            })
        } else {
            webView?.alpha = 0.0
        }
    }

    func showContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = true
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 1.0
            })
        } else {
            webView?.alpha = 1.0
        }
    }

    func addSnackbar(_ bar: SnackBar) {
        if bars.count > 2 { return } // maximum 3 snackbars allowed on a tab
        bars.append(bar)
        tabDelegate?.tab(self, didAddSnackbar: bar)
    }

    func removeSnackbar(_ bar: SnackBar) {
        if let index = bars.firstIndex(of: bar) {
            bars.remove(at: index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        bars.reversed().forEach { removeSnackbar($0) }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        bars.reversed().filter({ !$0.shouldPersist(self) }).forEach({ removeSnackbar($0) })
    }

    func expireSnackbars(withClass snackbarClass: String) {
        bars.reversed().filter({ $0.snackbarClassIdentifier == snackbarClass }).forEach({ removeSnackbar($0) })
    }

    func setScreenshot(_ screenshot: UIImage?) {
        self.screenshot = screenshot
    }
    
    func toggleChangeUserAgent() {
        changedUserAgent = !changedUserAgent

        if changedUserAgent, let url = url?.withoutMobilePrefix() {
            let request = URLRequest(url: url)
            webView?.load(request)
        } else {
            reload()
        }

        TabEvent.post(.didToggleDesktopMode, for: self)
    }

    func queueJavascriptAlertPrompt(_ alert: JSAlertInfo) {
        alertQueue.append(alert)
    }

    func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
        guard !alertQueue.isEmpty else {
            return nil
        }
        return alertQueue.removeFirst()
    }

    func cancelQueuedAlerts() {
        alertQueue.forEach { alert in
            alert.cancel()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView, webView == self.webView,
            let path = keyPath, path == KVOConstants.URL.rawValue else {
            return assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
        guard let url = self.webView?.url else {
            return
        }
        
        guard !url.missesClientContext else {
            self.webView?.relaunchNavigationWithContext()
            return
        }

        self.urlDidChangeDelegate?.tab(self, urlDidChangeTo: url)
    }

    func isDescendentOf(_ ancestor: Tab) -> Bool {
        return sequence(first: parent) { $0?.parent }.contains { $0 == ancestor }
    }

    func observeURLChanges(delegate: URLChangeDelegate) {
        self.urlDidChangeDelegate = delegate
    }

    func removeURLChangeObserver(delegate: URLChangeDelegate) {
        if let existing = self.urlDidChangeDelegate, existing === delegate {
            self.urlDidChangeDelegate = nil
        }
    }

    func applyTheme() {
        UITextField.appearance().keyboardAppearance = isPrivate ? .dark : (LegacyThemeManager.instance.currentName == .dark ? .dark : .light)
    }
    
    func getProviderForUrl() -> SearchEngine {
        guard let url = self.webView?.url else {
            return .none
        }
        for provider in SearchEngine.allCases {
            if (url.absoluteString.contains(provider.rawValue)) {
                return provider
            }
        }
        return .none
    }
    
    func updateFaviconCache() {
        guard let displayFavicon = displayFavicon?.url, let faviconUrl = URL(string: displayFavicon), let baseDomain = url?.baseDomain else {
            return
        }

        if currentFaviconUrl == nil {
            currentFaviconUrl = faviconUrl
        } else if !faviconUrl.isEqual(currentFaviconUrl!) {
            return
        }
        
        FaviconFetcher.downloadFaviconAndCache(imageURL: currentFaviconUrl, imageKey: baseDomain)
    }
}

extension Tab: UIGestureRecognizerDelegate {
    // This prevents the recognition of one gesture recognizer from blocking another
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func configureEdgeSwipeGestureRecognizers() {
        guard let webView = webView else {
            log.info("Tab's edge swipe gesture recognizer was never added. This will affect Tab navigation telemetry!")
            return
        }
        
        let edgeSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipeTabNavigation(_:)))
        edgeSwipeGesture.edges = .left
        edgeSwipeGesture.delegate = self
        webView.addGestureRecognizer(edgeSwipeGesture)
    }
    
    @objc func handleEdgeSwipeTabNavigation(_ sender: UIScreenEdgePanGestureRecognizer) {
        guard let webView = webView else { return }
        
        if sender.state == .ended, (sender.velocity(in: webView).x > 150) {
            TelemetryWrapper.recordEvent(category: .action, method: .swipe, object: .navigateTabHistoryBackSwipe)
        }
    }
    
}

extension Tab: TabWebViewDelegate {
    fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }
    fileprivate func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView, didSelectSearchWithFirefoxForSelection selection: String) {
        tabDelegate?.tab(self, didSelectSearchWithFirefoxForSelection: selection)
    }
}

extension Tab: ContentBlockerTab {
    func currentURL() -> URL? {
        return url
    }

    func currentWebView() -> WKWebView? {
        return webView
    }

    func imageContentBlockingEnabled() -> Bool {
        return noImageMode
    }
}

private class TabContentScriptManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: TabContentScript]()

    // Without calling this, the TabContentScriptManager will leak.
    func uninstall(tab: Tab) {
        helpers.forEach { helper in
            if let name = helper.value.scriptMessageHandlerName() {
                tab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }
        }
    }

    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName(), scriptMessageHandlerName == message.name {
                helper.userContentController(userContentController, didReceiveScriptMessage: message)
                return
            }
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on a tab, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            tab.webView?.configuration.userContentController.addInDefaultContentWorld(scriptMessageHandler: self, name: scriptMessageHandlerName)
        }
    }

    func addContentScriptToPage(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on the page, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            tab.webView?.configuration.userContentController.addInPageContentWorld(scriptMessageHandler: self, name: scriptMessageHandlerName)
        }
    }

    func getContentScript(_ name: String) -> TabContentScript? {
        return helpers[name]
    }
}

private protocol TabWebViewDelegate: AnyObject {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
    func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView, didSelectSearchWithFirefoxForSelection selection: String)
}

class TabWebView: WKWebView, MenuHelperInterface {
    fileprivate weak var delegate: TabWebViewDelegate?

    // Updates the `background-color` of the webview to match
    // the theme if the webview is showing "about:blank" (nil).
    func applyTheme() {
        if url == nil {
            let backgroundColor = LegacyThemeManager.instance.current.browser.background.hexString
            evaluateJavascriptInDefaultContentWorld("document.documentElement.style.backgroundColor = '\(backgroundColor)';")
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) || action == MenuHelper.SelectorFindInPage
    }

    @objc func menuHelperFindInPage() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    @objc func menuHelperSearchWithFirefox() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebViewSearchWithFirefox(self, didSelectSearchWithFirefoxForSelection: selection)
        }
    }

    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        if #available(iOS 13.4, *) {
            // Do not becomeFirstResponder on a mouse event.
            if let event = event, event.allTouches?.contains(where: { $0.type != .indirectPointer }) ?? false {
                becomeFirstResponder()
            }
        } else {
            becomeFirstResponder()
        }

        return super.hitTest(point, with: event)
    }
    
    /// Override evaluateJavascript - should not be called directly on TabWebViews any longer
    // We should only be calling evaluateJavascriptInDefaultContentWorld in the future
    @available(*, unavailable, message:"Do not call evaluateJavaScript directly on TabWebViews, should only be called on super class")
    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
}

///
// Temporary fix for Bug 1390871 - NSInvalidArgumentException: -[WKContentView menuHelperFindInPage]: unrecognized selector
//
// This class only exists to contain the swizzledMenuHelperFindInPage. This class is actually never
// instantiated. It only serves as a placeholder for the method. When the method is called, self is
// actually pointing to a WKContentView. Which is not public, but that is fine, we only need to know
// that it is a UIView subclass to access its superview.
//

class TabWebViewMenuHelper: UIView {
    @objc func swizzledMenuHelperFindInPage() {
        if let tabWebView = superview?.superview as? TabWebView {
            tabWebView.evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
                let selection = result as? String ?? ""
                tabWebView.delegate?.tabWebView(tabWebView, didSelectFindInPageForSelection: selection)
            }
        }
    }
}

extension URL {
    /**
    Returns a URL without a mobile prefix (`"m."` or `"mobile."`)
    */
    func withoutMobilePrefix() -> URL {
        let subDomainsToRemove: Set<String> = ["m", "mobile"]

        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        guard let parts = components.host?.split(separator: ".").filter({ !subDomainsToRemove.contains(String($0)) }) else { return self }

        let host = parts.joined(separator: ".")

        guard host != publicSuffix else { return self }
        components.host = host

        return components.url ?? self
    }
}
