// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// Convenience reference to these normal mode colors which are used in a few color classes.
private let defaultBackground = UIColor.Photon.DarkGrey60
private let defaultSeparator = UIColor.Photon.Grey60
private let defaultTextAndTint = UIColor.Photon.Grey10

private class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor { return UIColor.Photon.Grey70 } // layer2
    override var rowText: UIColor { return defaultTextAndTint } // textPrimary
    override var rowDetailText: UIColor { return UIColor.Photon.Grey30 }
    override var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
    override var separator: UIColor { return UIColor.Photon.Grey60 }
    override var headerBackground: UIColor { return UIColor.Photon.Grey80 }
    override var headerTextLight: UIColor { return UIColor.Photon.Grey30 } // textSecondary
    override var headerTextDark: UIColor { return UIColor.Photon.Grey30 }
    override var syncText: UIColor { return defaultTextAndTint }
    override var accessoryViewTint: UIColor { return UIColor.Photon.Grey40 } // actionSecondary
    override var selectedBackground: UIColor { return UIColor.Custom.selectedHighlightDark }
}

private class DarkActionMenuColor: ActionMenuColor {
    override var foreground: UIColor { return UIColor.Photon.White100 }
    override var iPhoneBackgroundBlurStyle: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
    override var iPhoneBackground: UIColor { return defaultBackground.withAlphaComponent(0.9) }
    override var closeButtonBackground: UIColor { return defaultBackground }
}

private class DarkURLBarColor: URLBarColor {
    override func textSelectionHighlight(_ isPrivate: Bool) -> TextSelectionHighlight {
        let color = isPrivate ? UIColor.Defaults.MobilePrivatePurple : UIColor(rgb: 0x3d89cc)
        return (labelMode: color.withAlphaComponent(0.25), textFieldMode: color)
    }

    override func activeBorder(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Blue20A40 : UIColor.Defaults.MobilePrivatePurple
    }
}

private class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return defaultBackground }
    override var tint: UIColor { return defaultTextAndTint }
}

// The back/forward/refresh/menu button (bottom toolbar)
private class DarkToolbarButtonColor: ToolbarButtonColor { }

private class DarkTabTrayColor: TabTrayColor {
    override var tabTitleText: UIColor { return defaultTextAndTint }
    override var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
    override var background: UIColor { return UIColor.Photon.DarkGrey80 }
    override var screenshotBackground: UIColor { return UIColor.Photon.DarkGrey30 }
    override var cellBackground: UIColor { return defaultBackground }
    override var toolbar: UIColor { return UIColor.Photon.Grey80 }
    override var toolbarButtonTint: UIColor { return defaultTextAndTint }
    override var cellCloseButton: UIColor { return defaultTextAndTint }
    override var cellTitleBackground: UIColor { return UIColor.Photon.Grey70 }
    override var faviconTint: UIColor { return UIColor.Photon.White100 }
    override var searchBackground: UIColor { return UIColor.Photon.Grey60 }
}

private class DarkEnhancedTrackingProtectionMenuColor: EnhancedTrackingProtectionMenuColor {
    override var defaultImageTints: UIColor { return defaultTextAndTint }
    override var background: UIColor { return UIColor.Photon.DarkGrey80 }
    override var sectionColor: UIColor { return UIColor.Photon.DarkGrey65 }
    override var switchAndButtonTint: UIColor { return UIColor.Photon.Blue20 }
    override var subtextColor: UIColor { return UIColor.Photon.LightGrey05 }
    override var closeButtonColor: UIColor { return UIColor.Photon.DarkGrey65 }
}

private class DarkTopTabsColor: TopTabsColor {
    override var background: UIColor { UIColor.Photon.DarkGrey80 }
    override var tabBackgroundSelected: UIColor { return UIColor.Photon.DarkGrey30 }
    override var tabBackgroundUnselected: UIColor { return UIColor.Photon.Grey80 }
    override var tabForegroundSelected: UIColor { return UIColor.Photon.Grey10 }
    override var tabForegroundUnselected: UIColor { return UIColor.Photon.Grey40 }
    override var closeButtonSelectedTab: UIColor { return tabForegroundSelected }
    override var closeButtonUnselectedTab: UIColor { return tabForegroundUnselected }
    override var separator: UIColor { return UIColor.Photon.Grey50 }
    override var buttonTint: UIColor { return UIColor.Photon.Grey10 }
}

private class DarkTextFieldColor: TextFieldColor {
    override var background: UIColor { return UIColor.Photon.DarkGrey80 }
    override var backgroundInOverlay: UIColor { return self.background }

    override var textAndTint: UIColor { return defaultTextAndTint }
    override var separator: UIColor { return super.separator.withAlphaComponent(0.3) }
}

private class DarkHomePanelColor: HomePanelColor {
    override var toolbarBackground: UIColor { return defaultBackground }
    override var toolbarHighlight: UIColor { return UIColor.Photon.Blue20 }
    override var toolbarTint: UIColor { return UIColor.Photon.Grey30 }
    override var topSiteHeaderTitle: UIColor { return UIColor.Photon.White100 }
    override var panelBackground: UIColor { return UIColor.Photon.Grey80 }
    override var separator: UIColor { return defaultSeparator }
    override var border: UIColor { return UIColor.Photon.Grey60 }
    override var buttonContainerBorder: UIColor { return separator }

    override var welcomeScreenText: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkIconBorder: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkFolderBackground: UIColor { return UIColor.Photon.Grey80 }
    override var bookmarkFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkCurrentFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkBackNavCellBackground: UIColor { return UIColor.Photon.Grey70 }

    override var activityStreamHeaderText: UIColor { return UIColor.Photon.LightGrey05 }
    override var activityStreamHeaderButton: UIColor { return UIColor.Photon.Blue20 }
    override var activityStreamCellTitle: UIColor { return UIColor.Photon.LightGrey05 }
    override var activityStreamCellDescription: UIColor { return UIColor.Photon.LightGrey50 }

    override var topSiteDomain: UIColor { return UIColor.Photon.LightGrey05 }
    override var topSitePin: UIColor { return UIColor.Photon.LightGrey05 }
    override var topSitesBackground: UIColor { return UIColor.Photon.DarkGrey60 }
    override var topSitesContainerView: UIColor { return UIColor.Photon.DarkGrey40 }
    override var emptyTopSitesBorder: UIColor { return .white }

    override var shortcutBackground: UIColor { return UIColor.Photon.DarkGrey30 }
    override var shortcutShadowColor: CGColor { return UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0).cgColor }

    override var recentlySavedBookmarkCellBackground: UIColor { return UIColor.Photon.DarkGrey40 }
    override var recentlySavedBookmarkImageBackground: UIColor { return UIColor.Photon.DarkGrey60 }
    override var recentlySavedBookmarkTitle: UIColor { return UIColor.Photon.LightGrey10 }

    override var recentlyVisitedCellGroupImage: UIColor { return .white }

    override var downloadedFileIcon: UIColor { return UIColor.Photon.Grey30 }

    override var historyHeaderIconsBackground: UIColor { return UIColor.clear }

    override var readingListActive: UIColor { return UIColor.Photon.Grey10 }
    override var readingListDimmed: UIColor { return UIColor.Photon.Grey40 }

    override var searchSuggestionPillBackground: UIColor { return UIColor.Photon.Grey70 }
    override var searchSuggestionPillForeground: UIColor { return defaultTextAndTint }

    override var customizeHomepageButtonBackground: UIColor { return UIColor.Photon.DarkGrey50 }
    override var customizeHomepageButtonText: UIColor { return UIColor.Photon.LightGrey10 }

    override var sponsored: UIColor { return UIColor.Photon.LightGrey40 }
}

private class DarkSnackBarColor: SnackBarColor {
// Use defaults
}

private class DarkGeneralColor: GeneralColor {
    override var settingsTextPlaceholder: UIColor { return UIColor.Photon.Grey40 }
    override var faviconBackground: UIColor { return UIColor.Photon.White100 }
    override var passcodeDot: UIColor { return UIColor.Photon.Grey40 }
    override var switchToggle: UIColor { return UIColor.Photon.Grey40 }
}

class DarkHomeTabBannerColor: HomeTabBannerColor {
    override var backgroundColor: UIColor { return UIColor.Photon.DarkGrey40 }
    override var textColor: UIColor { return UIColor.white }
    override var closeButtonBackground: UIColor { return UIColor.Photon.Grey80 }
    override var closeButton: UIColor { return UIColor.Photon.Grey20 }
}

class DarkOnboardingColor: OnboardingColor {
    override var backgroundColor: UIColor { return UIColor.Photon.DarkGrey40 }
    override var etpBackgroundColor: UIColor { return UIColor.Photon.DarkGrey40 }
    override var etpTextColor: UIColor { return UIColor.white }
    override var etpButtonColor: UIColor { return UIColor.Photon.Blue20 }
}

class DarkRemoteTabTrayColor: RemoteTabTrayColor {
    override var background: UIColor { return UIColor.Photon.Grey70 }
}

class DarkQwantVIPColor: QwantVIPColor {
    override var background: UIColor { return .black }
    override var sectionColor: UIColor { return UIColor(rgb: 0x212327) }
    override var textColor: UIColor { return .white }
    override var subtextColor: UIColor { return UIColor(rgb: 0xa7acb4) }
    override var greenText: UIColor { return UIColor(rgb: 0x57c78f) }
    override var redText: UIColor { return UIColor(rgb: 0xff5c5f) }
    override var blackText: UIColor { return UIColor(rgb: 0x050506) }
    override var horizontalLine: UIColor { return UIColor(rgb: 0x4b5058) }
    override var switchAndButtonTint: UIColor { return UIColor(rgb: 0x5c97ff) }
}

class LegacyDarkTheme: LegacyNormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var tableView: TableViewColor { return DarkTableViewColor() }
    override var urlbar: URLBarColor { return DarkURLBarColor() }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var toolbarButton: ToolbarButtonColor { return DarkToolbarButtonColor() }
    override var tabTray: TabTrayColor { return DarkTabTrayColor() }
    override var etpMenu: EnhancedTrackingProtectionMenuColor { return DarkEnhancedTrackingProtectionMenuColor() }
    override var topTabs: TopTabsColor { return DarkTopTabsColor() }
    override var textField: TextFieldColor { return DarkTextFieldColor() }
    override var homePanel: HomePanelColor { return DarkHomePanelColor() }
    override var snackbar: SnackBarColor { return DarkSnackBarColor() }
    override var general: GeneralColor { return DarkGeneralColor() }
    override var actionMenu: ActionMenuColor { return DarkActionMenuColor() }
    override var homeTabBanner: HomeTabBannerColor { return DarkHomeTabBannerColor() }
    override var onboarding: OnboardingColor { return DarkOnboardingColor() }
    override var remotePanel: RemoteTabTrayColor { return DarkRemoteTabTrayColor() }
    override var qwantVIP: QwantVIPColor { return DarkQwantVIPColor() }
}
