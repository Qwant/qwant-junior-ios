// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import Storage
import XCTest

class QwantTopSitesDataAdaptorTests: XCTestCase, FeatureFlaggable {
    
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
        let sut = createSut()
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 11, "Loading data on init, so we get 1 qwant site, 10 history sites")
    }
    
    func testNumberOfRows_default() {
        let sut = createSut()
        XCTAssertEqual(sut.numberOfRows, 2)
    }
    
    func testNumberOfRows_userChangedDefault() {
        profile.prefs.setInt(3, forKey: PrefsKeys.NumberOfTopSiteRows)
        let sut = createSut()
        XCTAssertEqual(sut.numberOfRows, 3)
    }
    
    // MARK: Qwant top site
    
    func testCalculateTopSitesData_hasQwantTopSite_qwantPrefsNil() {
        let sut = createSut()
        
        sut.recalculateTopSiteData(for: 6)
        
        // We test that without a pref, qwant is added
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantGUID)
        XCTAssertTrue(data[0].isQwantURL)
    }
    
    func testCalculateTopSitesData_hasQwantTopSiteWithPinnedCount_qwantPrefsNi() {
        let sut = createSut(addPinnedSiteCount: 3)
        
        sut.recalculateTopSiteData(for: 1)
        
        // We test that without a pref, qwant is added even with pinned tiles
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantGUID)
        XCTAssertTrue(data[0].isQwantURL)
    }
    
    func testCalculateTopSitesData_hasNotQwantTopSite_IfHidden() {
        let sut = createSut(addPinnedSiteCount: 3)
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteHideKey)
        
        sut.recalculateTopSiteData(for: 1)
        
        // We test that having more pinned than available tiles, qwant tile isn't put in
        let data = sut.getTopSitesData()
        XCTAssertFalse(data[0].isQwantURL)
        XCTAssertFalse(data[0].isQwantGUID)
    }
    
    // MARK: Pinned site
    
    func testCalculateTopSitesData_pinnedSites() {
        let sut = createSut(addPinnedSiteCount: 3)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 14)
        XCTAssertTrue(data[0].isPinned)
    }
    
    // MARK: Sponsored tiles
    
    func testLoadTopSitesData_hasDataAccountsForSponsoredTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteHideKey)
        
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(siteCount: 0, expectedContileResult: expectedContileResult)
        
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 0)
    }
    
    func testLoadTopSitesData_addSponsoredTile() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let sut = createSut(expectedContileResult: ContileResult.success(expectedContileResult))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 11, "Expects 1 qwant site, 0 contile, 10 history sites")
    }
    
    func testCalculateTopSitesData_addSponsoredTileAfterQwant() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1)
        let sut = createSut(expectedContileResult: ContileResult.success(expectedContileResult))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddSponsoredTileIfError() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.failure(ContileProvider.Error.failure)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddSponsoredTileIfSuccessEmpty() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success([])
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddMoreSponsoredTileThanMaximum() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        // Max contiles is currently at 0, so it should add 0 contiles only
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 3)
        let sut = createSut(expectedContileResult: ContileResult.success(expectedContileResult))
        
        sut.recalculateTopSiteData(for: 6)
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
        XCTAssertFalse(data[3].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddSponsoredTileIfDuplicatePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let sut = createSut(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_addSponsoredTileIfDuplicateIsNotPinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 1,
                                                                    duplicateFirstTile: true)
        let sut = createSut(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_addNextTileIfSponsoredTileIsDuplicate() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileProviderMock.getContiles(contilesCount: 2,
                                                                    duplicateFirstTile: true,
                                                                    pinnedDuplicateTile: true)
        let sut = createSut(addPinnedSiteCount: 1, expectedContileResult: ContileResult.success(expectedContileResult))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertEqual(data[1].title, String(format: ContileProviderMock.pinnedTitle, "0"))
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinned() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileResult.success([])
        let sut = createSut(addPinnedSiteCount: 12, expectedContileResult: expectedContileResult)
        
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.QwantTopSiteHideKey)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertFalse(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinnedAndQwantIsThere() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileResult.success([])
        let sut = createSut(addPinnedSiteCount: 11, expectedContileResult: expectedContileResult)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    func testSponsoredTileOrder_emptySites_addsAllContiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        var sites: [Site] = []
        sut.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 10)
        
        XCTAssertEqual(sites.count, 0, "Added zero contiles")
    }
    
    func testSponsoredTileOrder_emptySites_addsOneIfQwantIsThere() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        var sites: [Site] = []
        sut.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 2)
        
        XCTAssertEqual(sites.count, 0, "Added zero contile")
    }
    
    func testSponsoredTileOrder_withSites_addsAllContiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        var sites: [Site] = [Site(url: "www.test.com", title: "A test"),
                             Site(url: "www.test2.com", title: "A test2")]
        sut.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 10)
        
        XCTAssertEqual(sites.count, 2, "Added zero contiles and two sites")
        XCTAssertEqual(sites[0].title, "A test")
        XCTAssertEqual(sites[1].title, "A test2")
    }
    
    func testSponsoredTile_QwantTopSiteDoesntCountInSponsoredTilesCount_IfHidden() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        var sites: [Site] = []
        sut.addSponsoredTiles(sites: &sites, shouldAddGoogle: false, availableSpaceCount: 2)
        
        XCTAssertEqual(sites.count, 0, "Added zero contiles, no Qwant spot taken")
    }
    
    func testSponsoredTile_QwantTopSiteDoesntCountInSponsoredTilesCount_IfNotHidden() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let expectedContileResult = ContileResult.success(ContileProviderMock.defaultSuccessData)
        let sut = createSut(expectedContileResult: expectedContileResult)
        
        var sites: [Site] = []
        sut.addSponsoredTiles(sites: &sites, shouldAddGoogle: true, availableSpaceCount: 2)
        
        XCTAssertEqual(sites.count, 0, "Added zero contile, Qwant tile count is taken into account")
    }
    
    // MARK: Duplicates
    
    // Sponsored > Frequency
    func testDuplicates_SponsoredTileHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let sut = createSut(expectedContileResult: ContileResult.success([ContileProviderMock.duplicateTile]))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertEqual(data[1].title, ContileProviderMock.duplicateTile.name)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertFalse(data[2].isSponsoredTile)
    }
    
    // Pinned > Sponsored
    func testDuplicates_PinnedTilesHasPrecedenceOnSponsoredTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        
        let sut = createSut(addPinnedSiteCount: 1,
                            expectedContileResult: ContileResult.success([ContileProviderMock.pinnedDuplicateTile]))
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertTrue(data[0].isQwantURL)
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertTrue(data[1].isPinned)
        XCTAssertFalse(data[2].isSponsoredTile)
        XCTAssertFalse(data[2].isPinned)
    }
    
    // Pinned > Frequency
    func testDuplicates_PinnedTilesHasPrecedenceOnFrequencyTiles() {
        featureFlags.set(feature: .sponsoredTiles, to: true)
        let expectedPinnedURL = String(format: ContileProviderMock.url, "0")
        let sut = createSut(addPinnedSiteCount: 1, siteCount: 3, duplicatePinnedSiteURL: true)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 4, "Should have 3 sites and 1 pinned")
        XCTAssertTrue(data[0].isQwantURL)
        
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
        let sut = createSut(addPinnedSiteCount: 2, siteCount: 0)
        
        sut.recalculateTopSiteData(for: 6)
        
        let data = sut.getTopSitesData()
        XCTAssertEqual(data.count, 3, "Should have qwant site and 2 pinned sites")
        XCTAssertTrue(data[0].isQwantURL)
        
        XCTAssertFalse(data[1].isSponsoredTile)
        XCTAssertTrue(data[1].isPinned)
        XCTAssertEqual(data[1].site.url, "https://www.apinnedurl.com/pinned0")
        
        XCTAssertFalse(data[2].isSponsoredTile)
        XCTAssertTrue(data[2].isPinned)
        XCTAssertEqual(data[2].site.url, "https://www.apinnedurl.com/pinned1")
    }
}

// MARK: QwantTopSitesManagerTests
extension QwantTopSitesDataAdaptorTests {
    
    func createSut(addPinnedSiteCount: Int = 0,
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
        
        let sut = TopSitesDataAdaptorImplementation(profile: profile,
                                                    topSiteHistoryManager: historyStub,
                                                    googleTopSiteManager: googleManager,
                                                    contileProvider: contileProviderMock,
                                                    notificationCenter: notificationCenter,
                                                    dispatchGroup: dispatchGroup)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(historyStub, file: file, line: line)
        trackForMemoryLeaks(googleManager, file: file, line: line)
        trackForMemoryLeaks(dispatchGroup, file: file, line: line)
        
        return sut
    }
}

private extension TopSite {
    
    var isQwantGUID: Bool {
        return site.guid == QwantTopSiteManager.Constants.guid
    }
    
    var isQwantURL: Bool {
        return site.url == QwantTopSiteManager.Constants.url
    }
}
