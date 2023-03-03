// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

public protocol Identifiable: Equatable {
    var id: Int? { get set }
}

public func == <T> (lhs: T, rhs: T) -> Bool where T: Identifiable {
    return lhs.id == rhs.id
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
open class Site: Identifiable {
    open var id: Int?
    open var guid: String?

    open var tileURL: URL {
        return URL(string: url)?.domainURL ?? URL(string: "about:blank")!
    }

    // i.e. `http://www.example.com/` --> `example`
    open var secondLevelDomain: String? {
        return URL(string: url)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public let url: String
    public let title: String
    open var metadata: PageMetadata?
    open var latestVisit: Visit?
    open fileprivate(set) var bookmarked: Bool?

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false, guid: nil)
    }

    public init(url: String, title: String, bookmarked: Bool?, guid: String? = nil) {
        self.url = url
        self.bookmarked = bookmarked
        self.guid = guid
        
        if url.asURL?.isQwantJuniorUrl == true {
            self.title = "Qwant Junior"
        } else if url.asURL?.isQwantHelpUrl == true {
            self.title = "Qwant Help"
        } else if url.asURL?.isMapsUrl == true {
            self.title = "Qwant Maps"
        } else if url.asURL?.isQwantUrl == true {
            self.title = "Qwant"
        } else {
            self.title = title
        }
    }

    open func setBookmarked(_ bookmarked: Bool) {
        self.bookmarked = bookmarked
    }
}

// MARK: - Hashable
extension Site: Hashable {
     public func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }

     public static func == (lhs: Site, rhs: Site) -> Bool {
         lhs.url == rhs.url
     }
 }
