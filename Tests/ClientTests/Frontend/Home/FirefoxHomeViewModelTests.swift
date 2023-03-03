// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Clean user defaults to avoid having flaky test changing the section count
        // because message card reach max amount of impressions
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    // MARK: Number of sections

    func testNumberOfSection_withoutUpdatingData_has3Sections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile),
                                          theme: LightTheme())
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.messageCard)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.customizeHome)
    }
    
    func testNumberOfSection_withoutUpdatingData_has3Sections_qwantUpdate() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile),
                                          theme: LightTheme())
        XCTAssertEqual(viewModel.shownSections.count, 2)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.messageCard)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.customizeHome)
    }
}
