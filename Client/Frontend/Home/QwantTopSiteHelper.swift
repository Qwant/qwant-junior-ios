// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Storage

struct QwantTopSiteConstants {
    // A guid is required in the case the site might become a pinned site
    public static let guid = "DefaultQwantGUID"
    public static let url = "https://www.qwant.com/?client=qwantbrowser"
}

class QwantTopSiteHelper {
    private var prefs: Prefs
    
    init(prefs: Prefs) {
        self.prefs = prefs
    }
    
    var hasAdded: Bool {
        get { return prefs.boolForKey(PrefsKeys.QwantTopSiteAddedKey) ?? false }
        set { prefs.setBool(newValue, forKey: PrefsKeys.QwantTopSiteAddedKey) }
    }
    
    var isHidden: Bool {
        get { return prefs.boolForKey(PrefsKeys.QwantTopSiteHideKey) ?? false }
        set { prefs.setBool(newValue, forKey: PrefsKeys.QwantTopSiteHideKey) }
    }
    
    func suggestedSiteData() -> PinnedSite? {
        return PinnedSite(site: Site(url: QwantTopSiteConstants.url,
                                     title: "Qwant",
                                     bookmarked: false,
                                     guid: QwantTopSiteConstants.guid))
    }
}

