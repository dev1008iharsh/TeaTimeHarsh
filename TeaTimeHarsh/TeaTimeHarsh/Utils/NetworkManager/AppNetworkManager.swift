//
//  AppNetworkManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 03/01/26.
//

import Foundation
import UIKit
import Network

class AppNetworkManager {
    
    static let shared = AppNetworkManager()
    private let monitor = NWPathMonitor()
    
    // Weak reference prevents memory leaks (Retain Cycle)
    private weak var currentAlert: UIAlertController?
    
    private init() {}
    
    func startMonitoring() {
        // [weak self] ensures this closure doesn't keep the class alive if it shouldn't be
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.dismissAlert()
                } else {
                    self.showAlert()
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func showAlert() {
        // Prevent stacking multiple alerts
        guard currentAlert == nil else { return }
        
        guard let topVC = UIApplication.shared.getTopViewController() else { return }
        
        // Using your Utility function
        self.currentAlert = Utility.presentNetworkBlockingAlert(
            title: "No Connection",
            message: "Internet is required to proceed.",
            rightSideActionName: "Retry",
            leftSideActionName: "Settings",
            viewController: topVC,
            rightAction: { [weak self] _ in
                // Reset alert reference so logic can run again if needed
                self?.currentAlert = nil
            },
            leftAction: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
    }
    
    private func dismissAlert() {
        // Dismiss only if our specific alert is onscreen
        if let alert = currentAlert {
            alert.dismiss(animated: true, completion: nil)
            currentAlert = nil
        }
    }
}
