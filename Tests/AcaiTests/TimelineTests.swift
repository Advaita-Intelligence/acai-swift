import Foundation
import XCTest

@testable import AcaiSwift

final class TimelineTests: XCTestCase {
    private var timeline: Timeline!

    func testTimeline() {
        let expectation = XCTestExpectation(description: "First Plugin")
        let testPlugin = TestEnrichmentPlugin {
            expectation.fulfill()
            return true
        }

        let acai = Acai(configuration: Configuration(apiKey: "testApiKey"))
        acai.add(plugin: testPlugin)
        acai.track(event: BaseEvent(eventType: "testEvent"))

        wait(for: [expectation], timeout: 10.0)
    }

    func testTimelineWithTwoPlugin() {
        let expectation = XCTestExpectation(description: "First Plugin")
        let expectation2 = XCTestExpectation(description: "Second Plugin")
        let testPlugin = TestEnrichmentPlugin {
            expectation.fulfill()
            return true
        }

        let testPlugin2 = TestEnrichmentPlugin {
            expectation2.fulfill()
            return true
        }

        let acai = Acai(configuration: Configuration(apiKey: "testApiKey"))
        acai.add(plugin: testPlugin)
        acai.add(plugin: testPlugin2)
        acai.track(event: BaseEvent(eventType: "testEvent"))

        wait(for: [expectation, expectation2], timeout: 10.0)
    }
}
