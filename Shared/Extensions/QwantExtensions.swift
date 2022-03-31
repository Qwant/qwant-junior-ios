// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

public extension URL {
    
    private struct Constants {
        static let QWANT_DOMAIN = "qwant.com"
        static let CLIENT_CONTEXT_KEY = "client"
        static let CLIENT_CONTEXT_BROWSER = "qwantbrowser"
        static let CLIENT_CONTEXT_WIDGET = "qwantwidget"
    }
    
    /// Determines if the `client` context is missing as a query parameter of the URL.
    ///
    /// There are 2 cases to distinguish, the first one where the client context is actually really missing from the url
    /// as in `https://www.qwant.com?q=google` for example, but also when we can read through the
    /// user defaults that the app has been opened via the widget, and thus that we must override the default
    /// `qwantbrowser`with the `qwantwidget` in that case.
    var missesClientContext: Bool {
        guard self.host?.contains(Constants.QWANT_DOMAIN) == true else {
            return false
        }
        
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return true
        }
        
        let hasOpenedAppViaTheWidget = UserDefaults.standard.hasOpenedAppViaTheWidget
        let contextExists = components.queryItems?.first(where: { $0.name == Constants.CLIENT_CONTEXT_KEY }) != nil
        
        return hasOpenedAppViaTheWidget || !contextExists
    }
    
    /// Appends the client context as a query parameter to the URL, ensuring the URL is valid beforehand.
    ///
    /// Determines the context by checking first onto the user defaults to see if the client needs to have the widget context or the browser context.
    /// Then re-applies all query items, and re-write the client one with the correct context
    ///
    /// - Returns: the generated URL out of the re-written components
    fileprivate func appendClientContext() -> URL? {
        guard self.host?.contains(Constants.QWANT_DOMAIN) == true else {
            return self
        }
        
        let context = UserDefaults.standard.hasOpenedAppViaTheWidget ? Constants.CLIENT_CONTEXT_WIDGET : Constants.CLIENT_CONTEXT_BROWSER
        UserDefaults.standard.setHasOpenedAppViaTheWidget(false)
        
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = (components?.queryItems ?? []).filter ({ $0.name != Constants.CLIENT_CONTEXT_KEY })
        queryItems.append(URLQueryItem(name: Constants.CLIENT_CONTEXT_KEY, value: context))
        components?.queryItems = queryItems
        return components?.url
    }
}

public extension WKWebView {
    
    /// Relaunches the navigation in the webview by appending the context as a query parameter to the URL
    ///
    /// Stops the ongoing loading, and re-load an updated URL.
    func relaunchNavigationWithContext() {
        guard let url = self.url, let urlWithContext = url.appendClientContext() else {
            return
        }
        
        self.stopLoading()
        self.load(URLRequest(url: urlWithContext))
    }
}

public extension UserDefaults {

    private struct Constants {
        static let HAS_OPENED_APP_VIA_THE_WIDGET = "hasOpenedAppViaTheWidget"
    }
    
    var hasOpenedAppViaTheWidget: Bool {
        return bool(forKey: Constants.HAS_OPENED_APP_VIA_THE_WIDGET)
    }
    
    func setHasOpenedAppViaTheWidget(_ value: Bool) {
        setValue(value, forKey: Constants.HAS_OPENED_APP_VIA_THE_WIDGET)
    }
}
