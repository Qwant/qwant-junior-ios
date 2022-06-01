// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client

import XCTest

class TPStatsBlocklistsTests: XCTestCase {
    var blocklists: QwantTPStatsBlocklists!
    
    override func setUp() {
        super.setUp()
        
        blocklists = QwantTPStatsBlocklists()
    }
    
    override func tearDown() {
        super.tearDown()
        blocklists = nil
    }
    
    func testLoadPerformance() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            blocklists.load()
            self.stopMeasuring()
        }
    }
    
    func testURLInListPerformance() {
        blocklists.load()
        
        let safelistedRegexs = ["*google.com"].compactMap { (domain) -> String? in
            return wildcardContentBlockerDomainToRegex(domain: domain)
        }
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0..<100 {
                _ = blocklists.urlIsInList(URL(string: "https://www.firefox.com")!, mainDocumentURL: URL(string: "http://foo.com")!, safelistedDomains: safelistedRegexs)
            }
            self.stopMeasuring()
        }
    }
    
    func testURLInList() {
        blocklists.load()
        
        func blocklist(_ urlString: String, _ mainDoc: String = "https://foo.com", _ safelistedDomains: [String] = []) -> Bool {
            let safelistedRegexs = safelistedDomains.compactMap { (domain) -> String? in
                return wildcardContentBlockerDomainToRegex(domain: domain)
            }
            let mainDoc = URL(string: mainDoc)!
            return blocklists.urlIsInList(URL(string: urlString)!, mainDocumentURL: mainDoc, safelistedDomains: safelistedRegexs)
        }
        XCTAssertEqual(blocklist("https://www.facebook.com", "https://atlassolutions.com"), false)
        XCTAssertEqual(blocklist("https://www.firefox.com"), false)
        XCTAssertEqual(blocklist("https://wheredoyoucomefrom.ovh/malicious_tracker.js"), true)
        XCTAssertEqual(blocklist("https://sub.2leep.com/ad"), false)
        XCTAssertEqual(blocklist("https://admeld.com"), false)
        XCTAssertEqual(blocklist("https://admeld.com/popup"), false)
        XCTAssertEqual(blocklist("https://sub.admeld.com"), false)
        XCTAssertEqual(blocklist("https://xxxcounter.com"), true)
        XCTAssertEqual(blocklist("https://aol.com.aolanswers.com", "https://foo.com", ["ers.com"]), false)
        XCTAssertEqual(blocklist("https://sub.xiti.com/track"), true)
        XCTAssertEqual(blocklist("https://xlisting.jp"), true)
        XCTAssertEqual(blocklist("https://atlassolutions.com", "https://foo.com", ["*solutions.com"]), false)
    }
}
