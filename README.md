# Acai-Swift

Native iOS/tvOS/macOS/watchOS analytics SDK

Acai-Swift SDK
Integration & Setup Guide
Native iOS / tvOS / macOS / watchOS Analytics SDK



1. Capture Endpoint
All clickstream events are sent to a single capture endpoint. Requests are authenticated with your project API key, which the SDK includes in every request body.

1.1  Endpoint
POST https://clickstream.acaiplatform.ai/api/collect
The same URL is used for single and batch uploads (useBatch) and for both server zones (.US and .EU), so changing serverZone or useBatch does not change where events go.

1.2  Request Format
The SDK sends JSON payloads like this:
{
  "api_key": "YOUR_API_KEY",
  "client_upload_time": "2026-10-09T12:00:00.000Z",
  "events": [
    {
      "event_type": "Button Clicked",
      "user_id": "user@example.com",
      "device_id": "abc-123-def",
      "time": 1700000000000,
      "event_properties": { "button": "sign_up" },
      "user_properties": { "plan": "pro" },
      "library": "acai-swift/1.0.0",
      "platform": "iOS",
      "os_name": "ios",
      "os_version": "17.0",
      "device_model": "iPhone15,2"
    }
  ]
}
Content-Type is application/json. When the SDK uses its default endpoint it also gzip-compresses the request body and sets Content-Encoding: gzip.

1.3  Responses
The SDK treats any 2xx response as success. Other status codes are handled as follows:
	•	400: the rejected events are dropped and reported through the event callback.
	•	413: the SDK splits the batch and retries. A single event that is still too large is dropped.
	•	408, 429 and 5xx: the events stay queued and the SDK tries again on a later flush. After flushMaxRetries consecutive failures (default 6) it marks itself offline.

1.4  Overriding the Server URL
You normally do not need to set a URL. The defaults live in Sources/Acai/Constants.swift:
public static let DEFAULT_API_HOST    = "https://clickstream.acaiplatform.ai/api/collect"
public static let EU_DEFAULT_API_HOST = "https://clickstream.acaiplatform.ai/api/collect"
static let BATCH_API_HOST             = "https://clickstream.acaiplatform.ai/api/collect"
static let EU_BATCH_API_HOST          = "https://clickstream.acaiplatform.ai/api/collect"
To send events somewhere else, pass serverUrl in Configuration. A custom serverUrl turns request compression off unless you set enableRequestBodyCompression: true.

2. SDK Installation (For Your Users)
Share these instructions with any developer who wants to integrate the Acai-Swift SDK into their iOS/macOS app.

2.1  Swift Package Manager (Recommended)
In Xcode: File > Add Package Dependencies, then enter:
https://github.com/Advaita-Intelligence/acai-swift.git
Or add it to Package.swift:
dependencies: [
  .package(url: "https://github.com/Advaita-Intelligence/acai-swift.git", from: "1.0.0")
],
targets: [
  .target(name: "MyApp", dependencies: [
    .product(name: "AcaiSwift", package: "acai-swift")
  ])
]

2.2  CocoaPods
Add to your Podfile:
pod 'AcaiSwift', :git => 'https://github.com/Advaita-Intelligence/acai-swift.git', :tag => '1.0.0'
Then run: pod install

3. SDK Usage
   
3.1  Initialize the SDK
Initialize once at app startup, in AppDelegate or your App struct. No server URL is needed; the SDK uses the capture endpoint by default.
import AcaiSwift

// SwiftUI App
@main struct MyApp: App {
    let acai = Acai(
        configuration: Configuration(
            apiKey: "YOUR_API_KEY"
        )
    )
    var body: some Scene { WindowGroup { ContentView() } }
}

3.2  Identify Users
Call setUserId after login, and use Identify to attach user properties:
acai.setUserId(userId: "user@example.com")

let identify = Identify()
identify.set(property: "plan", value: "pro")
identify.set(property: "signup_date", value: "2024-01-01")
acai.identify(identify: identify)

3.3  Track Events
Track any user action with optional properties:
// Simple event
acai.track(eventType: "Button Clicked")

// Event with properties
acai.track(
    eventType: "Purchase Completed",
    eventProperties: [
        "item": "Premium Plan",
        "price": 9.99,
        "currency": "USD"
    ]
)

3.4  Revenue Tracking
let revenue = Revenue()
revenue.price = 9.99
revenue.quantity = 1
revenue.productId = "premium_monthly"
acai.revenue(revenue: revenue)

3.5  Group Analytics
acai.setGroup(groupType: "company", groupName: "Acme Corp")
acai.groupIdentify(
    groupType: "company",
    groupName: "Acme Corp",
    groupProperties: ["plan": "enterprise"]
)

4. Advanced Configuration
   
4.1  Common Configuration Options
Parameter
Default
Description
apiKey
(required)
Your project API key for authentication
serverUrl
nil (uses clickstream.acaiplatform.ai/api/collect)
Override the capture endpoint
serverZone
.US
No effect on routing; all zones use the same endpoint
useBatch
false
Use the batch upload path (same endpoint)
flushQueueSize
30
Events queued before a flush is forced
flushIntervalMillis
30000
Periodic upload interval in milliseconds
flushMaxRetries
6
Failed upload attempts before going offline
minTimeBetweenSessionsMillis
300000
Session timeout (5 minutes)
autocapture
.sessions
Events tracked automatically, e.g. [.sessions, .appLifecycles, .screenViews]
logLevel
.warn
.off, .error, .warn, .log, .debug
optOut
false
Stop tracking for this user
enableRequestBodyCompression
false
Gzip bodies when a custom serverUrl is set (always on for the default endpoint)

4.2  Custom Plugins
You can intercept or enrich events before they are sent by subclassing a plugin type:
class AppVersionPlugin: EnrichmentPlugin {
    override func execute(event: BaseEvent) -> BaseEvent? {
        // Add a custom property to every event
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var properties = event.eventProperties ?? [:]
        properties["app_version"] = version ?? "unknown"
        event.eventProperties = properties
        return event
    }
}

acai.add(plugin: AppVersionPlugin())


5. Quick Checklist
Use this checklist when onboarding a new app:
	•	Create a GitHub release tag (for example 1.0.0) so Swift Package Manager and CocoaPods can resolve it
	•	Share the repo URL and the project API key with the app developer
	•	Developer adds the Swift package to their Xcode project
	•	Developer initializes Acai with the apiKey (serverUrl is optional)
	•	Developer calls setUserId after authentication
	•	Developer tracks key events (onboarding, purchases, engagement milestones)
	•	Verify events arrive at the capture endpoint https://clickstream.acaiplatform.ai/api/collect
Acai-Swift SDK  •  Based on Amplitude-Swift (MIT License)  •  Updated Oct 2026
