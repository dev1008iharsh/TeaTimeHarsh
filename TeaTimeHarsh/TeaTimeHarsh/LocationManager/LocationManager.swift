//
//  LocationManager.swift
//  Api Harsh Darji
//

import UIKit
import CoreLocation

// 🟢 @MainActor: Since this manager interacts with UI (Alerts) and Settings,
// we mark the whole class as MainActor to satisfy strict iOS 18 concurrency rules.
@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    
    // If we don't use weak, the View Controller can never be removed from memory.
    private weak var viewControllerName: UIViewController?
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationFailure: ((Error) -> Void)?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        // Best practice: Set accuracy to save battery if high precision isn't needed
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func checkAuthorizationStatus(from viewController: UIViewController) {
        self.viewControllerName = viewController
        // iOS 14+ syntax for checking status
        let status = locationManager.authorizationStatus
        handleAuthorizationStatus(status)
    }
   
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location permission not determined")
            // Depending on flow, you might want to request permission here again
             locationManager.requestWhenInUseAuthorization()
          
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission authorized")
            locationManager.startUpdatingLocation()
             
        case .denied:
            print("Location permission denied")
            showPermissionDeniedAlert()
          
        case .restricted:
            print("Location permission restricted")
            showPermissionRestrictedAlert()
          
        @unknown default:
            print("Unknown location permission status")
        }
    }
    
    private func showPermissionDeniedAlert() {
        // Safely unwrap the weak viewController
        guard let vcName = viewControllerName else { return }
        
        Utility.shared.showCustomConfirmAlert(
            title: "Location Permission Denied",
            message: "Please enable location services in Settings to use this feature.",
            rightSideActionName: "Settings",
            leftSideActionName: "Cancel",
            viewController: vcName,
            rightAction: { _ in
                self.openSettings()
            },
            leftAction: { _ in
                print("Cancel tapped")
            }
        )
    }
    
    private func showPermissionRestrictedAlert() {
        guard let vcName = viewControllerName else { return }
        
        Utility.shared.showAlert(
            title: "Location Permission Restricted",
            message: "Your device restrictions prevent changing location permissions.",
            view: vcName
        )
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // These delegate methods will run on the Main Thread because the class is @MainActor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore "Unknown Location" errors which happen often on simulator initialization
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        print("Location Error: \(error.localizedDescription)")
        onLocationFailure?(error)
    }
    
    // Handle status changes automatically (e.g., user went to settings and came back)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        handleAuthorizationStatus(status)
    }
}
