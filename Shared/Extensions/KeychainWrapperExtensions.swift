// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import MozillaAppServices

private let log = Logger.keychainLogger

public extension MZKeychainWrapper {
    static var sharedClientAppContainerKeychain: MZKeychainWrapper {
        let baseBundleIdentifier = AppInfo.baseBundleIdentifier.replacingOccurrences(of: "junior", with: "")
        let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as! String
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)
        return MZKeychainWrapper(serviceName: baseBundleIdentifier, accessGroup: accessGroupIdentifier)
    }
}

public extension MZKeychainWrapper {
    func ensureClientStringItemAccessibility(_ accessibility: MZKeychainItemAccessibility, forKey key: String) {
        if self.hasValue(forKey: key) {
            if self.accessibilityOfKey(key) != .afterFirstUnlock {
                log.debug("updating item \(key) with \(accessibility)")

                guard let value = self.string(forKey: key) else {
                    log.error("failed to get item \(key)")
                    return
                }

                if !self.removeObject(forKey: key) {
                    log.warning("failed to remove item \(key)")
                }

                if !self.set(value, forKey: key, withAccessibility: accessibility) {
                    log.warning("failed to update item \(key)")
                }
            }
        }
    }

    func ensureDictonaryItemAccessibility(_ accessibility: MZKeychainItemAccessibility, forKey key: String) {
        if self.hasValue(forKey: key) {
            if self.accessibilityOfKey(key) != .afterFirstUnlock {
                log.debug("updating item \(key) with \(accessibility)")

                guard let value = self.object(forKey: key, ofClass: NSDictionary.self) else {
                    log.error("failed to get item \(key)")
                    return
                }

                if !self.removeObject(forKey: key) {
                    log.warning("failed to remove item \(key)")
                }

                if !self.set(value, forKey: key, withAccessibility: accessibility) {
                    log.warning("failed to update item \(key)")
                }
            }
        }
    }
}
