# Acai-Swift

Native iOS/tvOS/macOS/watchOS analytics SDK
## Installation

### Swift Package Manager

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Advaita-Intelligence/acai-swift.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → enter your repo URL.

### CocoaPods

```ruby
pod 'AcaiSwift', :git => 'https://github.com/Advaita-Intelligence/acai-swift.git'
```

## Quick Start

```swift
import AcaiSwift

// 1. Initialize (once, e.g. in AppDelegate / App struct)
let acai = Acai(
    configuration: Configuration(
        apiKey: "YOUR_API_KEY"
        // Events go to https://clickstream.acaiplatform.ai/api/collect by default.
        // Pass serverUrl: to override it.
    )
)

// 2. Identify the user (optional)
acai.setUserId(userId: "user@example.com")

// 3. Track events
acai.track(eventType: "Button Clicked", eventProperties: ["button": "sign_up"])

// 4. Revenue tracking
let revenue = Revenue()
revenue.price = 9.99
revenue.productId = "premium_plan"
acai.revenue(revenue: revenue)
```

## Configuration

The SDK sends events to the capture endpoint `https://clickstream.acaiplatform.ai/api/collect`, authenticated with your project API key. All zones and batch mode use the same URL. Common options (parameters must be passed in this order):

```swift
let config = Configuration(
    apiKey: "YOUR_API_KEY",
    flushQueueSize: 30,          // flush every 30 events
    flushIntervalMillis: 30000,  // or every 30s
    useBatch: false,             // batch upload path (same endpoint)
    serverZone: .US,             // no effect: all zones use the same endpoint
    serverUrl: "https://clickstream.acaiplatform.ai/api/collect"  // optional override
)
let acai = Acai(configuration: config)
```

Setting a custom `serverUrl` turns request compression off unless you pass `enableRequestBodyCompression: true`. With the default endpoint, request bodies are gzip-compressed.

The SDK sends POST requests with a JSON body in this format:

```json
{
  "api_key": "YOUR_API_KEY",
  "client_upload_time": "2026-10-09T12:00:00.000Z",
  "events": [
    {
      "event_type": "Button Clicked",
      "user_id": "user@example.com",
      "device_id": "abc123",
      "time": 1700000000000,
      "event_properties": { "button": "sign_up" },
      "user_properties": {},
      "library": "acai-swift/1.0.0"
    }
  ]
}
```

The SDK treats any 2xx response as success.

## License

MIT
