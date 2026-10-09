//
//  NetworkConnectivityCheckerPluginTests.swift
//  Acai-SwiftTests
//
//  Created by Xinyi.Ye on 1/29/24.
//

import XCTest

@testable import AcaiSwift

final class NetworkConnectivityCheckerPluginTests: XCTestCase {
    private var mockPathCreation: MockPathCreation!
    private var plugin: NetworkConnectivityCheckerPlugin!
    private var acai: Acai!

    override func setUp() {
        super.setUp()
        mockPathCreation = MockPathCreation()
        acai = Acai(configuration: Configuration(apiKey: "test-api-key"))
        plugin = NetworkConnectivityCheckerPlugin(pathCreation: mockPathCreation)
        plugin.setup(acai: acai)
    }

    func testNetworkBecomesOnline() {
        mockPathCreation.simulateNetworkChange(status: .satisfied)
        XCTAssertEqual(acai.configuration.offline, false)
    }

    func testNetworkBecomesOffline() {
        mockPathCreation.simulateNetworkChange(status: .unsatisfied)
        XCTAssertEqual(acai.configuration.offline, true)
    }
}
