//
//  SelectPlaceOnMapVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//


import CoreLocation
import GoogleMaps
import UIKit

protocol SelectPlaceOnMapVCDelegate: AnyObject {
    func didSelectLocation(latitude: Double, longitude: Double, address: String)
}

class SelectPlaceOnMapVC: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var lblAddress: UILabel!
    @IBOutlet var mapContainerView: UIView!
    @IBOutlet var centerPinImageView: UIImageView!

    // MARK: - Properties
    var alreadySelectedLatitude: Double?
    var alreadySelectedLongitude: Double?

    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private var currentAddress: String?

    private var hasCenteredOnUser = false
    
    weak var delegateMap: SelectPlaceOnMapVCDelegate?
    var googleMapView: GMSMapView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        determineInitialState()
    }
    
    deinit {
        print("💀 SelectPlaceOnMapVC is dead. Memory Free!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Setup
    func setupMap() {
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

    func determineInitialState() {
        if let lat = alreadySelectedLatitude, let long = alreadySelectedLongitude {
            print("💾 Loading Previous Selection: \(lat), \(long)")
            moveCamera(lat: lat, long: long)
            hasCenteredOnUser = true
        } else {
            print("📡 No selection found, searching for user...")
            setupLocationListeners()
        }
    }

    func setupLocationListeners() {
        // 1. Check Permission
        let status = LocationManager.shared.authorizationStatus
        if status == .denied || status == .restricted {
            showPermissionAlert()
            return
        }

        // 2. Assign Callback (For FUTURE updates)
        LocationManager.shared.onLocationUpdate = { [weak self] location in
            guard let self = self else { return }
            if !self.hasCenteredOnUser {
                self.hasCenteredOnUser = true
                self.moveCamera(lat: location.coordinate.latitude, long: location.coordinate.longitude)
            }
        }
        
        LocationManager.shared.onLocationFailure = { [weak self] error in
            if let clError = error as? CLError, clError.code == .locationUnknown { return }
            print("❌ Failed: \(error.localizedDescription)")
            guard let self = self else { return }
            HapticHelper.warning()
            Utility.showAlert(title: "Location Error", message: "Could not find location.", viewController: self)
        }
        
        // 🛠️ FIX: Check IMMEDIATE Location
        // If the GPS is already warm (running), get the location NOW.
        // Don't wait for the next update cycle.
        if let lastLocation = LocationManager.shared.lastKnownLocation {
            print("🚀 Found Cached Location! Moving immediately.")
            hasCenteredOnUser = true
            moveCamera(lat: lastLocation.coordinate.latitude, long: lastLocation.coordinate.longitude)
        }
        
        // 3. Keep Listening (in case we didn't have a cached location)
        LocationManager.shared.checkAuthorizationStatus(from: self)
    }

    func moveCamera(lat: Double, long: Double) {
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16.0)
        googleMapView?.animate(to: camera)

        if lat != 0.0 && long != 0.0 {
            getAddressFromLatLong(lat: lat, long: long)
        }
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "Please enable Location Services in Settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                HapticHelper.medium()
                UIApplication.shared.open(url) }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            HapticHelper.error()
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Actions
    @IBAction func btnSubmitMapTapped(_ sender: UIButton) {
        HapticHelper.success()
        guard let lat = currentLatitude, let long = currentLongitude, let address = currentAddress else { return }
        delegateMap?.didSelectLocation(latitude: lat, longitude: long, address: address)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Animations
    func animatePinLift() {
        UIView.animate(withDuration: 0.2) { self.centerPinImageView.transform = CGAffineTransform(translationX: 0, y: -10) }
    }

    func animatePinDrop() {
        UIView.animate(withDuration: 0.2) { self.centerPinImageView.transform = .identity }
    }
}

// MARK: - Map Delegate
extension SelectPlaceOnMapVC: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            animatePinLift()
            lblAddress.text = "Locating place of marker..."
            hasCenteredOnUser = true
        }
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        animatePinDrop()
        HapticHelper.light()
        
        let lat = position.target.latitude
        let long = position.target.longitude
        
        // 🛑 Ignore Null Island (0,0)
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
        
        print("🔄 Geocoding: \(lat), \(long)")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("❌ Error: \(error.localizedDescription)")
                    self.lblAddress.text = "Address not found"
                    return
                }
                guard let place = placemarks?.first else { return }
                
                let components = [place.name, place.subThoroughfare, place.thoroughfare, place.subLocality, place.locality, place.administrativeArea, place.postalCode, place.country]
                let fullAddress = components.compactMap { $0 }.reduce([]) { result, component -> [String] in
                    if let last = result.last, last.contains(component) { return result }
                    return result + [component]
                }.joined(separator: ", ")
                
                self.lblAddress.text = fullAddress
                self.currentAddress = fullAddress
                self.currentLatitude = lat
                self.currentLongitude = long
            }
        }
    }
}
