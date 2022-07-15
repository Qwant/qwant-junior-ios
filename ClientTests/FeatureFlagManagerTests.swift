// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

class FeatureFlagManagerTests: XCTestCase, FeatureFlaggable {

    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testExpectedCoreFeatures() {
        let adjustSetting = featureFlags.isCoreFeatureEnabled(.adjustEnvironmentProd)
        let mockDataSetting = featureFlags.isCoreFeatureEnabled(.useMockData)
        let contileAPISetting = featureFlags.isCoreFeatureEnabled(.useStagingContileAPI)

        XCTAssertTrue(adjustSetting) // Qwant: Activated
        XCTAssertFalse(mockDataSetting) // Qwant: Deactivated
        XCTAssertFalse(contileAPISetting) // Qwant: Deactivated
    }

    func testDefaultNimbusBoolFlags() {
        // Tests for default settings should be performed on both build and user
        // prefs separately to ensure that we are getting the expected results on both.
        // Technically, at this stage, these should be the same.
        XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.pocket, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.pocket, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .userOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.searchHighlights, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.searchHighlights, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly)) // Qwant: Deactivated
        XCTAssertFalse(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .userOnly)) // Qwant: Deactivated
        XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .userOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly)) // Qwant: Deactivated
    }

    func testDefaultNimbusCustomFlags() {
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
    }

    // Changing the prefs manually, to make sure settings are respected through
    // the FFMs interface
    func testManagerRespectsProfileChangesForBoolSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        // Changing the prefs manually, to make sure settings are respected through
        // the FFMs interface
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.JumpBackInSection)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
    }

    // Changing the prefs manually, to make sure settings are respected through
    // the FFMs interface
    func testManagerRespectsProfileChangesForCustomSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        mockProfile.prefs.setString(SearchBarPosition.top.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)

        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        mockProfile.prefs.setString(StartAtHomeSetting.always.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.always)
    }

    func testManagerInterfaceForUpdatingBoolFlags() {
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        featureFlags.set(feature: .jumpBackIn, to: false)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
    }

    func testManagerInterfaceForUpdatingCustomFlags() {
        // Search Bar
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.top)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)

        // StartAtHome
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.always)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.always)
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.disabled)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.disabled)
    }

    func testStartAtHomeBoolean() {
        // Ensure defaults are operating correctly
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
        XCTAssertEqual(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly), featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        // Now simulate user toggling to different settings
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.always)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.disabled)
        XCTAssertFalse(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.afterFourHours)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
    }
}
