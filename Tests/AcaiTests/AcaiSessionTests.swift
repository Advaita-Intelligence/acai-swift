import XCTest

@testable import AcaiSwift

final class AcaiSessionTests: XCTestCase {
    private var configuration: Configuration!
    private var storageMem: FakeInMemoryStorage!
    private var interceptStorageMem: FakeInMemoryStorage!

    override func setUp() {
        super.setUp()
        let apiKey = "testApiKey"

        storageMem = FakeInMemoryStorage()
        interceptStorageMem = FakeInMemoryStorage()

        configuration = Configuration(
            apiKey: apiKey,
            storageProvider: storageMem,
            identifyStorageProvider: interceptStorageMem,
            minTimeBetweenSessionsMillis: 100,
            offline: NetworkConnectivityCheckerPlugin.Disabled,
            enableAutoCaptureRemoteConfig: false
        )
    }

    func testCloseBackgroundEventsShouldNotStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 3)
        XCTAssertEqual(acai.getSessionId(), 1000)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testDistantBackgroundEventsShouldStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testBackgroundOutOfSessionEvent() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)
        let customCongiguration = Configuration(
            apiKey: "test-out-of-session",
            storageProvider: storageMem,
            identifyStorageProvider: interceptStorageMem,
            minTimeBetweenSessionsMillis: 100,
            autocapture: [],
            offline: NetworkConnectivityCheckerPlugin.Disabled,
            enableAutoCaptureRemoteConfig: false
        )
        let acai = Acai(configuration: customCongiguration)
        acai.setSessionId(timestamp: 800)
        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)
        let eventOptions = EventOptions(timestamp: 1000, sessionId: -1)
        let eventType = "out of session event"
        acai.track(eventType: eventType, options: eventOptions)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, eventType: "test event"))
        acai.waitForTrackingQueue()
        let collectedEvents = eventCollector.events
        XCTAssertEqual(collectedEvents.count, 2)
        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, eventType)
        XCTAssertEqual(event.sessionId, -1)
        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(acai.getSessionId(), 1000)
    }

    func testForegroundEventsShouldNotStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.onEnterForeground(timestamp: 1000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))

        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 3)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testCloseBackgroundForegroundEventsShouldNotStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.onEnterForeground(timestamp: 1050)
        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))

        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 3)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testDistantBackgroundForegroundEventsShouldStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.onEnterForeground(timestamp: 2000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 3000, eventType: "test event 2"))

        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 3000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testCloseForegroundBackgroundEventsShouldNotStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.onEnterForeground(timestamp: 1000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1500, eventType: "test event 1"))
        acai.onExitForeground(timestamp: 2000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 2050, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 3)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1500)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 2050)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testDistantForegroundBackgroundEventsShouldStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.onEnterForeground(timestamp: 1000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1500, eventType: "test event 1"))
        acai.onExitForeground(timestamp: 2000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 3000, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1500)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 3000)
        XCTAssertEqual(event.timestamp, 3000)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 3000)
        XCTAssertEqual(event.timestamp, 3000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testSessionDataShouldBePersisted() throws {
        let acai1 = Acai(configuration: configuration)
        acai1.onEnterForeground(timestamp: 1000)
        acai1.waitForTrackingQueue()

        XCTAssertEqual(acai1.sessionId, 1000)
        XCTAssertEqual(acai1.sessions.sessionId, 1000)
        XCTAssertEqual(acai1.sessions.lastEventTime, 1000)
        XCTAssertEqual(acai1.sessions.lastEventId, 1)

        acai1.track(event: BaseEvent(userId: "user", timestamp: 1200, eventType: "test event 1"))
        acai1.waitForTrackingQueue()

        XCTAssertEqual(acai1.sessionId, 1000)
        XCTAssertEqual(acai1.sessions.sessionId, 1000)
        XCTAssertEqual(acai1.sessions.lastEventTime, 1200)
        XCTAssertEqual(acai1.sessions.lastEventId, 2)

        let acai2 = Acai(configuration: configuration)
        acai2.waitForTrackingQueue()

        XCTAssertEqual(acai2.sessionId, 1000)
        XCTAssertEqual(acai2.sessions.sessionId, 1000)
        XCTAssertEqual(acai2.sessions.lastEventTime, 1200)
        XCTAssertEqual(acai2.sessions.lastEventId, 2)
    }

    func testExplicitSessionForEventShouldBePreserved() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, sessionId: 3000, eventType: "test event 2"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1100, eventType: "test event 3"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 4)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 3000)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, "test event 3")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1100)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testExplicitNoSessionForEventShouldBePreserved() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, sessionId: -1, eventType: "test event 2"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1100, eventType: "test event 3"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 4)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, -1)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, "test event 3")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1100)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testSetSessionIdInBackgroundShouldStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 100, eventType: "test event 1"))
        acai.setSessionId(timestamp: 150)
        acai.track(event: BaseEvent(userId: "user", timestamp: 200, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 100)
        XCTAssertEqual(event.timestamp, 100)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 100)
        XCTAssertEqual(event.timestamp, 100)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 100)
        XCTAssertEqual(event.timestamp, 100)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 150)
        XCTAssertEqual(event.timestamp, 150)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 150)
        XCTAssertEqual(event.timestamp, 200)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testSetSessionIdInForegroundShouldStartNewSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.onEnterForeground(timestamp: 1000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, eventType: "test event 1"))
        acai.setSessionId(timestamp: 1100)
        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1050)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1100)
        XCTAssertEqual(event.timestamp, 1100)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 1100)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testSessionEndInBackgroundShouldEndCurrentSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, 1000)

        acai.setSessionId(timestamp: -1)
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, -1)

        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, 2000)

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func testSessionEndInForegroundShouldEndCurrentSession() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        acai.onEnterForeground(timestamp: 1000)
        acai.track(event: BaseEvent(userId: "user", timestamp: 1500, eventType: "test event 1"))
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, 1000)

        acai.setSessionId(timestamp: -1)
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, -1)

        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))
        acai.waitForTrackingQueue()
        XCTAssertEqual(acai.sessionId, 2000)

        let collectedEvents = eventCollector.events

        XCTAssertEqual(collectedEvents.count, 5)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1000)
        XCTAssertEqual(event.eventId, lastEventId+1)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 1")
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1500)
        XCTAssertEqual(event.eventId, lastEventId+2)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[2]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_END_EVENT)
        XCTAssertEqual(event.sessionId, 1000)
        XCTAssertEqual(event.timestamp, 1500)
        XCTAssertEqual(event.eventId, lastEventId+3)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[3]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+4)
        XCTAssertEqual(event.userId, acai.getUserId())
        XCTAssertEqual(event.deviceId, acai.getDeviceId())

        event = collectedEvents[4]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
        XCTAssertEqual(event.eventId, lastEventId+5)
        XCTAssertEqual(event.userId, "user")
        XCTAssertEqual(event.deviceId, acai.getDeviceId())
    }

    func getDictionary(_ props: [String: Any?]) -> NSDictionary {
        return NSDictionary(dictionary: props as [AnyHashable: Any])
    }

    // MARK: - OptOut Session Event Tests

    func testOptOutShouldNotSendSessionEventsWhenTracking() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let optOutConfiguration = Configuration(
            apiKey: "testOptOutSessionEvents",
            optOut: true,
            storageProvider: storageMem,
            identifyStorageProvider: interceptStorageMem,
            minTimeBetweenSessionsMillis: 100,
            offline: NetworkConnectivityCheckerPlugin.Disabled,
            enableAutoCaptureRemoteConfig: false
        )
        let acai = Acai(configuration: optOutConfiguration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        // Track events that would normally trigger session_start
        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.track(event: BaseEvent(userId: "user", timestamp: 1050, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        // With optOut=true, no events should be collected (no session_start, no regular events)
        XCTAssertEqual(collectedEvents.count, 0)
    }

    func testOptOutShouldNotSendSessionEventsOnEnterForeground() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let optOutConfiguration = Configuration(
            apiKey: "testOptOutForegroundSessionEvents",
            optOut: true,
            storageProvider: storageMem,
            identifyStorageProvider: interceptStorageMem,
            minTimeBetweenSessionsMillis: 100,
            offline: NetworkConnectivityCheckerPlugin.Disabled,
            enableAutoCaptureRemoteConfig: false
        )
        let acai = Acai(configuration: optOutConfiguration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        // Enter foreground which would normally trigger session_start
        acai.onEnterForeground(timestamp: 1000)
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        // With optOut=true, no session_start event should be sent
        XCTAssertEqual(collectedEvents.count, 0)
    }

    func testOptOutShouldNotSendSessionEndEventsOnSetSessionId() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        // Start with optOut=false to establish a session
        let acai = Acai(configuration: configuration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        // Track an event to start a session
        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.waitForTrackingQueue()

        // Should have session_start and test event
        XCTAssertEqual(eventCollector.events.count, 2)
        XCTAssertEqual(eventCollector.events[0].eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(eventCollector.events[1].eventType, "test event 1")

        // Now enable optOut
        acai.configuration.optOut = true

        // Set a new session ID which would normally trigger session_end and session_start
        acai.setSessionId(timestamp: 2000)
        acai.waitForTrackingQueue()

        // No new events should be added because optOut is true
        XCTAssertEqual(eventCollector.events.count, 2)
    }

    func testOptOutDisabledAfterEnableShouldSendSessionEvents() throws {
        let lastEventId: Int64 = 123
        try storageMem.write(key: StorageKey.LAST_EVENT_ID, value: lastEventId)

        let optOutConfiguration = Configuration(
            apiKey: "testOptOutToggle",
            optOut: true,
            storageProvider: storageMem,
            identifyStorageProvider: interceptStorageMem,
            minTimeBetweenSessionsMillis: 100,
            offline: NetworkConnectivityCheckerPlugin.Disabled,
            enableAutoCaptureRemoteConfig: false
        )
        let acai = Acai(configuration: optOutConfiguration)

        let eventCollector = EventCollectorPlugin()
        acai.add(plugin: eventCollector)

        // Try to track with optOut=true
        acai.track(event: BaseEvent(userId: "user", timestamp: 1000, eventType: "test event 1"))
        acai.waitForTrackingQueue()

        // No events should be collected
        XCTAssertEqual(eventCollector.events.count, 0)

        // Disable optOut
        acai.configuration.optOut = false

        // Now track an event - should trigger session_start and the event
        acai.track(event: BaseEvent(userId: "user", timestamp: 2000, eventType: "test event 2"))
        acai.waitForTrackingQueue()

        let collectedEvents = eventCollector.events

        // Should have session_start and test event 2
        XCTAssertEqual(collectedEvents.count, 2)

        var event = collectedEvents[0]
        XCTAssertEqual(event.eventType, Constants.AMP_SESSION_START_EVENT)
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)

        event = collectedEvents[1]
        XCTAssertEqual(event.eventType, "test event 2")
        XCTAssertEqual(event.sessionId, 2000)
        XCTAssertEqual(event.timestamp, 2000)
    }
}
