// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import Telemetry
import Glean

protocol OnViewDismissable: AnyObject {
    var onViewDismissed: (() -> Void)? { get set }
}

class DismissableNavigationViewController: UINavigationController, OnViewDismissable {
    var onViewDismissed: (() -> Void)?
    var onViewWillDisappear: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onViewWillDisappear?()
        onViewWillDisappear = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }
}

extension BrowserViewController: URLBarDelegate {
    func showTabTray(withFocusOnUnselectedTab tabToFocus: Tab? = nil,
                     focusedSegment: TabTrayViewModel.Segment? = nil) {
        updateFindInPageVisibility(visible: false)

        self.tabTrayViewController = TabTrayViewController(
            tabTrayDelegate: self,
            profile: profile,
            tabToFocus: tabToFocus,
            tabManager: tabManager,
            focusedSegment: focusedSegment)

        tabTrayViewController?.openInNewTab = { url, isPrivate in
            let tab = self.tabManager.addTab(URLRequest(url: url), afterTab: self.tabManager.selectedTab, isPrivate: isPrivate)
            // If we are showing toptabs a user can just use the top tab bar
            // If in overlay mode switching doesnt correctly dismiss the homepanels
            guard !self.topTabsVisible, !self.urlBar.inOverlayMode else { return }
            // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
            let viewModel = ButtonToastViewModel(labelText: .ContextMenuButtonToastNewTabOpenedLabelText,
                                                 buttonText: .ContextMenuButtonToastNewTabOpenedButtonText)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: self.themeManager.currentTheme,
                                    completion: { buttonPressed in
                if buttonPressed {
                    self.tabManager.selectTab(tab)
                }
            })
            self.show(toast: toast)
        }

        tabTrayViewController?.didSelectUrl = { url, visitType in
            guard let tab = self.tabManager.selectedTab else { return }
            self.finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
        }

        guard self.tabTrayViewController != nil else { return }

        let navigationController = ThemedDefaultNavigationController(rootViewController: tabTrayViewController!)
        navigationController.presentationController?.delegate = tabTrayViewController

        self.present(navigationController, animated: true, completion: nil)

        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .tabTray)

#if MOZ_CHANNEL_BETA
        let alert = UIAlertController(title: "User rating criteria",
                                      message: ratingPromptManager.debugMessage,
                                      preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "OK", style: .cancel) { _ in
            // App store review in-app prompt
            self.ratingPromptManager.showRatingPromptIfNeeded()
        }
        alert.addAction(dismiss)
        navigationController.present(alert, animated: true)
#else
        // App store review in-app prompt
        ratingPromptManager.showRatingPromptIfNeeded()
#endif
    }

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressShare(_ urlBar: URLBarView, shareView: UIView) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .awesomebarLocation,
                                     value: .awesomebarShareTap,
                                     extras: nil)

        if let selectedtab = tabManager.selectedTab, let tabUrl = selectedtab.canonicalURL?.displayURL {
            presentShareSheet(tabUrl,
                              tab: selectedtab,
                              sourceView: shareView,
                              sourceRect: CGRect.null,
                              arrowDirection: isBottomSearchBar ? .down : .up)
        }
    }

    func urlBarDidPressQRButton(_ urlBar: URLBarView) {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = self
        let controller = QRCodeNavigationController(rootViewController: qrCodeViewController)
        self.present(controller, animated: true, completion: nil)
    }

    func urlBarDidTapShield(_ urlBar: URLBarView) {
        if let tab = self.tabManager.selectedTab {
            let etpViewModel = QwantTPMenuVM(tab: tab, profile: profile, tabManager: tabManager)
            etpViewModel.onOpenSettingsTapped = {
                let settingsTableViewController = AppSettingsTableViewController(
                    with: self.profile,
                    and: self.tabManager,
                    delegate: self,
                    deeplinkingTo: .contentBlocker)

                let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
                controller.presentingModalViewControllerDelegate = self

                // Wait to present VC in an async dispatch queue to prevent a case where dismissal
                // of this popover on iPad seems to block the presentation of the modal VC.
                DispatchQueue.main.async {
                    self.present(controller, animated: true, completion: nil)
                }
            }

            let etpVC = QwantTPMenuVC(viewModel: etpViewModel)
            let controller = ThemedNavigationController(rootViewController: etpVC)
            if UIDevice.current.userInterfaceIdiom == .phone {
                controller.modalPresentationStyle = .pageSheet
                controller.transitioningDelegate = self
            } else {
                etpVC.asPopover = true
                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.sourceView = urlBar.locationView.trackingProtectionButton
                controller.popoverPresentationController?.permittedArrowDirections = .up
                controller.popoverPresentationController?.delegate = self
            }

            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .trackingProtectionMenu)
            self.present(controller, animated: true, completion: nil)
        }
    }

    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        showTabTray()
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        guard let tab = tabManager.selectedTab,
              let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode
        else { return }

        switch readerMode.state {
        case .available:
            enableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeOpenButton)
        case .active:
            disableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeCloseButton)
        case .unavailable:
            break
        }
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
              let url = tab.url?.displayURL
        else {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageGeneralErrorAccessibilityLabel)
            return false
        }

        let result = profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)

        switch result.value {
        case .success:
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageSuccessAcessibilityLabel)
            SimpleToast().showAlertWithText(.ShareAddToReadingListDone,
                                            bottomContainer: self.webViewContainer,
                                            theme: themeManager.currentTheme)
        case .failure(let error):
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageMaybeExistsErrorAccessibilityLabel)
            print("readingList.createRecordWithURL(url: \"\(url.absoluteString)\", ...) failed with error: \(error)")
        }
        return true
    }

    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(actions: [urlActions], closeButtonTitle: .CloseButtonTitle, modalStyle: style)
        presentSheetWith(viewModel: viewModel, on: self, from: button)
    }

    func locationActionsForURLBar(_ urlBar: URLBarView) -> [AccessibleAction] {
        if UIPasteboard.general.hasStrings {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.url
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let query = profile.searchEngines.queryForSearchURL(searchURL as URL?) {
            return (query, true)
        } else {
            return (url?.absoluteString, false)
        }
    }

    func urlBarDidLongPressLocation(_ urlBar: URLBarView) {
        let urlActions = self.getLongPressLocationBarActions(with: urlBar, webViewContainer: self.webViewContainer)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = UIDevice.current.userInterfaceIdiom != .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(actions: [urlActions], closeButtonTitle: .CloseButtonTitle, modalStyle: style)
        self.presentSheetWith(viewModel: viewModel, on: self, from: urlBar)
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        if let selectedTab = tabManager.selectedTab, homepageViewController == nil {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didRestoreText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
        }

        searchController?.searchQuery = text
        searchLoader?.setQueryWithoutAutocomplete(text)
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        urlBar.updateSearchEngineImage()
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
        }

        searchController?.searchQuery = text
        searchLoader?.query = text
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        guard let currentTab = tabManager.selectedTab else { return }

        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed, forTab: currentTab)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.firstIndex(of: " ") else {
            submitSearchText(text, forTab: currentTab)
            return
        }

        let possibleKeyword = String(trimmedText[..<possibleKeywordQuerySeparatorSpace])
        let possibleQuery = String(trimmedText[trimmedText.index(after: possibleKeywordQuerySeparatorSpace)...])

        profile.places.getBookmarkURLForKeyword(keyword: possibleKeyword).uponQueue(.main) { result in
            if var urlString = result.successValue ?? "",
                let escapedQuery = possibleQuery.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
                let range = urlString.range(of: "%s") {
                urlString.replaceSubrange(range, with: escapedQuery)

                if let url = URL(string: urlString) {
                    self.finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: currentTab)
                    return
                }
            }

            self.submitSearchText(text, forTab: currentTab)
        }
    }

    func submitSearchText(_ text: String, forTab tab: Tab) {
        let engine = profile.searchEngines.defaultEngine

        if let searchURL = engine.searchURLForQuery(text) {
            // We couldn't find a matching search keyword, so do a search query.
//            Telemetry.default.recordSearch(location: .actionBar, searchEngine: engine.engineID ?? "other")
            GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.actionBar.rawValue)"].add()
            searchTelemetry?.shouldSetUrlTypeSearch = true

            let searchData = TabGroupData(searchTerm: text,
                                          searchUrl: searchURL.absoluteString,
                                          nextReferralUrl: "")
            tab.metadataManager?.updateTimerAndObserving(state: .navSearchLoaded, searchData: searchData, isPrivate: tab.isPrivate)
            finishEditingAndSubmit(searchURL, visitType: VisitType.typed, forTab: tab)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            print("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
        }
    }

    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView) {
        urlBar.updateSearchEngineImage()
        guard let profile = profile as? BrowserProfile else { return }

        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: UIAccessibility.Notification.screenChanged)
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }

            showHomepage(inline: false)
        }
    }

    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView) {
        destroySearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
    }

    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView) {
        dismissVisibleMenus()
    }
}

extension BrowserViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let globalETPStatus = QwantSpecificTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs)
        return SlideOverPresentationController(presentedViewController: presented,
                                               presenting: presenting,
                                               withGlobalETPStatus: globalETPStatus)
    }
}
