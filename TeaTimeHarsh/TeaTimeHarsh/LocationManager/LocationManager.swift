//
//  LocationManager.swift
//  Api Harsh Darji

import UIKit
import CoreLocation
 
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
   
    private let locationManager = CLLocationManager()
    private var viewControllerName: UIViewController?
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationFailure: ((Error) -> Void)?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func checkAuthorizationStatus(from viewController: UIViewController) {
        self.viewControllerName = viewController
        let status = locationManager.authorizationStatus
        handleAuthorizationStatus(status)
    }
   
    
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location permission not determined")
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission authorized")
             
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
        guard let vcName = viewControllerName else { return }
        Utility.shared.showCustomConfirmAlert(title: "Location Permission Restricted", message: "Your device restrictions prevent changing location permissions.", rightSideActionName: "Settings", leftSideActionName: "Cancel", viewController: vcName) { settingAction in
            self.openSettings()
        } leftAction: { cancelAction in
            print("cancle")
        }
    }
    
    private func showPermissionRestrictedAlert() {
        guard let vcName = viewControllerName else { return }
        Utility.shared.showAlert(title: "Location Permission Restricted", message: "Your device restrictions prevent changing location permissions.", view: vcName)
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationFailure?(error)
    }
}
