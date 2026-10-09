# Acai-Swift

Analytics SDK for iOS, tvOS, macOS and watchOS. It sends clickstream events to the Acai capture endpoint, authenticated with your project API key. Based on [Amplitude-Swift](https://github.com/amplitude/Amplitude-Swift) (MIT).

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Capture endpoint](#capture-endpoint)
- [Plugins](#plugins)
- [Documentation](#documentation)
- [License](#license)

## Requirements

| Platform | Minimum version |
| -------- | --------------- |
| iOS      | 13.0            |
| tvOS     | 13.0            |
| macOS    | 10.15           |
| watchOS  | 7.0             |

## Installation

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies** and enter:

```
https://github.com/Advaita-Intelligence/acai-swift.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Advaita-Intelligence/acai-swift.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "AcaiSwift", package: "acai-swift")
    ])
]
```

### CocoaPods

Add to your `Podfile`, then run `pod install`:

```ruby
pod 'AcaiSwift', :git => 'https://github.com/Advaita-Intelligence/acai-swift.git', :tag => '1.0.0'
```

> The versions above resolve from git tags. Create a release tag (for example `1.0.0`) before installing.

## Quick start

Initialize the SDK once at app startup, in your `AppDelegate` or `App` struct.

```swift
import AcaiSwift

let acai = Acai(
    configuration: Configuration(
        apiKey: "YOUR_API_KEY"
    )
)

acai.setUserId(userId: "user@example.com")
acai.track(eventType: "Button Clicked", eventProperties: ["button": "sign_up"])
```

Events go to the [capture endpoint](#capture-endpoint) by default. You don't need to set a server URL.

## Usage

### Track events

```swift
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
```

### Identify users

Call `setUserId` after login, and use `Identify` to attach user properties.

```swift
acai.setUserId(userId: "user@example.com")

let identify = Identify()
identify.set(property: "plan", value: "pro")
identify.set(property: "signup_date", value: "2024-01-01")
acai.identify(identify: identify)
```

### Track revenue

```swift
let revenue = Revenue()
revenue.price = 9.99
revenue.quantity = 1
revenue.productId = "premium_monthly"
acai.revenue(revenue: revenue)
```

### Groups

```swift
acai.setGroup(groupType: "company", groupName: "Acme Corp")
acai.groupIdentify(
    groupType: "company",
    groupName: "Acme Corp",
    groupProperties: ["plan": "enterprise"]
)
```

## Configuration

`Configuration` takes the options below. Swift requires named parameters to be passed in the order they are declared, so keep this order when you combine them.

```swift
let config = Configuration(
    apiKey: "YOUR_API_KEY",
    flushQueueSize: 30,          // flush after 30 queued events
    flushIntervalMillis: 30000,  // or every 30 seconds
    useBatch: false,             // batch upload path (same endpoint)
    serverZone: .US,             // no effect: all zones use the same endpoint
    serverUrl: nil               // optional endpoint override
)
let acai = Acai(configuration: config)
```

| Option                         | Default      | Description                                                         |
| ------------------------------ | ------------ | ------------------------------------------------------------------- |
| `apiKey`                       | required     | Your project API key                                                |
| `flushQueueSize`               | `30`         | Events queued before a flush is forced                              |
| `flushIntervalMillis`          | `30000`      | Periodic upload interval in milliseconds                            |
| `flushMaxRetries`              | `6`          | Failed upload attempts before the SDK marks itself offline          |
| `useBatch`                     | `false`      | Use the batch upload path (same endpoint)                           |
| `serverZone`                   | `.US`        | No effect on routing                                                |
| `serverUrl`                    | `nil`        | Override the capture endpoint                                       |
| `minTimeBetweenSessionsMillis` | `300000`     | Session timeout (5 minutes)                                         |
| `autocapture`                  | `.sessions`  | Events tracked automatically, such as `[.sessions, .screenViews]`   |
| `logLevel`                     | `.warn`      | `.off`, `.error`, `.warn`, `.log` or `.debug`                       |
| `optOut`                       | `false`      | Stop tracking for this user                                         |
| `enableRequestBodyCompression` | `false`      | Gzip bodies when a custom `serverUrl` is set                        |

## Capture endpoint

```
POST https://clickstream.acaiplatform.ai/api/collect
```

The SDK sends the API key in the request body. Single and batch uploads, and both server zones, use this same URL.

### Request

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

With the default endpoint, request bodies are gzip-compressed (`Content-Encoding: gzip`). With a custom `serverUrl`, compression is off unless you pass `enableRequestBodyCompression: true`.

### Responses

| Status          | SDK behavior                                                                            |
| --------------- | --------------------------------------------------------------------------------------- |
| 2xx             | Success                                                                                 |
| 400             | Rejected events are dropped and reported through the event callback                     |
| 413             | The batch is split and retried; a single oversized event is dropped                     |
| 408, 429, 5xx   | Events stay queued and are retried on a later flush, until `flushMaxRetries` is reached |

## Plugins

Subclass a plugin type to enrich or filter events before they are sent.

```swift
class AppVersionPlugin: EnrichmentPlugin {
    override func execute(event: BaseEvent) -> BaseEvent? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var properties = event.eventProperties ?? [:]
        properties["app_version"] = version ?? "unknown"
        event.eventProperties = properties
        return event
    }
}

acai.add(plugin: AppVersionPlugin())
```

## Documentation

See [Acai-Swift-Integration-Guide.docx](Acai-Swift-Integration-Guide.docx) for repository setup, release steps and an onboarding checklist. Contribution rules are in [CONTRIBUTING.md](CONTRIBUTING.md), and changes are listed in [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
