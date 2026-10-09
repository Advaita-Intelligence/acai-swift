import Foundation
import AnalyticsConnector

class AnalyticsConnectorPlugin: BeforePlugin {
    private static let EXPOSURE_EVENT = "$exposure"
    private var connector: AnalyticsConnector?

    override func setup(acai: Acai) {
        super.setup(acai: acai)
        connector = AnalyticsConnector.getInstance(acai.configuration.instanceName)
        let logger = acai.logger
        connector!.eventBridge.setEventReceiver { [weak acai, logger] event in
            if let acai = acai {
                acai.track(event: BaseEvent(
                    eventType: event.eventType,
                    eventProperties: event.eventProperties as? [String: Any],
                    userProperties: event.userProperties as? [String: Any]
                ))
            } else {
                logger?.error(message: "Acai instance has been deallocated, please maintain a strong reference to track events from Experiment")
            }
        }
    }

    override func execute(event: BaseEvent) -> BaseEvent? {
        guard let userProperties = event.userProperties else {
            return event
        }
        if userProperties.count == 0 || event.eventType == AnalyticsConnectorPlugin.EXPOSURE_EVENT {
            return event
        }
        connector?.identityStore.editIdentity().updateUserProperties(userProperties as NSDictionary).commit()
        return event
    }
}
