//
//  LocationManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import CoreLocation
import UIKit

@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    // 🛠️  Expose the authorization status publicly
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    // 🛠️  Expose the last known location
    // This allows us to get the location INSTANTLY if the GPS is already warm.
    var lastKnownLocation: CLLocation? {
        return locationManager.location
    }

    private weak var viewControllerName: UIViewController?

    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationFailure: ((Error) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // We don't start updating here to save battery until requested
    }

    func checkAuthorizationStatus(from viewController: UIViewController) {
        viewControllerName = viewController
        let status = locationManager.authorizationStatus
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied:
            HapticHelper.warning()
            showPermissionDeniedAlert()
        case .restricted:
            showPermissionRestrictedAlert()
        @unknown default:
            print("Unknown status")
        }
    }

    // MARK: - Alerts

    private func showPermissionDeniedAlert() {
        guard let vcName = viewControllerName else { return }
        AlertHelper.showConfirmationAlert(
            title: "Location Permission Denied",
            message: "Please enable location services in Settings.",
            vc: vcName,
            rightBtnTitle: "Settings",
            rightBtnStyle: .default,
            leftBtnTitle: "Cancel",
            leftBtnStyle: .destructive,
            rightAction: { _ in
                self.openSettings()
            },
            leftAction: { _ in
                print("User cancelled location setup")
            }
        )
    }

    private func showPermissionRestrictedAlert() {
        guard let vcName = viewControllerName else { return }
        HapticHelper.warning()
        AlertHelper.showAlert(title: "Restricted", message: "Location is restricted.", vc: vcName)
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    // MARK: - Delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        onLocationFailure?(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }
}
