// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

public class QwantDefaultSiteImageFetcher: DefaultSiteImageFetcher {

    public override func getImage(urlStringRequest: String,
                                  type: SiteImageType,
                                  id: UUID,
                                  usesIndirectDomain: Bool) async -> SiteImageModel {

        var viewModel = await super.getImage(urlStringRequest: urlStringRequest,
                                             type: type,
                                             id: id,
                                             usesIndirectDomain: usesIndirectDomain)

        guard let url = viewModel.siteURL else { return viewModel }

        // Tweak for Qwant Maps favicon
        if url.normalizedHost == "qwant.com" && url.path.starts(with: "/maps") {
            let mapsIcon = Bundle.main.path(forResource: "TopSites/qwantmaps-com", ofType: "png")!
            viewModel.heroImage = UIImage(contentsOfFile: mapsIcon)
            viewModel.faviconImage = UIImage(contentsOfFile: mapsIcon)
        }

        return viewModel
    }
}
