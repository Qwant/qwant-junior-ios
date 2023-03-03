// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

class HomeLogoHeaderViewModelTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        featureFlags.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testDefaultHomepageViewModelProtocolValues_qwantOverride() {
        let subject = createSubject()
        XCTAssertEqual(subject.sectionType, .logoHeader)
        XCTAssertEqual(subject.headerViewModel, LabelButtonHeaderViewModel.emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 1)
        XCTAssertFalse(subject.isEnabled)
    }
}

extension HomeLogoHeaderViewModelTests {
    func createSubject(file: StaticString = #file, line: UInt = #line) -> HomeLogoHeaderViewModel {
        let subject = HomeLogoHeaderViewModel(profile: profile, theme: LightTheme())
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

extension LabelButtonHeaderViewModel: Equatable {
    public static func == (lhs: LabelButtonHeaderViewModel, rhs: LabelButtonHeaderViewModel) -> Bool {
        return lhs.title == rhs.title && lhs.isButtonHidden == rhs.isButtonHidden
    }
}
