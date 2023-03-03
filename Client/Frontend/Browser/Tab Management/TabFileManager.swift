// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol TabFileManager {
    func removeItem(at URL: URL) throws
    func fileExists(atPath path: String) -> Bool
    var tabPath: String? { get }
}

extension FileManager: TabFileManager {
    var tabPath: String? {
        return containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?
            .appendingPathComponent("profile.juniorprofile")
            .path
    }
}
