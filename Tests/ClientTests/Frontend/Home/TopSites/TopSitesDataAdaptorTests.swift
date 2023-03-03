// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import Storage
import XCTest

class TopSitesDataAdaptorTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!
    private var contileProviderMock: ContileProviderMock!
    private var notificationCenter: SpyNotificationCenter!

    override func setUp() {
        super.setUp()

        notificationCenter = SpyNotificationCenter()
        profile = MockProfile(databasePrefix: "FxHomeTopSitesManagerTests")
        profile.reopen()

        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        profile.prefs.clearAll()
    }

    override func tearDown() {
        super.tearDown()

        notificationCenter = nil
        contileProviderMock = nil
        profile.prefs.clearAll()
        profile.shutdown()
        profile = nil
    }

    func testData_whenNotLoaded() {
        let subject = createSubject()
        let data = subject.getTopSitesData()
        XCTAssertEqual(data.count, 11, "Loading data on init, so we get 1 google site, 10 history sites")
    }

    func testNumberOfRows_default() {
        let subject = createSubject()
        XCTAssertEqual(subject.numberOfRows, 2)
    }

    func testNumberOfRows_userChangedDefault() {
        profile.prefs.setInt(3, forKey: PrefsKeys.NumberOfTopSiteRows)
        let subject = createSubject()
        XCTAssertEqual(subject.numberOfRows, 3)
    }

    // MARK: Google top site

    func testCalculateTopSitesData_hasGoogleTopSite_googlePrefsNil() {
        let subject = createSubject()

        subject.recalculateTopSiteData(for: 6)

        // We test that without a pref, google is added
        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[0].isGoogleGUID)
    }

    func testCalculateTopSitesData_hasGoogleTopSiteWithPinnedCount_googlePrefsNi() {
        let subject = createSubject(addPinnedSiteCount: 3)

        subject.recalculateTopSiteData(for: 1)

        // We test that without a pref, google is added even with pinned tiles
        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[0].isGoogleGUID)
    }

    func testCalculateTopSitesData_hasNotGoogleTopSite_IfHidden() {
        let subject = createSubject(addPinnedSiteCount: 3)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        subject.recalculateTopSiteData(for: 1)

        // We test that having more pinned than available tiles, google tile isn't put in
        let data = subject.getTopSitesData()
        XCTAssertFalse(data[0].isGoogleURL)
        XCTAssertFalse(data[0].isGoogleGUID)
    }

    // MARK: Pinned site

    func testCalculateTopSitesData_pinnedSites() {
        let subject = createSubject(addPinnedSiteCount: 3)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertEqual(data.count, 14)
        XCTAssertTrue(data[0].isPinned)
    }

    // MARK: Sponsored tiles

    func testLoadTopSitesData_hasDataAccountsForSponsoredTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(siteCount: 0, expectedContileResult: expectedContileResult)

        let data = subject.getTopSitesData()
        XCTAssertNotEqual(data.count, 0)
    }

    func testLoadTopSitesData_addSponsoredTile() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let subject = createSubject(expectedContileResult: ContileResult.success(expectedContileResult))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertEqual(data.count, 12, "Expects 1 google site, 1 contile, 10 history sites")
    }

    func testCalculateTopSitesData_addSponsoredTileAfterGoogle() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let subject = createSubject(expectedContileResult: ContileResult.success(expectedContileResult))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfError() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.failure(ContileProvider.Error.failure)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfSuccessEmpty() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success([])
        let subject = createSubject(expectedContileResult: expectedContileResult)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddMoreSponsoredTileThanMaximum() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        // Max contiles is currently at 2, so it should add 2 contiles only
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 3)
        let subject = createSubject(expectedContileResult: ContileResult.success(expectedContileResult))

        subject.recalculateTopSiteData(for: 6)
        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[1].isSponsoredTile)
        XCTAssertTrue(data[2].isSponsoredTile)
        XCTAssertFalse(data[3].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfDuplicatePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let subject = createSubject(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))
        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_addSponsoredTileIfDuplicateIsNotPinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true)
        let subject = createSubject(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_addNextTileIfSponsoredTileIsDuplicate() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 2,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let subject = createSubject(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertTrue(data[1].isSponsoredTile)
        XCTAssertEqual(data[1].title, ContileProviderMock.defaultSuccessData[0].name)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success([])
        let subject = createSubject(addPinnedSiteCount: 12, expectedContileResult: expectedContileResult)

        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertFalse(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinnedAndGoogleIsThere() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success([])
        let subject = createSubject(addPinnedSiteCount: 11, expectedContileResult: expectedContileResult)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    func testSponsoredTileOrder_emptySites_addsAllContiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        var sites: [Site] = []
        subject.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 10)

        XCTAssertEqual(sites.count, 2, "Added two contiles")
        XCTAssertEqual(sites[0].title, "Firefox")
        XCTAssertEqual(sites[1].title, "Mozilla")
    }

    func testSponsoredTileOrder_emptySites_addsOneIfGoogleIsThere() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        var sites: [Site] = []
        subject.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 2)

        XCTAssertEqual(sites.count, 1, "Added one contile")
        XCTAssertEqual(sites[0].title, "Firefox")
    }

    func testSponsoredTileOrder_withSites_addsAllContiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        var sites: [Site] = [Site(url: "www.test.com", title: "A test"),
                             Site(url: "www.test2.com", title: "A test2")]
        subject.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 10)

        XCTAssertEqual(sites.count, 4, "Added two contiles and two sites")
        XCTAssertEqual(sites[0].title, "Firefox")
        XCTAssertEqual(sites[1].title, "Mozilla")
    }

    func testSponsoredTile_GoogleTopSiteDoesntCountInSponsoredTilesCount_IfHidden() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        var sites: [Site] = []
        subject.addSponsoredTiles(sites: &sites, shouldAddGoogle: false, availableSpaceCount: 2)

        XCTAssertEqual(sites.count, 2, "Added two contiles, no Google spot taken")
        XCTAssertEqual(sites[0].title, "Firefox")
        XCTAssertEqual(sites[1].title, "Mozilla")
    }

    func testSponsoredTile_GoogleTopSiteDoesntCountInSponsoredTilesCount_IfNotHidden() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let subject = createSubject(expectedContileResult: expectedContileResult)

        var sites: [Site] = []
        subject.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 2)

        XCTAssertEqual(sites.count, 1, "Added only one contile, Google tile count is taken into account")
        XCTAssertEqual(sites[0].title, "Firefox")
    }

    // MARK: Duplicates

    // Sponsored > Frequency
    func testDuplicates_SponsoredTileHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let subject = createSubject(expectedContileResult: ContileResult.success([ContileProviderMock.duplicateTile]))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertEqual(data[1].title, ContileProviderMock.duplicateTile.name)
        XCTAssertTrue(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }

    // Pinned > Sponsored
    func testDuplicates_PinnedTilesHasPrecedenceOnSponsoredTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)

        let subject = createSubject(addPinnedSiteCount: 1,
                                    expectedContileResult: ContileResult.success([ContileProviderMock.pinnedDuplicateTile]))

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertTrue(data[0].isGoogleURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertTrue(data[1].isPinned)
        XCTAssertFalse(data[2].isSponsoredTile)
        XCTAssertFalse(data[2].isPinned)
    }

    // Pinned > Frequency
    func testDuplicates_PinnedTilesHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedPinnedURL = String(format: ContileProviderMock.url, "0")
        let subject = createSubject(addPinnedSiteCount: 1, siteCount: 3, duplicatePinnedSiteURL: true)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertEqual(data.count, 4, "Should have 3 sites and 1 pinned")
        XCTAssertTrue(data[0].isGoogleURL)

        let tile1 = data[1]
        XCTAssertFalse(tile1.isSponsoredTile)
        XCTAssertTrue(tile1.isPinned)
        XCTAssertEqual(tile1.site.url, expectedPinnedURL)

        let tile2 = data[2]
        XCTAssertFalse(tile2.isSponsoredTile)
        XCTAssertFalse(tile2.isPinned)
        XCTAssertNotEqual(tile2.title, expectedPinnedURL)

        let tile3 = data[3]
        XCTAssertFalse(tile3.isSponsoredTile)
        XCTAssertFalse(tile3.isPinned)
        XCTAssertNotEqual(tile3.title, expectedPinnedURL)
    }

    // Pinned vs another Pinned of same domain
    func testDuplicates_PinnedTilesOfSameDomainIsntDeduped() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let subject = createSubject(addPinnedSiteCount: 2, siteCount: 0)

        subject.recalculateTopSiteData(for: 6)

        let data = subject.getTopSitesData()
        XCTAssertEqual(data.count, 3, "Should have google site and 2 pinned sites")
        XCTAssertTrue(data[0].isGoogleURL)

        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertTrue(data[1].isPinned)
        XCTAssertEqual(data[1].site.url, "https://www.apinnedurl.com/pinned0")

        XCTAssertFalse(data[2].isSponsoredTile)
        XCTAssertTrue(data[2].isPinned)
        XCTAssertEqual(data[2].site.url, "https://www.apinnedurl.com/pinned1")
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
    static let pinnedURL = "https://www.apinnedurl.com/pinned%@"
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

// MARK: TopSitesManagerTests
extension TopSitesDataAdaptorTests {
    func createSubject(addPinnedSiteCount: Int = 0,
                       siteCount: Int = 10,
                       duplicatePinnedSiteURL: Bool = false,
                       expectedContileResult: ContileResult = .success([]),
                       file: StaticString = #file,
                       line: UInt = #line) -> TopSitesDataAdaptorImplementation {
        let historyStub = TopSiteHistoryManagerStub(profile: profile)
        historyStub.siteCount = siteCount
        historyStub.addPinnedSiteCount = addPinnedSiteCount
        historyStub.duplicatePinnedSiteURL = duplicatePinnedSiteURL

        contileProviderMock = ContileProviderMock(result: expectedContileResult)

        let googleManager = QwantTopSiteManager(prefs: profile.prefs)
        let dispatchGroup = MockDispatchGroup()

        let subject = TopSitesDataAdaptorImplementation(profile: profile,
                                                        topSiteHistoryManager: historyStub,
                                                        googleTopSiteManager: googleManager,
                                                        contileProvider: contileProviderMock,
                                                        notificationCenter: notificationCenter,
                                                        dispatchGroup: dispatchGroup)

        trackForMemoryLeaks(subject, file: file, line: line)
        trackForMemoryLeaks(historyStub, file: file, line: line)
        trackForMemoryLeaks(googleManager, file: file, line: line)
        trackForMemoryLeaks(dispatchGroup, file: file, line: line)

        return subject
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
