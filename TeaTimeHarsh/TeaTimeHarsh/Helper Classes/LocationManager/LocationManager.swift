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
    // ✅ Singleton Instance
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    // Callback: Triggered when user denies permission or cancels the alert
    var onPermissionDenied: (() -> Void)?

    // 🛠️ Public Authorization Status
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    // 🛠️ Last Known Location (Instant Access)
    var lastKnownLocation: CLLocation? {
        return locationManager.location
    }

    // ⚠️ Improved Naming: 'hostViewController' clarifies it's a reference to the VC, not a String name.
    // [weak] is crucial here to avoid Retain Cycles (Memory Leak Prevention).
    private weak var hostViewController: UIViewController?

    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationFailure: ((Error) -> Void)?

    override private init() {
        super.init()
        locationManager.delegate = self
        // 'Best' accuracy is good for maps, but uses more battery. Ensure we stop it when not needed.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Call this when you are done with the map (e.g. viewWillDisappear) to save battery 🔋
    func stopUpdating() {
        print("🛑 Stopping Location Updates to save battery.")
        locationManager.stopUpdatingLocation()
    }

    func checkAuthorizationStatus(from viewController: UIViewController) {
        hostViewController = viewController
        let status = locationManager.authorizationStatus
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("❓ Permission Not Determined. Requesting...")
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }

        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Permission Granted.")

            // Optional: Check for accuracy (iOS 14+)
            if locationManager.accuracyAuthorization == .reducedAccuracy {
                print("⚠️ Note: User has only granted approximate location.")
            }

            locationManager.startUpdatingLocation()

        case .denied, .restricted:
            print("🚫 Permission Explicitly Denied/Restricted. Handling Alert.")
            showPermissionDeniedAlert()

        @unknown default:
            print("⚠️ Unknown Authorization Status")
        }
    }

    // MARK: - Alerts

    private func showPermissionDeniedAlert() {
        // Ensure UI updates are always on Main Thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let hostVC = self.hostViewController else { return }

            // 🛡️ Safety: Prevent stacking alerts.
            // If an alert is ALREADY showing, don't show another one.
            // This logic is crucial when returning from Settings.
            if hostVC.presentedViewController is UIAlertController {
                print("⚠️ Alert already presented, skipping duplicate.")
                return
            }

            print("🚨 Presenting Permission Alert")
            AlertHelper.showConfirmationAlert(
                title: "Permission Required 📍",
                message: "We need your location to show the map. Please enable 'Location' in Settings.",
                vc: hostVC,
                rightBtnTitle: "Settings",
                rightBtnStyle: .default,
                leftBtnTitle: "Cancel",
                leftBtnStyle: .destructive,
                rightAction: { _ in
                    self.openSettings()
                },
                leftAction: { [weak self] _ in
                    print("❌ User cancelled permission alert.")
                    self?.onPermissionDenied?()
                }
            )
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Delegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Pass location to the closure
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore "Unknown" error which happens sometimes during initialization
        if let clError = error as? CLError, clError.code == .locationUnknown { return }

        print("❌ Location Manager Failed: \(error.localizedDescription)")
        onLocationFailure?(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 🔄 Real-time update: If user comes back from Settings, this triggers automatically.
        print("🔄 Authorization Status Changed.")
        handleAuthorizationStatus(manager.authorizationStatus)
    }
}
