import Foundation
import AnalyticsConnector

class AnalyticsConnectorIdentityPlugin: ObservePlugin {
    private var connector: AnalyticsConnector?

    override func setup(acai: Acai) {
        super.setup(acai: acai)
        connector = AnalyticsConnector.getInstance(acai.configuration.instanceName)
        connector?.identityStore.editIdentity()
            .setUserId(acai.getUserId())
            .setDeviceId(acai.getDeviceId())
            .commit()
    }

    override func onUserIdChanged(_ userId: String?) {
        connector?.identityStore.editIdentity().setUserId(userId).commit()
    }

    override func onDeviceIdChanged(_ deviceId: String?) {
        connector?.identityStore.editIdentity().setDeviceId(deviceId).commit()
    }
}
