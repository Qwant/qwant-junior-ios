// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import GCDWebServers
@testable import Client
import UIKit

import XCTest

class SearchTests: XCTestCase {
    func testParsing() {
        let parser = OpenSearchParser(pluginMode: true)
        let file = Bundle.main.path(forResource: "qwant-junior", ofType: "xml", inDirectory: "SearchPlugins/")
        let engine: OpenSearchEngine! = parser.parse(file!, engineID: "qwantjunior")
        XCTAssertEqual(engine.shortName, "Qwant Junior")

        // Test regular search queries.
        XCTAssertEqual(engine.searchURLForQuery("foobar")!.absoluteString, "https://www.qwantjunior.com/?q=foobar&client=qwantbrowser")

        // Test search suggestion queries.
        XCTAssertEqual(engine.suggestURLForQuery("foobar")!.absoluteString, "https://api.qwantjunior.com/api/suggest/?q=foobar&client=opensearch")
    }

    func testURIFixup() {
        // Check valid URLs. We can load these after some fixup.
        checkValidURL("http://www.mozilla.org", afterFixup: "http://www.mozilla.org")
        checkValidURL("about:config", afterFixup: "about:config")
        checkValidURL("about: config", afterFixup: "about:%20config")
        checkValidURL("file:///f/o/o", afterFixup: "file:///f/o/o")
        checkValidURL("ftp://ftp.mozilla.org", afterFixup: "ftp://ftp.mozilla.org")
        checkValidURL("foo.bar", afterFixup: "http://foo.bar")
        checkValidURL(" foo.bar ", afterFixup: "http://foo.bar")
        checkValidURL("1.2.3", afterFixup: "http://1.2.3")

        // Check invalid URLs. These are passed along to the default search engine.
        checkInvalidURL("foobar")
        checkInvalidURL("foo bar")
        checkInvalidURL("mozilla. org")
        checkInvalidURL("123")
        checkInvalidURL("a/b")
        checkInvalidURL("创业咖啡")
        checkInvalidURL("创业咖啡 中国")
        checkInvalidURL("创业咖啡. 中国")
        checkInvalidURL("about:")
        checkInvalidURL("javascript:")
        checkInvalidURL("javascript:alert(%22hi%22)")
        checkInvalidURL("ftp:")
        
    }

    func testURIFixupPunyCode() {
        checkValidURL("http://创业咖啡.中国/", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s/")
        checkValidURL("创业咖啡.中国", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s")
        checkValidURL(" 创业咖啡.中国 ", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s")
    }

    fileprivate func checkValidURL(_ beforeFixup: String, afterFixup: String) {
        XCTAssertEqual(URIFixup.getURL(beforeFixup)!.absoluteString, afterFixup)
    }

    fileprivate func checkInvalidURL(_ beforeFixup: String) {
        XCTAssertNil(URIFixup.getURL(beforeFixup))
    }

    func testSuggestClient() {
        let webServerBase = startMockSuggestServer()
        let engine = OpenSearchEngine(engineID: "mock", shortName: "Mock engine", image: UIImage(), searchTemplate: "", suggestTemplate: "\(webServerBase)?q={searchTerms}",
            isCustomEngine: false)
        let client = SearchSuggestClient(searchEngine: engine, userAgent: "Fx-testSuggestClient")

        let query1 = self.expectation(description: "foo query")
        client.query("foo", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                }

                XCTAssertEqual(response![0], "foo")
                XCTAssertEqual(response![1], "foo2")
                XCTAssertEqual(response![2], "foo you")

                query1.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)

        let query2 = self.expectation(description: "foo bar query")
        client.query("foo bar", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                }

                XCTAssertEqual(response![0], "foo bar soap")
                XCTAssertEqual(response![1], "foo barstool")
                XCTAssertEqual(response![2], "foo bartender")

                query2.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testExtractingOfSearchTermsFromURL() {
        let parser = OpenSearchParser(pluginMode: true)
        var file = Bundle.main.path(forResource: "qwant-junior", ofType: "xml", inDirectory: "SearchPlugins/")!
        let qwantJuniorEngine: OpenSearchEngine! = parser.parse(file, engineID: "qwantjunior")

        // create URL
        let searchTerm = "Foo Bar"
        let encodedSeachTerm = searchTerm.replacingOccurrences(of: " ", with: "+")
        let qwantSearchURL = URL(string: "https://qwant.com/?q=\(encodedSeachTerm)&client=qwantbrowser")
        let qwantJuniorSearchURL = URL(string: "https://qwantjunior.com/?q=\(encodedSeachTerm)&client=qwantbrowser")
        let invalidSearchURL = URL(string: "https://www.google.co.uk")
        
        // check it correctly matches qwant junior search term given qwant config
        XCTAssertEqual(searchTerm, qwantJuniorEngine.queryForSearchURL(qwantJuniorSearchURL))
        
        // check it doesn't match when the URL is not a search URL
        XCTAssertNil(qwantJuniorEngine.queryForSearchURL(invalidSearchURL))

        // check that it matches given a different configuration
        file = Bundle.main.path(forResource: "qwant", ofType: "xml", inDirectory: "SearchPlugins/")!
        let qwantEngine: OpenSearchEngine! = parser.parse(file, engineID: "qwant")
        XCTAssertEqual(searchTerm, qwantEngine.queryForSearchURL(qwantSearchURL))

        // check it doesn't match search URLs for different configurations
        XCTAssertNil(qwantEngine.queryForSearchURL(qwantJuniorSearchURL))

        // check that if you pass in a nil URL that everything works
        XCTAssertNil(qwantEngine.queryForSearchURL(nil))
    }

    fileprivate func startMockSuggestServer() -> String {
        let webServer: GCDWebServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            var suggestions: [String]!
            let query = request.query!["q"]!
            switch query {
            case "foo":
                suggestions = ["foo", "foo2", "foo you"]
            case "foo bar":
                suggestions = ["foo bar soap", "foo barstool", "foo bartender"]
            default:
                XCTFail("Unexpected query: \(query)")
            }
            return GCDWebServerDataResponse(jsonObject: [query, suggestions as Any])
        }

        if !webServer.start(withPort: 0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        return "http://localhost:\(webServer.port)"
    }
}
