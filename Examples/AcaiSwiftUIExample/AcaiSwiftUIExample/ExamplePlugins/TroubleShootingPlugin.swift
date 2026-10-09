//
//  TroubleShootingPlugin.swift
//  AcaiSwiftUIExample
//
//  Created by Alyssa.Yu on 6/27/23.
//

import Foundation
import AcaiSwift

class TroubleShootingPlugin: DestinationPlugin {
    open override func setup(acai: Acai) {
        super.setup(acai: acai)
        let apiKey = acai.configuration.apiKey;
        let serverZone = acai.configuration.serverZone.rawValue;
        let serverUrl = acai.configuration.serverUrl ?? "null";

        self.acai?.logger?.debug(message: "Current Configuration : {\"apiKey\": "+apiKey+", \"serverZone\": "+serverZone+", \"serverUrl\": "+serverUrl+"}")
    }

    open override func track(event: BaseEvent) -> BaseEvent? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let eventJsonData = try! jsonEncoder.encode(event)
        let eventJson = String(data: eventJsonData, encoding: String.Encoding.utf8)

        self.acai?.logger?.debug(message: "Processed event: \(eventJson ?? "")")
        return event
    }
}
