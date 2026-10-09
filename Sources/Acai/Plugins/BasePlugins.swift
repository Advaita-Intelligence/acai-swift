import Foundation

open class BasePlugin {
    weak public private(set) var acai: Acai?

    public init() {
    }

    open func setup(acai: Acai) {
        self.acai = acai
    }

    open func execute(event: BaseEvent) -> BaseEvent? {
        return event
    }

    public func teardown(){
        // Clean up any resources from setup if necessary
    }

    open func onUserIdChanged(_ userId: String?) {}
    open func onDeviceIdChanged(_ deviceId: String?) {}
    open func onSessionIdChanged(_ sessionId: Int64) {}
    open func onOptOutChanged(_ optOut: Bool) {}
}

open class BeforePlugin: BasePlugin, Plugin {
    public let type: PluginType = .before
}

open class EnrichmentPlugin: BasePlugin, Plugin {
    public let type: PluginType = .enrichment
}

open class UtilityPlugin: BasePlugin, Plugin {
    public let type: PluginType = .utility
}

open class ObservePlugin: BasePlugin, Plugin {
    public let type: PluginType = .observe
}
