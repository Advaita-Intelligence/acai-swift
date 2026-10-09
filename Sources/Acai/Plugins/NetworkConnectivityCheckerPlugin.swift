//
//  NetworkConnectivityCheckerPlugin.swift
//  Acai-Swift
//
//  Created by Xinyi.Ye on 1/26/24.
//

import Foundation
import Network
import Combine

// Define a custom struct to represent network path status
public struct NetworkPath {
    public var status: NWPath.Status

    public init(status: NWPath.Status) {
        self.status = status
    }
}

// Protocol for creating network paths
protocol PathCreationProtocol {
    var networkPathPublisher: AnyPublisher<NetworkPath, Never>? { get }
    func start(queue: DispatchQueue)
}

// Implementation of PathCreationProtocol using NWPathMonitor
final class PathCreation: PathCreationProtocol {
    public var networkPathPublisher: AnyPublisher<NetworkPath, Never>?
    private let subject = PassthroughSubject<NWPath, Never>()
    private let monitor = NWPathMonitor()

    func start(queue: DispatchQueue) {
        monitor.pathUpdateHandler = subject.send
        networkPathPublisher = subject
            .map { NetworkPath(status: $0.status) }
            .eraseToAnyPublisher()
        monitor.start(queue: queue)
    }
}

open class NetworkConnectivityCheckerPlugin: BeforePlugin {
    public static let Disabled: Bool? = nil
    var pathCreation: PathCreationProtocol
    private var pathUpdateCancellable: AnyCancellable?

    init(pathCreation: PathCreationProtocol = PathCreation()) {
        self.pathCreation = pathCreation
        super.init()
    }

    open override func setup(acai: Acai) {
        super.setup(acai: acai)
        acai.logger?.debug(message: "Installing NetworkConnectivityCheckerPlugin, offline feature should be supported.")

        pathCreation.start(queue: acai.trackingQueue)
        let logger = acai.logger
        pathUpdateCancellable = pathCreation.networkPathPublisher?
            .sink(receiveValue: { [weak acai, logger] networkPath in
                guard let acai = acai else {
                    logger?.debug(message: "Received network connectivity updated when acai instance has been deallocated")
                    return
                }
                let isOffline = !(networkPath.status == .satisfied)
                if acai.configuration.offline == isOffline {
                    return
                }
                acai.logger?.debug(message: "Network connectivity changed to \(isOffline ? "offline" : "online").")
                acai.configuration.offline = isOffline
                if !isOffline {
                    acai.flush()
                }
            })
    }

    open override func teardown() {
        pathUpdateCancellable?.cancel()
    }
}
