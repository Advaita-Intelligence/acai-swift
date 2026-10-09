# Acai-Swift

Native iOS/tvOS/macOS/watchOS analytics SDK — a fork of Acai-Swift rebranded for Acai.

## Installation

### Swift Package Manager

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/Acai-Swift.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → enter your repo URL.

### CocoaPods

```ruby
pod 'AcaiSwift', :git => 'https://github.com/your-org/Acai-Swift.git'
```

## Quick Start

```swift
import AcaiSwift

// 1. Initialize (once, e.g. in AppDelegate / App struct)
let acai = Acai(
    configuration: Configuration(
        apiKey: "YOUR_API_KEY",
        serverUrl: "https://api.your-acai-server.com/2/httpapi"  // your custom server
    )
)

// 2. Identify the user (optional)
acai.setUserId("user@example.com")

// 3. Track events
acai.track(eventType: "Button Clicked", eventProperties: ["button": "sign_up"])

// 4. Revenue tracking
let revenue = Revenue()
revenue.price = 9.99
revenue.productId = "premium_plan"
acai.revenue(revenue: revenue)
```

## Custom Server Configuration

Point the SDK to your own event ingestion server:

```swift
let config = Configuration(
    apiKey: "YOUR_API_KEY",
    serverUrl: "https://api.your-server.com/2/httpapi",   // events endpoint
    serverZone: .US,                                        // .US or .EU
    batchEvents: true,                                      // batch uploads
    eventUploadThreshold: 30,                               // flush every 30 events
    eventUploadPeriodMillis: 30000                          // or every 30s
)
let acai = Acai(configuration: config)
```

Your server must accept POST requests with a JSON body in this format:

```json
{
  "api_key": "YOUR_API_KEY",
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

Respond with `200 OK` and `{"code": 200}` to acknowledge receipt.

## License

MIT
