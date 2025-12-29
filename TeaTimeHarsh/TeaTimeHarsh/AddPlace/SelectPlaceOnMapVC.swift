//
//  SelectPlaceOnMapVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import CoreLocation
import GoogleMaps
import UIKit

protocol SelectPlaceOnMapVCDelegate: AnyObject {
    func didSelectLocation(
        latitude: Double,
        longitude: Double,
        address: String
    )
}

class SelectPlaceOnMapVC: UIViewController {
    
    @IBOutlet var lblAddress: UILabel!
    @IBOutlet var mapContainerView: UIView!
    
    @IBOutlet var centerPinImageView: UIImageView! // Connect this to your UI Image

    
    
    private var selectedLatitude: Double = 0.0
    private var selectedLongitude: Double = 0.0
    private var selectedAddress: String = ""

    weak var delegateMap: SelectPlaceOnMapVCDelegate?
    
    var googleMapView: GMSMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocationListeners()
    }

    func setupLocationListeners() {
        LocationManager.shared.checkAuthorizationStatus(from: self)
        
        googleMapView = GoogleMapHelper.initializeMap(in: mapContainerView, enableGestures: true, showLocationButton: true, showCompass: true, showIndoorPicker: true, enableTraffic: true, showUserLocation: true)
        googleMapView?.delegate = self

        // This code waits here until the Manager finds the location
        LocationManager.shared.onLocationUpdate = { [weak self] location in
            guard let self else { return }
            // This runs whenever the location updates
            let lat = location.coordinate.latitude
            let long = location.coordinate.longitude
            GoogleMapHelper.updateLocation(mapView: googleMapView, lat: lat, long: long, showMarker: true)
            print("✅ New Location: \(lat), \(long)")
        }

        // 2. Assign the "Failure" Block
        LocationManager.shared.onLocationFailure = { [weak self] error in
            print("❌ Failed: \(error.localizedDescription)")
            // Show alert to user if needed
            Utility.shared.showAlert(title: "Failed", message: "Could not get location please check location permission and system location settings.", view: self ?? UIViewController())
        }
    }
    
    
    @IBAction func btnSubmitMapTapped(_ sender: UIButton) {
        print("permisson at submit \(selectedLatitude)", "\(selectedLongitude)", "\(selectedAddress)")
        
        delegateMap?.didSelectLocation(
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    address: selectedAddress
                )

        navigationController?.popViewController(animated: true)
        
    }
    
//    
//
//    func setupGoogleMap(currentLat: Double, currentLong: Double) {
//        let options = GMSMapViewOptions()
//        options.camera = GMSCameraPosition.camera(withLatitude: currentLat, longitude: currentLong, zoom: 18.0)
//        options.frame = mapContainerView.bounds
//
//        let mapView = GMSMapView(options: options)
//        mapView.delegate = self
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        mapView.settings.myLocationButton = true
//        mapView.settings.compassButton = true
//        mapView.settings.indoorPicker = false
//
//        mapView.isTrafficEnabled = true
//        mapView.isMyLocationEnabled = true
//
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong)
//
//        marker.map = mapView
//
//        mapContainerView.addSubview(mapView)
//    }

    // Move pin UP slightly (User is dragging)
    func animatePinLift() {
        UIView.animate(withDuration: 0.2) {
            // Move up by 10 pixels
            self.centerPinImageView.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }

    // Move pin DOWN (User stopped)
    func animatePinDrop() {
        UIView.animate(withDuration: 0.2) {
            // Return to normal (center)
            self.centerPinImageView.transform = .identity
        }
    }

    func getAddressFromLatLong(lat: Double, long: Double) {
        // 1. Create a Location Object
        let location = CLLocation(latitude: lat, longitude: long)

        // 2. Use Apple's Geocoder
        let geocoder = CLGeocoder()

        print("🔄 Finding address for: \(lat), \(long)...")

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in

            // Always go back to Main Thread for UI
            DispatchQueue.main.async {
                // Check for errors
                if let error = error {
                    print("❌ Geocoding failed: \(error.localizedDescription)")
                    self?.lblAddress.text = "Address not found"
                    return
                }

                // Get the first result (Placemark)
                guard let place = placemarks?.first else { return }

                var addressComponents: [String?] = [
                    place.name, // Specific Place Name (e.g., "Apple Store", "Block A") 🏢
                    place.subThoroughfare, // House/Flat Number (e.g., "12") 🏠
                    place.thoroughfare, // Street Name (e.g., "Sindhu Bhavan Road") 🛣️
                    place.subLocality, // Area (e.g., "Bodakdev") 📍
                    place.locality, // City (e.g., "Ahmedabad") 🏙️
                    place.administrativeArea, // State (e.g., "Gujarat")
                    place.postalCode, // Pincode
                    place.country, // Country
                ]

                // 2. Remove Duplicate (Smart Filter) 🧠
                // NSOrderedSet to remove duplicate

                let fullAddress = addressComponents
                    .compactMap { $0 } // remove nil
                    .reduce([]) { result, component -> [String] in
                        // (Duplicates remove)
                        if let last = result.last, last.contains(component) {
                            return result
                        }
                        return result + [component]
                    }
                    .joined(separator: ", ")

                // 3. Update UI
                print("📍 Super Detail Address: \(fullAddress)")
                self?.lblAddress.text = fullAddress
                self?.selectedAddress = fullAddress
            }
        }
    }
}

// MARK: - Google Maps Delegate (The Magic Happens Here)

extension SelectPlaceOnMapVC: GMSMapViewDelegate {
    // This runs when the map STOPS moving
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        // 1. Get coordinates from center
        let lat = position.target.latitude
        let long = position.target.longitude

        
        // 2. Drop the pin visually
        animatePinDrop()
        
        selectedLatitude = lat
        selectedLongitude = long

        print("idleAt position \(selectedLatitude) \(selectedLatitude)")
        // 3. CALL THE NEW FUNCTION HERE 👇
        getAddressFromLatLong(lat: lat, long: long)
    }

    // This runs when the map STARTS moving
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            animatePinLift()

            // Optional: Show "Loading..." while they drag
            lblAddress.text = "Locating the address..."
        }
    }
}
