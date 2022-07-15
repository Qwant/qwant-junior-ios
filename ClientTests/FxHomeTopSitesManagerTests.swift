// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import Storage
import XCTest

class FxHomeTopSitesManagerTests: XCTestCase, FeatureFlaggable {

    private var profile: MockProfile!
    private var contileProviderMock: ContileProviderMock!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "FxHomeTopSitesManagerTests")
        profile._reopen()

        profile.prefs.clearAll()
    }

    override func tearDown() {
        super.tearDown()

        contileProviderMock = nil
        profile.prefs.clearAll()
        profile._shutdown()
        profile = nil
    }

    func testEmptyData_whenNotLoaded() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertFalse(manager.hasData)
        XCTAssertEqual(manager.siteCount, 0)
    }

    func testEmptyData_getSites() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertNil(manager.getSite(index: 0))
        XCTAssertNil(manager.getSite(index: -1))
        XCTAssertNil(manager.getSite(index: 10))
        XCTAssertNil(manager.getSiteDetail(index: 0))
        XCTAssertNil(manager.getSiteDetail(index: -1))
        XCTAssertNil(manager.getSiteDetail(index: 10))
    }

    func testNumberOfRows_default() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 2)
    }

    func testNumberOfRows_userChangedDefault() {
        profile.prefs.setInt(3, forKey: PrefsKeys.NumberOfTopSiteRows)
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 3)
    }

    func testLoadTopSitesData_hasDataWithDefaultCalculation() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: nil) {
            XCTAssertTrue(manager.hasData)
            XCTAssertEqual(manager.siteCount, 11)
        }
    }

    func testLoadTopSitesData() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.hasData)
            XCTAssertEqual(manager.siteCount, 11)
        }
    }

    func testLoadTopSitesData_whenGetSites() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertNotNil(manager.getSite(index: 0))
            XCTAssertNil(manager.getSite(index: -1))
            XCTAssertNotNil(manager.getSite(index: 10))
            XCTAssertNil(manager.getSite(index: 15))

            XCTAssertNotNil(manager.getSiteDetail(index: 0))
            XCTAssertNil(manager.getSiteDetail(index: -1))
            XCTAssertNotNil(manager.getSiteDetail(index: 10))
            XCTAssertNil(manager.getSiteDetail(index: 15))
        }
    }

    // MARK: Google top site

    func testCalculateTopSitesData_hasGoogleTopSite_googlePrefsNil() {
        let manager = createManager()

        // We test that without a pref, google is added
        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertTrue(manager.getSite(index: 0)!.site.guid == QwantTopSiteManager.Constants.guid)
        }
    }

    func testCalculateTopSitesData_hasGoogleTopSiteWithPinnedCount_googlePrefsNi() {
        let manager = createManager(addPinnedSiteCount: 3)

        // We test that without a pref, google is added even with pinned tiles
        testLoadData(manager: manager, numberOfTilesPerRow: 1) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertTrue(manager.getSite(index: 0)!.site.guid == QwantTopSiteManager.Constants.guid)
        }
    }

    func testCalculateTopSitesData_hasNotGoogleTopSite_IfHidden() {
        let manager = createManager(addPinnedSiteCount: 3)

        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        // We test that having more pinned than available tiles, google tile isn't put in
        testLoadData(manager: manager, numberOfTilesPerRow: 1) {
            XCTAssertFalse(manager.getSite(index: 0)!.isGoogleURL)
            XCTAssertFalse(manager.getSite(index: 0)!.isGoogleGUID)
        }
    }

    // MARK: Pinned site

    func testCalculateTopSitesData_pinnedSites() {
        let manager = createManager(addPinnedSiteCount: 3)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.hasData)
            XCTAssertEqual(manager.siteCount, 14)
            XCTAssertTrue(manager.getSite(index: 0)!.isPinned)
        }
    }

    // MARK: Sponsored tiles

    func testLoadTopSitesData_addSponsoredTile() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let manager = createManager(expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.hasData)
            XCTAssertEqual(manager.siteCount, 11)
        }
    }

    func testCalculateTopSitesData_addSponsoredTileAfterGoogle() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let manager = createManager(expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfError() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.failure(ContileProvider.Error.failure)
        let manager = createManager(expectedContileResult: expectedContileResult)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfSuccessEmpty() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success([])
        let manager = createManager(expectedContileResult: expectedContileResult)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddMoreSponsoredTileThanMaximum() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        // Max contiles is currently at 2, so it should add 2 contiles only
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 3)
        let manager = createManager(expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 3)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfDuplicatePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let manager = createManager(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_addSponsoredTileIfDuplicateIsNotPinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true)
        let manager = createManager(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_addNextTileIfSponsoredTileIsDuplicate() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 2,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let manager = createManager(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success([])
        let manager = createManager(addPinnedSiteCount: 12, expectedContileResult: expectedContileResult)

        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertFalse(manager.getSite(index: 0)!.isGoogleURL)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinnedAndGoogleIsThere() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success([])
        let manager = createManager(addPinnedSiteCount: 11, expectedContileResult: expectedContileResult)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    // MARK: Duplicates

    // Sponsored > Frequency
    func testDuplicates_SponsoredTileHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let manager = createManager(expectedContileResult: ContileResult.success([ContileProviderMock.duplicateTile]))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertEqual(manager.getSite(index: 1)!.title, ContileProviderMock.duplicateTile.name)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
        }
    }

    // Pinned > Sponsored
    func testDuplicates_PinnedTilesHasPrecedenceOnSponsoredTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let manager = createManager(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success([ContileProviderMock.pinnedDuplicateTile]))

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)
            XCTAssertFalse(manager.getSite(index: 1)!.isSponsoredTile)
            XCTAssertTrue(manager.getSite(index: 1)!.isPinned)
            XCTAssertFalse(manager.getSite(index: 2)!.isSponsoredTile)
            XCTAssertFalse(manager.getSite(index: 2)!.isPinned)
        }
    }

    // Pinned > Frequency
    func testDuplicates_PinnedTilesHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedPinnedURL = String(format: ContileProviderMock.url, "0")
        let manager = createManager(addPinnedSiteCount: 1, siteCount: 3, duplicatePinnedSiteURL: true)

        testLoadData(manager: manager, numberOfTilesPerRow: 4) {
            XCTAssertEqual(manager.siteCount, 4, "Should have 3 sites and 1 pinned")
            XCTAssertTrue(manager.getSite(index: 0)!.site.url == QwantTopSiteManager.Constants.url)

            let tile1 = manager.getSite(index: 1)
            XCTAssertFalse(tile1!.isSponsoredTile)
            XCTAssertTrue(tile1!.isPinned)
            XCTAssertEqual(tile1!.site.url, expectedPinnedURL)

            let tile2 = manager.getSite(index: 2)
            XCTAssertFalse(tile2!.isSponsoredTile)
            XCTAssertFalse(tile2!.isPinned)
            XCTAssertNotEqual(tile2!.title, expectedPinnedURL)

            let tile3 = manager.getSite(index: 3)
            XCTAssertFalse(tile3!.isSponsoredTile)
            XCTAssertFalse(tile3!.isPinned)
            XCTAssertNotEqual(tile3!.title, expectedPinnedURL)
        }
    }

    func testTopSiteManager_hasNoLeaks() {
        let topSitesManager = FxHomeTopSitesManager(profile: profile)
        let historyStub = TopSiteHistoryManagerStub(profile: profile)
        historyStub.addPinnedSiteCount = 0
        topSitesManager.topSiteHistoryManager = historyStub

        trackForMemoryLeaks(historyStub)
        trackForMemoryLeaks(topSitesManager)
        trackForMemoryLeaks(topSitesManager.topSiteHistoryManager)
    }
}

// MARK: - ContileProviderMock
class ContileProviderMock: ContileProviderInterface {

    private var result: ContileResult

    static var defaultSuccessData: [Contile] {
        return [Contile(id: 1,
                        name: "Firefox",
                        url: "https://firefox.com",
                        clickUrl: "https://firefox.com/click",
                        imageUrl: "https://test.com/image1.jpg",
                        imageSize: 200,
                        impressionUrl: "https://test.com",
                        position: 1),
                Contile(id: 2,
                        name: "Mozilla",
                        url: "https://mozilla.com",
                        clickUrl: "https://mozilla.com/click",
                        imageUrl: "https://test.com/image2.jpg",
                        imageSize: 200,
                        impressionUrl: "https://example.com",
                        position: 2),
                Contile(id: 3,
                        name: "Focus",
                        url: "https://support.mozilla.org/en-US/kb/firefox-focus-ios",
                        clickUrl: "https://support.mozilla.org/en-US/kb/firefox-focus-ios/click",
                        imageUrl: "https://test.com/image3.jpg",
                        imageSize: 200,
                        impressionUrl: "https://another-example.com",
                        position: 3)]
    }

    init(result: ContileResult) {
        self.result = result
    }

    func fetchContiles(timestamp: Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        completion(result)
    }
}

extension ContileProviderMock {

    static func getContiles(contilesCount: Int,
                            duplicateFirstTile: Bool = false,
                            pinnedDuplicateTile: Bool = false) -> [Contile] {

        var defaultData = ContileProviderMock.defaultSuccessData

        if duplicateFirstTile {
            let duplicateTile = pinnedDuplicateTile ? ContileProviderMock.pinnedDuplicateTile : ContileProviderMock.duplicateTile
            defaultData.insert(duplicateTile, at: 0)
        }

        return Array(defaultData.prefix(contilesCount))
    }

    static let pinnedTitle = "A pinned title %@"
    static let pinnedURL = "https://www.apinnedurl%@.com"
    static let title = "A title %@"
    static let url = "https://www.aurl%@.com"

    static var pinnedDuplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: ContileProviderMock.pinnedTitle, "0"),
                       url: String(format: ContileProviderMock.pinnedURL, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageUrl: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }

    static var duplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: ContileProviderMock.title, "0"),
                       url: String(format: ContileProviderMock.url, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageUrl: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }
}

// MARK: FxHomeTopSitesManagerTests
extension FxHomeTopSitesManagerTests {

    func createManager(addPinnedSiteCount: Int = 0,
                       siteCount: Int = 10,
                       duplicatePinnedSiteURL: Bool = false,
                       expectedContileResult: ContileResult = .success([]),
                       file: StaticString = #file,
                       line: UInt = #line) -> FxHomeTopSitesManager {

        let topSitesManager = FxHomeTopSitesManager(profile: profile)

        let historyStub = TopSiteHistoryManagerStub(profile: profile)
        historyStub.siteCount = siteCount
        historyStub.addPinnedSiteCount = addPinnedSiteCount
        historyStub.duplicatePinnedSiteURL = duplicatePinnedSiteURL
        topSitesManager.topSiteHistoryManager = historyStub

        contileProviderMock = ContileProviderMock(result: expectedContileResult)
        topSitesManager.contileProvider = contileProviderMock

        trackForMemoryLeaks(topSitesManager, file: file, line: line)
        trackForMemoryLeaks(historyStub, file: file, line: line)
        trackForMemoryLeaks(topSitesManager.topSiteHistoryManager, file: file, line: line)

        return topSitesManager
    }

    func testLoadData(manager: FxHomeTopSitesManager, numberOfTilesPerRow: Int?, completion: @escaping () -> Void) {
        let expectation = expectation(description: "Top sites data should be loaded")

        manager.loadTopSitesData {
            if let numberOfTilesPerRow = numberOfTilesPerRow {
                manager.calculateTopSiteData(numberOfTilesPerRow: numberOfTilesPerRow)
            }
            completion()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}

// MARK: TopSiteHistoryManagerStub
class TopSiteHistoryManagerStub: TopSiteHistoryManager {

    override func getTopSites(completion: @escaping ([Site]) -> Void) {
        completion(createHistorySites())
    }

    var siteCount = 10
    var addPinnedSiteCount: Int = 0
    var duplicatePinnedSiteURL = false

    func createHistorySites() -> [Site] {
        var sites = [Site]()

        (0..<addPinnedSiteCount).forEach {
            let pinnedSiteURL = duplicatePinnedSiteURL ? String(format: ContileProviderMock.url, "\($0)"): String(format: ContileProviderMock.pinnedURL, "\($0)")
            let site = Site(url: pinnedSiteURL, title: String(format: ContileProviderMock.pinnedTitle, "\($0)"))
            sites.append(PinnedSite(site: site))
        }

        (0..<siteCount).forEach {
            let site = Site(url: String(format: ContileProviderMock.url, "\($0)"), title: String(format: ContileProviderMock.title, "\($0)"))
            sites.append(site)
        }

        return sites
    }
}
