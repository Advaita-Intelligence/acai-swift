//
//  AutocaptureRemoteConfigTests.swift
//  Acai-Swift
//
//  Created by Chris Leonavicius on 4/29/25.
//

import AmplitudeCore
@testable
import AcaiSwift
import ObjectiveC
import XCTest

class AutocaptureRemoteConfigTests: XCTestCase {

    private static func swizzleEphemeral() {
        let metaClass: AnyClass = object_getClass(URLSessionConfiguration.self)!
        let originalSel = #selector(getter: URLSessionConfiguration.ephemeral)
        let swizzledSel = #selector(URLSessionConfiguration.amp_ephemeral)

        guard let original = class_getClassMethod(metaClass, originalSel),
              let swizzled = class_getClassMethod(metaClass, swizzledSel) else {
            return
        }

        method_exchangeImplementations(original, swizzled)
    }

    override class func setUp() {
        super.setUp()
        swizzleEphemeral()
    }

    override class func tearDown() {
        // Swizzle again to restore original behavior
        swizzleEphemeral()
        super.tearDown()
    }

    private func uniqueApiKey(_ function: String = #function) -> String {
        let cleanName = function.replacingOccurrences(of: "()", with: "")
        return "\(RemoteConfigUrlProtocol.testApiKeyPrefix)\(cleanName)"
    }

    private func uniqueInstanceName(_ function: String = #function) -> String {
        let cleanName = function.replacingOccurrences(of: "()", with: "")
        return "test-instance-\(cleanName)"
    }

    private func resetStorage(_ function: String = #function) {
        let instanceName = uniqueInstanceName(function)
        RemoteConfigClient.resetStorage(instanceName: instanceName)
    }

    func testSessionsTurnsOnFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "sessions": true,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: []))
        XCTAssertFalse(acai.autocaptureManager.isEnabled(.sessions), "Sessions should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.sessions), "Sessions should be on from remote config")
    }

    func testSessionsTurnsOffFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "sessions": false,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: [.sessions]))
        XCTAssertTrue(acai.autocaptureManager.isEnabled(.sessions), "Sessions should be on by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.sessions), "Sessions should be off from remote config")
    }

#if os(iOS)

    func testScreenViewsTurnsOnFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "pageViews": true,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: []))

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }
        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.screenViews), "Screen views should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.screenViews), "Screen views should be on from remote config")
    }

    func testScreenViewsTurnsOffFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "pageViews": false,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: [.screenViews]))

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.screenViews), "Screen views should be on by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.screenViews), "Screen views should be off from remote config")
    }

    func testElementInteractionsTurnsOnFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "elementInteractions": true,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: []))

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.elementInteractions), "Element interactions should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.elementInteractions), "Element interactions should be on from remote config")
    }

    func testElementInteractionsTurnsOffFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "elementInteractions": false,
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: [.elementInteractions]))

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.elementInteractions), "Element interactions should be on by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.elementInteractions), "Element interactions should be off from remote config")
    }

    func testFrustrationInteractionsTurnsOnFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "frustrationInteractions": [
                            "enabled": true,
                            "rageClick": [
                                "enabled": true
                            ],
                            "deadClick": [
                                "enabled": false
                            ]
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let interactionsOptions = InteractionsOptions(
            rageClick: .init(enabled: false),
            deadClick: .init(enabled: false)
        )
        let config = Configuration(apiKey: apiKey,
                                   instanceName: uniqueInstanceName(),
                                   autocapture: [],
                                   interactionsOptions: interactionsOptions)
        let acai = Acai(configuration: config)

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be off by default")
        XCTAssertFalse(acai.autocaptureManager.rageClickEnabled, "Rage click should be off by default")
        XCTAssertFalse(acai.autocaptureManager.deadClickEnabled, "Dead click should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be on from remote config")
        XCTAssertTrue(acai.autocaptureManager.rageClickEnabled, "Rage click should be on from remote config")
        XCTAssertFalse(acai.autocaptureManager.deadClickEnabled, "Dead click should be off from remote config")
    }

    func testFrustrationInteractionsTurnsOffFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "frustrationInteractions": [
                            "enabled": false
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let interactionsOptions = InteractionsOptions(
            rageClick: .init(enabled: true),
            deadClick: .init(enabled: true)
        )
        let config = Configuration(apiKey: apiKey,
                                   instanceName: uniqueInstanceName(),
                                   autocapture: [.frustrationInteractions],
                                   interactionsOptions: interactionsOptions)
        let acai = Acai(configuration: config)

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be on by default")
        XCTAssertTrue(acai.autocaptureManager.rageClickEnabled, "Rage click should be on by default")
        XCTAssertTrue(acai.autocaptureManager.deadClickEnabled, "Dead click should be on by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertFalse(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be off from remote config")
        XCTAssertTrue(acai.autocaptureManager.rageClickEnabled, "Rage click should still be on from local config")
        XCTAssertTrue(acai.autocaptureManager.deadClickEnabled, "Dead click should still be on from local config")
    }

    func testFrustrationInteractionsPartialRemoteConfig() {
        resetStorage()
        // Test that missing values in remote config fall back to local config
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "frustrationInteractions": [
                            "enabled": true,
                            "rageClick": [
                                "enabled": false
                            ]
                            // deadClick is missing, should use local config
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let interactionsOptions = InteractionsOptions(
            rageClick: .init(enabled: true),
            deadClick: .init(enabled: true)
        )
        let config = Configuration(apiKey: apiKey,
                                   instanceName: uniqueInstanceName(),
                                   autocapture: [.frustrationInteractions],
                                   interactionsOptions: interactionsOptions)
        let acai = Acai(configuration: config)

        var iosLifecycleMonitor: IOSLifecycleMonitor?
        acai.apply { plugin in
            if let monitor = plugin as? IOSLifecycleMonitor {
                iosLifecycleMonitor = monitor
            }
        }

        XCTAssertNotNil(iosLifecycleMonitor, "iOS lifecycle monitor not installed")

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be on by default")
        XCTAssertTrue(acai.autocaptureManager.rageClickEnabled, "Rage click should be on by default")
        XCTAssertTrue(acai.autocaptureManager.deadClickEnabled, "Dead click should be on by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(acai.autocaptureManager.isEnabled(.frustrationInteractions), "Frustration interactions should be on by default")
        XCTAssertFalse(acai.autocaptureManager.rageClickEnabled, "Rage click should be off from remote config")
        XCTAssertTrue(acai.autocaptureManager.deadClickEnabled, "Dead click should be on from local config")
    }
#endif
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
    func testNetworkTrackingTurnsOnFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "networkTracking": [
                            "enabled": true
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: []))

        var networkTrackingPlugin: NetworkTrackingPlugin?
        acai.apply { plugin in
            if let networkPlugin = plugin as? NetworkTrackingPlugin {
                networkTrackingPlugin = networkPlugin
            }
        }
        guard let networkTrackingPlugin else {
            XCTFail("Network tracking plugin not installed")
            return
        }

        XCTAssertTrue(networkTrackingPlugin.optOut, "Network tracking should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertFalse(networkTrackingPlugin.optOut, "Network tracking should be on from remote config")
    }

    func testNetworkTrackingTurnsOffFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "networkTracking": [
                            "enabled": false
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: [.networkTracking]))

        var networkTrackingPlugin: NetworkTrackingPlugin?
        acai.apply { plugin in
            if let networkPlugin = plugin as? NetworkTrackingPlugin {
                networkTrackingPlugin = networkPlugin
            }
        }
        guard let networkTrackingPlugin else {
            XCTFail("Network tracking plugin not installed")
            return
        }

        XCTAssertFalse(networkTrackingPlugin.optOut, "Network tracking should be off by default")

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        XCTAssertTrue(networkTrackingPlugin.optOut, "Network tracking should be on from remote config")
    }

    func testNetworkTrackingConfigSchemaFromRemoteConfig() {
        resetStorage()
        let apiKey = uniqueApiKey()
        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "networkTracking": [
                            "enabled": true,
                            "ignoreHosts": ["test.example.com", "*.internal.com"],
                            "ignoreAcaiRequests": false,
                            "captureRules": [
                                [
                                    "hosts": ["api.example.com", "*.api.com"],
                                    "urls": ["https://api.example.com/v1/endpoint"],
                                    "urlsRegex": [".*\\/api\\/v[0-9]+\\/.*"],
                                    "methods": ["GET", "POST"],
                                    "statusCodeRange": "400-599",
                                    "requestHeaders": [
                                        "allowlist": ["Content-Type", "Authorization"],
                                        "captureSafeHeaders": true
                                    ],
                                    "responseHeaders": [
                                        "allowlist": ["Content-Type"],
                                        "captureSafeHeaders": false
                                    ],
                                    "requestBody": [
                                        "allowlist": ["userId", "eventType"],
                                        "excludelist": ["password", "token"]
                                    ],
                                    "responseBody": [
                                        "allowlist": ["status", "message"],
                                        "excludelist": ["secret"]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let acai = Acai(configuration: Configuration(apiKey: apiKey, instanceName: uniqueInstanceName(), autocapture: []))

        var networkTrackingPlugin: NetworkTrackingPlugin?
        acai.apply { plugin in
            if let networkPlugin = plugin as? NetworkTrackingPlugin {
                networkTrackingPlugin = networkPlugin
            }
        }
        guard let networkTrackingPlugin else {
            XCTFail("Network tracking plugin not installed")
            return
        }

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        // Verify the plugin is enabled
        XCTAssertFalse(networkTrackingPlugin.optOut)

        // Verify the configuration was applied correctly
        XCTAssertNotNil(networkTrackingPlugin.originalOptions)
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.ignoreHosts, ["test.example.com", "*.internal.com"])
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.ignoreAcaiRequests, false)

        // Verify capture rules
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.captureRules.count, 1)

        if let captureRule = networkTrackingPlugin.originalOptions?.captureRules.first {
            XCTAssertEqual(captureRule.hosts, ["api.example.com", "*.api.com"])
            XCTAssertEqual(captureRule.methods, ["GET", "POST"])
            XCTAssertEqual(captureRule.statusCodeRange, "400-599")

            // Verify URLs patterns
            XCTAssertEqual(captureRule.urls.count, 2)

            // Verify headers configuration
            XCTAssertNotNil(captureRule.requestHeaders)
            XCTAssertEqual(captureRule.requestHeaders?.allowlist, ["Content-Type", "Authorization"])
            XCTAssertTrue(captureRule.requestHeaders?.captureSafeHeaders ?? false)

            XCTAssertNotNil(captureRule.responseHeaders)
            XCTAssertEqual(captureRule.responseHeaders?.allowlist, ["Content-Type"])
            XCTAssertFalse(captureRule.responseHeaders?.captureSafeHeaders ?? true)

            // Verify body configuration
            XCTAssertNotNil(captureRule.requestBody)
            XCTAssertEqual(captureRule.requestBody?.allowlist, ["userId", "eventType"])
            XCTAssertEqual(captureRule.requestBody?.blocklist, ["password", "token"])

            XCTAssertNotNil(captureRule.responseBody)
            XCTAssertEqual(captureRule.responseBody?.allowlist, ["status", "message"])
            XCTAssertEqual(captureRule.responseBody?.blocklist, ["secret"])
        }
    }

    func testNetworkTrackingPartialRemoteConfig() {
        resetStorage()
        // Test that missing values in remote config fall back to local config
        let apiKey = uniqueApiKey()
        let localOptions = NetworkTrackingOptions(
            captureRules: [
                NetworkTrackingOptions.CaptureRule(hosts: ["local.example.com"], statusCodeRange: "500-599")
            ],
            ignoreHosts: ["local-ignore.com"],
            ignoreAcaiRequests: false
        )

        RemoteConfigClient.setNextFetchedRemoteConfig([
            "analyticsSDK": [
                "iosSDK": [
                    "autocapture": [
                        "networkTracking": [
                            "enabled": true,
                            "ignoreHosts": ["remote-ignore.com"]
                            // captureRules and ignoreAcaiRequests are missing, should use local config
                        ]
                    ]
                ]
            ]
        ], forApiKey: apiKey)

        let config = Configuration(apiKey: apiKey,
                                   instanceName: uniqueInstanceName(),
                                   autocapture: [.networkTracking],
                                   networkTrackingOptions: localOptions)
        let acai = Acai(configuration: config)

        var networkTrackingPlugin: NetworkTrackingPlugin?
        acai.apply { plugin in
            if let networkPlugin = plugin as? NetworkTrackingPlugin {
                networkTrackingPlugin = networkPlugin
            }
        }
        guard let networkTrackingPlugin else {
            XCTFail("Network tracking plugin not installed")
            return
        }

        wait(for: [acai.amplitudeContext.remoteConfigClient.didFetchRemoteExpectation], timeout: 15)

        // Verify the plugin is enabled from remote config
        XCTAssertFalse(networkTrackingPlugin.optOut)

        // Verify ignoreHosts was overridden by remote config
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.ignoreHosts, ["remote-ignore.com"])

        // Verify captureRules stayed from local config (not overridden since missing in remote)
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.captureRules.count, 1)
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.captureRules.first?.hosts, ["local.example.com"])

        // Verify ignoreAcaiRequests stayed from local config
        XCTAssertEqual(networkTrackingPlugin.originalOptions?.ignoreAcaiRequests, false)
    }
#endif
}

extension RemoteConfigClient {

    private final class SubscriptionHolder: @unchecked Sendable {
        @AtomicRef var subscription: Any?
    }

    nonisolated var didFetchRemoteExpectation: XCTestExpectation {
        let expectation = XCTestExpectation(description: "didFetchRemote")

        let subscriptionHolder = SubscriptionHolder()
        subscriptionHolder.subscription = subscribe(deliveryMode: .waitForRemote(timeout: 1.8)) { [weak self] _, _, _ in
            if let subscription = subscriptionHolder.subscription {
                self?.unsubscribe(subscription)
            }
            // Add a small delay to ensure other subscription callbacks complete.
            // Callbacks are processed asynchronously, so even though this subscription
            // was registered after the plugin's subscription, there's no guarantee
            // about callback execution order.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }

        return expectation
    }

    static func setNextFetchedRemoteConfig(_ remoteConfig: RemoteConfigClient.RemoteConfig, forApiKey apiKey: String) {
        RemoteConfigUrlProtocol.setConfig(remoteConfig, forApiKey: apiKey)
    }

    static func resetStorage(instanceName: String) {
        let suiteName = "com.acai.remoteconfig.cache.\(instanceName)"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}

extension URLSessionConfiguration {

    @objc class func amp_ephemeral() -> URLSessionConfiguration {
        // This is swizzled, so amp_ephemeral actually calls the original ephemeral
        let config = amp_ephemeral()
        config.protocolClasses = [RemoteConfigUrlProtocol.self] + (config.protocolClasses ?? [])
        return config
    }
}

class RemoteConfigUrlProtocol: URLProtocol {

    static let testApiKeyPrefix = "remote-config-test-"
    // Configs keyed by API key for test isolation
    static var configsByApiKey: [String: [RemoteConfigClient.RemoteConfig]] = [:]

    private static let responseQueue = DispatchQueue(label: "RemoteConfigUrlProtocol.responseQueue")

    static func setConfig(_ config: RemoteConfigClient.RemoteConfig, forApiKey apiKey: String) {
        configsByApiKey[apiKey, default: []].append(config)
    }

    static func popConfig(forApiKey apiKey: String) -> RemoteConfigClient.RemoteConfig? {
        guard var configs = configsByApiKey[apiKey], !configs.isEmpty else {
            return nil
        }
        let config = configs.removeFirst()
        configsByApiKey[apiKey] = configs
        return config
    }

    private static func extractApiKey(from url: URL) -> String? {
        // URL format: https://sr-client-cfg.acai.io/config/{apiKey}
        return url.pathComponents.last?.components(separatedBy: "?").first
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url,
              url.absoluteString.hasPrefix("https://sr-client-cfg."),
              let apiKey = extractApiKey(from: url) else {
            return false
        }
        // Only intercept requests with our test API key prefix
        return apiKey.hasPrefix(testApiKeyPrefix)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url,
              let apiKey = Self.extractApiKey(from: url),
              let config = Self.popConfig(forApiKey: apiKey) else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown))
            return
        }

        print("RemoteConfigUrlProtocol: Starting to load \(url)")

        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        let data = try? JSONSerialization.data(withJSONObject: ["configs": config])

        Self.responseQueue.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(500)) { [self] in
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)

            print("RemoteConfigUrlProtocol: Finished loading \(url): \(config)")
        }
    }

    override func stopLoading() {
        // no-op
    }
}
