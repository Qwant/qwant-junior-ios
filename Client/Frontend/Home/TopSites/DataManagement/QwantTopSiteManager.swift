// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Storage

class QwantTopSiteManager {
    
    struct Constants {
        // A guid is required in the case the site might become a pinned site
        public static let guid = "DefaultQwantJuniorGUID"
        public static let url = "https://www.qwantjunior.com/"
   
        // The number of tiles taken by Qwant top site manager
        static let reservedSpaceCount = 1
    }
    
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
        let pinnedSite = PinnedSite(site: Site(url: Constants.url, title: "Qwant Junior"))
        pinnedSite.guid = Constants.guid
        return pinnedSite
    }
    
    // Once Qwant top site is added, we don't remove unless it's explicitly unpinned
    // Add it when pinned websites are less than max pinned sites
    func shouldAddQwantTopSite(hasSpace: Bool) -> Bool {
        let shouldShow = !isHidden && suggestedSiteData() != nil
        return shouldShow && (hasAdded || hasSpace)
    }
    
    func removeQwantTopSite(site: Site) {
        guard site.guid == Constants.guid else { return }
        isHidden = true
    }
    
    func addQwantTopSite(sites: inout [Site]) {
        guard let qwantSite = suggestedSiteData() else { return }
        sites.insert(qwantSite, at: 0)
        hasAdded = true
    }
}
