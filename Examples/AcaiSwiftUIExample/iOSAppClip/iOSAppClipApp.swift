//
//  iOSAppClipApp.swift
//  iOSAppClip
//
//  Created by Marvin Liu on 12/15/22.
//

import SwiftUI
import AcaiSwift

@main
struct iOSAppClipApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension Acai {
    static var testInstance = Acai(
        configuration: Configuration(
            apiKey: "TEST-API-KEY",
            logLevel: LogLevelEnum.debug,
            callback: { (event: BaseEvent, code: Int, message: String) -> Void in
                print("eventcallback: \(event), code: \(code), message: \(message)")
            },
            trackingOptions: TrackingOptions().disableTrackDMA(),
            flushEventsOnClose: true,
            minTimeBetweenSessionsMillis: 15000
        )
    )
}
