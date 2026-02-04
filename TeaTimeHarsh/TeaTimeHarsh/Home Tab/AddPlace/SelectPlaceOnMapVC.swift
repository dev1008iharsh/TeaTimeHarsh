//
//  SelectPlaceOnMapVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import CoreLocation
import GoogleMaps
import UIKit

// MARK: - Delegate Protocol

protocol SelectPlaceOnMapVCDelegate: AnyObject {
    func didSelectLocation(latitude: Double, longitude: Double, address: String)
}

class SelectPlaceOnMapVC: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet var viewAddressLabel: UIView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var mapContainerView: UIView!
    @IBOutlet var centerPinImageView: UIImageView!

    // MARK: - Properties

    // Data passed from previous screen
    var alreadySelectedLatitude: Double?
    var alreadySelectedLongitude: Double?

    // Current selection state
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private var currentAddress: String?

    // Flag to prevent re-centering map repeatedly on user updates
    private var hasCenteredOnUser = false

    weak var delegateMap: SelectPlaceOnMapVCDelegate?
    var googleMapView: GMSMapView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Check Internet Connection first
        guard AppNetworkManager.shared.isConnected else {
            print("⚠️ No Internet Connection. Popping VC.")
            ToastManager.shared.show(message: "⚠️ No Internet Connection.", type: .error)
            navigationController?.popViewController(animated: true)
            return
        }

        // 2. Setup UI (Initially Hidden for Security)
        setupMapUI()

        // 3. Setup Listeners (CRITICAL: Must be done before requesting location)
        setupCallbackHandlers()

        // 4. Determine Start State (Edit mode or New mode)
        determineInitialState()

        // 5. Setup Observers (For Background/Foreground changes)
        setupNotificationCenter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true

        // 🛑 Stop updates to save battery
        LocationManager.shared.stopUpdating()
    }

    deinit {
        print("💀 SelectPlaceOnMapVC is dead. Memory Free!")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup UI & Observers

    func setupMapUI() {
        // 🔒 SECURITY: Keep map hidden initially to avoid showing "Null Island" (0,0 coordinates)
        mapContainerView.isHidden = true
        viewAddressLabel.isHidden = true
        mapContainerView.alpha = 0
        viewAddressLabel.alpha = 0

        googleMapView = GoogleMapHelper.initializeMap(
            in: mapContainerView,
            enableGestures: true,
            showLocationButton: true,
            showCompass: true,
            showIndoorPicker: true,
            enableTraffic: true,
            showUserLocation: true
        )
        googleMapView?.delegate = self
    }

    private func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - Location Logic & Security (Grouped)

    /// 1. Setup Listeners for LocationManager callbacks
    func setupCallbackHandlers() {
        // Handle Permission Denied / Cancel Action
        LocationManager.shared.onPermissionDenied = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("🚪 Permission denied/cancelled by user. Popping VC.")
                self.navigationController?.popViewController(animated: true)
            }
        }

        // Handle Live Location Updates
        LocationManager.shared.onLocationUpdate = { [weak self] location in
            guard let self = self else { return }

            // Reveal Map if it was hidden
            self.revealMapWithAnimation()

            if !self.hasCenteredOnUser {
                print("📍 First precise location received. Centering map.")
                self.hasCenteredOnUser = true
                self.moveCamera(lat: location.coordinate.latitude, long: location.coordinate.longitude)
            }
        }

        // Handle Errors
        LocationManager.shared.onLocationFailure = { error in
            print("❌ Location Manager Error: \(error.localizedDescription)")
        }
    }

    /// 2. Determine if we are editing an address or finding a new one
    func determineInitialState() {
        if let lat = alreadySelectedLatitude, let long = alreadySelectedLongitude {
            print("💾 Loading Pre-selected Location: \(lat), \(long)")

            // Show map immediately for saved location
            revealMapWithAnimation()
            moveCamera(lat: lat, long: long)
            hasCenteredOnUser = true

        } else {
            print("📡 Starting fresh search for user location...")
            // Case 2: New Selection - Trigger Permission Flow
            LocationManager.shared.checkAuthorizationStatus(from: self)

            // Check Cached Location (Fast Path)
            if let lastLocation = LocationManager.shared.lastKnownLocation {
                print("🚀 Found Cached Location! Moving immediately.")
                revealMapWithAnimation()
                hasCenteredOnUser = true
                moveCamera(lat: lastLocation.coordinate.latitude, long: lastLocation.coordinate.longitude)
            }
        }
    }

    /// 3. Security Check when App comes to Foreground
    @objc func appDidBecomeActive() {
        let status = LocationManager.shared.authorizationStatus

        // 🛡️ SECURITY CRITICAL:
        // If permission is denied or restricted, HIDE EVERYTHING IMMEDIATELY.

        if status == .denied || status == .restricted {
            print("🔒 Access Revoked in Settings. Hiding Map & UI.")

            // Hide UI instantly (No animation, just gone)
            mapContainerView.isHidden = true
            viewAddressLabel.isHidden = true
            mapContainerView.alpha = 0
            viewAddressLabel.alpha = 0

            // Re-trigger the permission check (which will show the Alert)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                LocationManager.shared.checkAuthorizationStatus(from: self)
            }
        }
    }

    // MARK: - UI Helpers

    /// Helper to unhide the map smoothly.
    private func revealMapWithAnimation() {
        // Only animate if it's currently hidden
        guard mapContainerView.isHidden else { return }

        print("✨ Revealing Map UI")
        mapContainerView.isHidden = false
        viewAddressLabel.isHidden = false

        UIView.animate(withDuration: 0.3) {
            self.mapContainerView.alpha = 1
            self.viewAddressLabel.alpha = 1
        } completion: { _ in
            ToastManager.shared.show(message: "Drag map to choose location 📍", type: .warning)
        }
    }

    func moveCamera(lat: Double, long: Double) {
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16.0)
        googleMapView?.animate(to: camera)

        // Only fetch address if coordinates are valid
        if lat != 0.0 && long != 0.0 {
            getAddressFromLatLong(lat: lat, long: long)
        }
    }

    // MARK: - Actions

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        HapticHelper.light()
        view.endEditing(true)

        // 1. Check Network
        guard AppNetworkManager.shared.isConnected else {
            AlertHelper.showAlert(
                title: "No Internet 🛜",
                message: "Please connect to the internet to perform this action.",
                vc: self
            )
            return
        }

        // 2. Check Valid Data
        guard let lat = currentLatitude, let long = currentLongitude, let address = currentAddress else {
            HapticHelper.error()
            AlertHelper.showAlert(
                title: "Location Not Found",
                message: "We couldn't catch that spot. 📍 Please try moving the map slightly.",
                vc: self
            )
            return
        }

        // 3. Success
        print("✅ User selected location: \(address)")
        delegateMap?.didSelectLocation(latitude: lat, longitude: long, address: address)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Animations

    func animatePinLift() {
        UIView.animate(withDuration: 0.2) {
            self.centerPinImageView.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }

    func animatePinDrop() {
        HapticHelper.light() // Feedback when pin drops
        UIView.animate(withDuration: 0.2) {
            self.centerPinImageView.transform = .identity
        }
    }
}

// MARK: - Map Delegate

extension SelectPlaceOnMapVC: GMSMapViewDelegate {
    // Called when user starts dragging the map
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            animatePinLift()
            addressLabel.text = "Locating place of marker..."
            // If user manually moves map, we stop auto-centering
            hasCenteredOnUser = true
        }
    }

    // Called when user stops dragging
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        animatePinDrop()

        let lat = position.target.latitude
        let long = position.target.longitude

        // 🛑 Ignore Null Island (0,0) - Invalid coordinates
        if lat == 0.0 && long == 0.0 { return }

        currentLatitude = lat
        currentLongitude = long

        getAddressFromLatLong(lat: lat, long: long)
    }
}

// MARK: - Geocoding

extension SelectPlaceOnMapVC {
    func getAddressFromLatLong(lat: Double, long: Double) {
        let location = CLLocation(latitude: lat, longitude: long)
        let geocoder = CLGeocoder()

        print("🔄 Reverse Geocoding: \(lat), \(long)")

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            // Always update UI on Main Thread
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("❌ Geocoding Error: \(error.localizedDescription)")
                    self.addressLabel.text = "Address not found"
                    return
                }

                guard let place = placemarks?.first else {
                    print("⚠️ No placemarks found")
                    return
                }

                // Construct full address safely
                let addressComponents = [
                    place.name,
                    place.subThoroughfare,
                    place.thoroughfare,
                    place.subLocality,
                    place.locality,
                    place.administrativeArea,
                    place.postalCode,
                    place.country,
                ]

                // remove nil and duplicates from address
                let fullAddress = addressComponents
                    .compactMap { $0 }
                    .reduce([]) { result, component -> [String] in
                        if let last = result.last, last.contains(component) { return result }
                        return result + [component]
                    }
                    .joined(separator: ", ")

                print("📍 Resolved Address: \(fullAddress)")

                self.addressLabel.text = fullAddress
                self.currentAddress = fullAddress
                self.currentLatitude = lat
                self.currentLongitude = long
            }
        }
    }
}
