// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class QwantAdjustTelemetryHelperTests: XCTestCase {
    
    var telemetryHelper: AdjustTelemetryHelper!
    
    override func setUp() {
        super.setUp()
        
        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
        
        // Setup mock profile
        telemetryHelper = AdjustTelemetryHelper()
    }
    
    override func tearDown() {
        super.tearDown()
        telemetryHelper = nil
    }
    
    func testFailSetAttribution_WithNilData() {
        // Submit the ping.
        let attribution = MockAdjustTelemetryData(campaign: nil)
        telemetryHelper.setAttributionData(attribution)
        
        XCTAssertNil(GleanMetrics.Adjust.campaign.testGetValue())
        XCTAssertNil(GleanMetrics.Adjust.adGroup.testGetValue())
        XCTAssertNil(GleanMetrics.Adjust.creative.testGetValue())
        XCTAssertNil(GleanMetrics.Adjust.network.testGetValue())
    }
    
    func testFirstSessionPing() {
        GleanMetrics.Adjust.campaign.set("campaign")
        GleanMetrics.Adjust.adGroup.set("adGroup")
        GleanMetrics.Adjust.creative.set("creative")
        GleanMetrics.Adjust.network.set("network")
        
        let expectation = expectation(description: "The first session ping was sent")
        
        GleanMetrics.Pings.shared.firstSession.testBeforeNextSubmit { _ in
            
            XCTAssertNil(GleanMetrics.Adjust.campaign.testGetValue())
            XCTAssertNil(GleanMetrics.Adjust.adGroup.testGetValue())
            XCTAssertNil(GleanMetrics.Adjust.creative.testGetValue())
            XCTAssertNil(GleanMetrics.Adjust.network.testGetValue())
            expectation.fulfill()
        }
        
        // Submit the ping.
        GleanMetrics.Pings.shared.firstSession.submit()
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testDeeplinkHandleEvent_GleanCalled() {
        guard let url = URL(string: "https://testurl.com") else {
            XCTFail("Url should be build correctly")
            return
        }
        
        let mockData = MockAdjustTelemetryData()
        let campaign = mockData.campaign ?? ""
        let adGroup = mockData.adgroup ?? ""
        let creative = mockData.creative ?? ""
        let network = mockData.network ?? ""
        
        let expectation = expectation(description: "The first session ping was sent")
        GleanMetrics.Pings.shared.firstSession.testBeforeNextSubmit { _ in
            
            self.testEventMetricRecordingFailed(metric: GleanMetrics.Adjust.deeplinkReceived)
            
            self.testStringMetricFailed(metric: GleanMetrics.Adjust.campaign,
                                        expectedValue: campaign,
                                        failureMessage: "Should have adjust campaign of \(campaign)")
            
            self.testStringMetricFailed(metric: GleanMetrics.Adjust.adGroup,
                                        expectedValue: adGroup,
                                        failureMessage: "Should have adjust adGroup of \(adGroup)")
            
            self.testStringMetricFailed(metric: GleanMetrics.Adjust.creative,
                                        expectedValue: creative,
                                        failureMessage: "Should have adjust creative of \(creative)")
            
            self.testStringMetricFailed(metric: GleanMetrics.Adjust.network,
                                        expectedValue: network,
                                        failureMessage: "Should have adjust network of \(network)")
            
            expectation.fulfill()
        }
        
        telemetryHelper.sendDeeplinkTelemetry(url: url, attribution: mockData)
        waitForExpectations(timeout: 5.0)
    }
}

// MARK: - Helper functions to test telemetry
extension XCTestCase {
    
    func testEventMetricRecordingFailed<Keys: EventExtraKey, Extras: EventExtras>(metric: EventMetricType<Keys, Extras>,
                                                                                  file: StaticString = #file,
                                                                                  line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testCounterMetricRecordingFailed(metric: CounterMetricType,
                                          value: Int32 = 1,
                                          file: StaticString = #file,
                                          line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testLabeledMetricFailed(metric: LabeledMetricType<CounterMetricType>,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testQuantityMetricFailed(metric: QuantityMetricType,
                                  expectedValue: Int64,
                                  failureMessage: String,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testStringMetricFailed(metric: StringMetricType,
                                expectedValue: String,
                                failureMessage: String,
                                file: StaticString = #file,
                                line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testUrlMetricFailed(metric: UrlMetricType,
                             expectedValue: String,
                             failureMessage: String,
                             file: StaticString = #file,
                             line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }
    
    func testUuidMetricFailed(metric: UuidMetricType,
                              expectedValue: UUID,
                              failureMessage: String,
                              file: StaticString = #file,
                              line: UInt = #line) {
        XCTAssertNil(metric.testGetValue(), file: file, line: line)
    }
}

