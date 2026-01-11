//
//  AppNetworkManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 03/01/26.
//

import Foundation
import UIKit
import Network

extension Notification.Name {
    static let connectionRestored = Notification.Name("connectionRestored")
}

class AppNetworkManager {
    
    static let shared = AppNetworkManager()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected: Bool = false
    
    private init() {}
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Remember old status
            let previousStatus = self.isConnected
            
            // update new status
            self.isConnected = path.status == .satisfied
            
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("📡 Internet Connected")
                    
                    // 🔥 LOGIC: Send notification only when network changes from offline to online.
                    if previousStatus == false {
                        NotificationCenter.default.post(name: .connectionRestored, object: nil)
                    }
                    
                } else {
                    print("🔌 Internet Disconnected * AppNetworkManager")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
}
