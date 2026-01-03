//
//  GoogleMapHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import Foundation
import UIKit
import GoogleMaps

class GoogleMapHelper {
    
    // MARK: - Part 1: One-Time Setup
    // Call this ONLY ONCE (e.g., in viewDidLoad).
    // It creates the map, applies static settings, and returns the map instance.
    static func initializeMap(in view: UIView,
                              enableGestures: Bool,
                              showLocationButton: Bool,
                              showCompass: Bool,
                              showIndoorPicker: Bool,
                              enableTraffic: Bool,
                              showUserLocation: Bool) -> GMSMapView {
        
        // 1. Clean up: Remove any existing subviews to prevent duplicate maps
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // 2. Initialize MapView
        // We start with a default camera (0,0) because the real location will come later via updates.
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 15.0)
        options.frame = view.bounds
        
        let mapView = GMSMapView(options: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 3. Apply Static Settings (UI & Gestures)
        mapView.settings.setAllGesturesEnabled(enableGestures)
        mapView.settings.myLocationButton = showLocationButton
        mapView.settings.compassButton = showCompass
        mapView.settings.indoorPicker = showIndoorPicker
        
        // 4. Apply Features
        mapView.isTrafficEnabled = enableTraffic
        mapView.isMyLocationEnabled = showUserLocation
        
        // 5. Add Map to the Container View
        view.addSubview(mapView)
        
        // 6. Return the map instance so the View Controller can store it
        return mapView
    }
    
    // MARK: - Part 2: Update Logic
    // Call this REPEATEDLY (e.g., inside onLocationUpdate).
    // It only moves the camera and updates the marker. It does NOT recreate the map.
    static func updateLocation(mapView: GMSMapView?, lat: Double, long: Double, showMarker: Bool) {
        
        // Safety check: Make sure the map exists
        guard let mapView = mapView else { return }
        
        // 1. Animate Camera to the new location smoothly
        let cameraUpdate = GMSCameraUpdate.setTarget(CLLocationCoordinate2D(latitude: lat, longitude: long), zoom: 15.0)
        mapView.animate(with: cameraUpdate)
        
        // 2. Manage the Marker
        if showMarker {
            // Clear old markers to avoid duplicates before adding the new one
            mapView.clear()
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
            marker.map = mapView
        }
    }
}
