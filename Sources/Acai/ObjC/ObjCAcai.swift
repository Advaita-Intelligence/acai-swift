import Foundation

@objc(Acai)
public class ObjCAcai: NSObject {
    private let acai: Acai
    private var plugins: [ObjCPluginWrapper] = []

    @objc(initWithConfiguration:)
    public static func initWithConfiguration(
        configuration: ObjCConfiguration
    ) -> ObjCAcai {
        ObjCAcai(configuration: configuration)
    }

    @objc(initWithConfiguration:)
    public init(
        configuration: ObjCConfiguration
    ) {
        acai = Acai(configuration: configuration.configuration)
    }

    @objc
    public var configuration: ObjCConfiguration {
        ObjCConfiguration(configuration: acai.configuration)
    }

    @objc
    public var storage: ObjCStorage {
        ObjCStorage(acai: acai)
    }

    @objc(track:)
    @discardableResult
    public func track(event: ObjCBaseEvent) -> ObjCAcai {
        acai.track(event: event.event)
        return self
    }

    @objc(track:callback:)
    @discardableResult
    public func track(event: ObjCBaseEvent, callback: ObjCEventCallback?) -> ObjCAcai {
        acai.track(event: event.event, callback: callback == nil ? nil : { (event, code, message) in
            callback!(ObjCBaseEvent(event: event), code, message)
        })
        return self
    }

    @objc(track:options:)
    @discardableResult
    public func track(event: ObjCBaseEvent, options: ObjCEventOptions?) -> ObjCAcai {
        acai.track(event: event.event, options: options?.options)
        return self
    }

    @objc(track:options:callback:)
    @discardableResult
    public func track(event: ObjCBaseEvent, options: ObjCEventOptions?, callback: ObjCEventCallback?) -> ObjCAcai {
        acai.track(event: event.event, options: options?.options, callback: callback == nil ? nil : { (event, code, message) in
            callback!(ObjCBaseEvent(event: event), code, message)
        })
        return self
    }

    @objc(track:eventProperties:)
    @discardableResult
    public func track(eventType: String, eventProperties: [String: Any]?) -> ObjCAcai {
        acai.track(eventType: eventType, eventProperties: eventProperties)
        return self
    }

    @objc(track:eventProperties:options:)
    @discardableResult
    public func track(eventType: String, eventProperties: [String: Any]?, options: ObjCEventOptions?) -> ObjCAcai {
        acai.track(eventType: eventType, eventProperties: eventProperties, options: options?.options)
        return self
    }

    @objc(identify:)
    @discardableResult
    public func identify(identify: ObjCIdentify) -> ObjCAcai {
        acai.identify(identify: identify.identify)
        return self
    }

    @objc(identify:options:)
    @discardableResult
    public func identify(identify: ObjCIdentify, options: ObjCEventOptions?) -> ObjCAcai {
        acai.identify(identify: identify.identify, options: options?.options)
        return self
    }

    @objc(groupIdentify:groupName:identify:)
    @discardableResult
    public func groupIdentify(groupType: String, groupName: String, identify: ObjCIdentify) -> ObjCAcai {
        acai.groupIdentify(groupType: groupType, groupName: groupName, identify: identify.identify)
        return self
    }

    @objc(groupIdentify:groupName:identify:options:)
    @discardableResult
    public func groupIdentify(groupType: String, groupName: String, identify: ObjCIdentify, options: ObjCEventOptions?) -> ObjCAcai {
        acai.groupIdentify(groupType: groupType, groupName: groupName, identify: identify.identify, options: options?.options)
        return self
    }

    @objc(setGroup:groupName:)
    @discardableResult
    public func setGroup(groupType: String, groupName: String) -> ObjCAcai {
        acai.setGroup(groupType: groupType, groupName: groupName)
        return self
    }

    @objc(setGroup:groupName:options:)
    @discardableResult
    public func setGroup(groupType: String, groupName: String, options: ObjCEventOptions?) -> ObjCAcai {
        acai.setGroup(groupType: groupType, groupName: groupName, options: options?.options)
        return self
    }

    @objc(setGroup:groupNames:)
    @discardableResult
    public func setGroup(groupType: String, groupNames: [String]) -> ObjCAcai {
        acai.setGroup(groupType: groupType, groupName: groupNames)
        return self
    }

    @objc(setGroup:groupNames:options:)
    @discardableResult
    public func setGroup(groupType: String, groupNames: [String], options: ObjCEventOptions?) -> ObjCAcai {
        acai.setGroup(groupType: groupType, groupName: groupNames, options: options?.options)
        return self
    }

    @objc(revenue:)
    @discardableResult
    public func revenue(revenue: ObjCRevenue) -> ObjCAcai {
        acai.revenue(revenue: revenue.instance)
        return self
    }

    @objc(revenue:options:)
    @discardableResult
    public func revenue(revenue: ObjCRevenue, options: ObjCEventOptions? = nil) -> ObjCAcai {
        acai.revenue(revenue: revenue.instance, options: options?.options)
        return self
    }

    @objc(add:)
    @discardableResult
    public func add(plugin: AnyObject) -> ObjCAcai {
        switch plugin {
        case let swiftPlugin as UniversalPlugin:
            acai.add(plugin: swiftPlugin)
        case let objcPlugin as ObjCPlugin:
            let wrapper = ObjCPluginWrapper(acai: self, wrapped: objcPlugin)
            plugins.append(wrapper)
            acai.add(plugin: wrapper)
        default:
            fatalError("Attempted to add a plugin that is not an instance of Plugin or ObjCPlugin")
        }
        return self
    }

    @objc(remove:)
    @discardableResult
    public func remove(plugin: ObjCPlugin) -> ObjCAcai {
        guard let pluginIndex = plugins.firstIndex(where: { wrapper in wrapper.wrapped == plugin }) else { return self }
        let wrapper = plugins[pluginIndex]
        plugins.remove(at: pluginIndex)
        acai.remove(plugin: wrapper)
        return self
    }

    @objc
    @discardableResult
    public func flush() -> ObjCAcai {
        acai.flush()
        return self
    }

    @objc(setUserId:)
    @discardableResult
    public func setUserId(userId: String?) -> ObjCAcai {
        acai.setUserId(userId: userId)
        return self
    }

    @objc(setDeviceId:)
    @discardableResult
    public func setDeviceId(deviceId: String?) -> ObjCAcai {
        acai.setDeviceId(deviceId: deviceId)
        return self
    }

    @objc
    public func getUserId() -> String? {
        acai.getUserId()
    }

    @objc
    public func getDeviceId() -> String? {
        acai.getDeviceId()
    }

    @objc
    public func getSessionId() -> Int64 {
        acai.getSessionId()
    }

    @objc(setSessionIdWithTimestamp:)
    @discardableResult
    public func setSessionId(timestamp: Int64) -> ObjCAcai {
        acai.setSessionId(timestamp: timestamp)
        return self
    }

    @objc(setSessionIdWithDate:)
    @discardableResult
    public func setSessionId(date: Date) -> ObjCAcai {
        acai.setSessionId(date: date)
        return self
    }

    @objc
    @discardableResult
    public func reset() -> ObjCAcai {
        acai.reset()
        return self
    }

    @objc
    var optOut: Bool {
        get {
            return acai.optOut
        }
        set {
            acai.optOut = newValue
        }
    }
}

extension ObjCAcai: PluginHost {

    public func plugin(name: String) -> (any UniversalPlugin)? {
        return acai.plugin(name: name)
    }

    public func plugins<PluginType: UniversalPlugin>(type: PluginType.Type) -> [PluginType] {
        return acai.plugins(type: type)
    }
}
