//
//  OTFNetworkObserver.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 17/07/23.
//

import Network
import Combine
import Foundation

class OTFNetworkObserver: ObservableObject {
    @Published private(set) var status: OTFNetworkStatus
    
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "NWPathMonitor")
    
    init(status: OTFNetworkStatus = .unsatisfied, active: Bool = true) {
        self.status = status
        if active {
            enablePathMonitor()
        }
    }
    
    private func enablePathMonitor() {
        pathMonitor.pathUpdateHandler = { path in
            guard path.status == .satisfied else {
                self.status = .offline
                return
            }
            
            self.pingEndpoint(isExpensive: path.isExpensive)
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }
    
    func pingEndpoint(isExpensive: Bool) {
        guard let url = URL(string: "https://theraforge.org/api/v1/") else {
            self.status = .offline
            return
        }
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url) { [weak self] _, response, _ in
            DispatchQueue.main.async {
                guard response != nil else {
                    self?.status = .offline
                    return
                }
                if isExpensive {
                    self?.status = .cellular
                } else {
                    self?.status = .wifi
                }
            }
        }
        task.resume()
    }
}

enum OTFNetworkStatus {
    case offline
    case wifi
    case cellular
    case unsatisfied
}
