//
//  DetailStaticCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 28/12/25.
//

import GoogleMaps
import UIKit

class DetailStaticCell: UITableViewCell {
    // MARK: - IBOutlet

    @IBOutlet var btnPhone: UIButton!

    @IBOutlet var lblDesc: UILabel!
    
    @IBOutlet var lblAddress: UILabel!
    
    @IBOutlet var mapContainerView: UIView! {
        didSet {
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    // MARK: - Properties
    var targetLat = 0.0
    var targetLong = 0.0

    
    // We must keep a reference to the map to update it later
    var googleMapView: GMSMapView?
    
     var teaPlace: TeaPlace? {
        didSet {
            configure()
        }
    }

    

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureGoogleMap()
        addTapGestureToMap()
    }

    func addTapGestureToMap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        googleMapView?.addGestureRecognizer(tapGesture)
    }

    func configureGoogleMap() {
        // Initialize the map once and store the reference in 'googleMapView'
        googleMapView = GoogleMapHelper.initializeMap(
            in: mapContainerView,
            enableGestures: false,
            showLocationButton: false,
            showCompass: false,
            showIndoorPicker: false,
            enableTraffic: false,
            showUserLocation: false
        )
    }

    // MARK: - Configure Data

    func configure() {
        btnPhone.setTitle("Connect via \(teaPlace?.phone, default: "")", for: .normal)
        lblDesc.text = teaPlace?.desc ?? ""
        lblAddress.text = teaPlace?.address ?? ""
        targetLat = teaPlace?.latitude ?? 0.0
        targetLong = teaPlace?.longitude ?? 0.0
        GoogleMapHelper.updateLocation(mapView: googleMapView, lat: targetLat, long: targetLong, showMarker: true)
    }

    @IBAction func btnCallTapped(_ sender: UIButton) {
        guard let phone = teaPlace?.phone,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    @objc func mapTapped() {
        print("Map Tapped! Redirecting...")
        openGoogleMaps(lat: targetLat, long: targetLong)
    }

    func openGoogleMaps(lat: Double, long: Double) {
        let appScheme = "comgooglemaps://?q=\(lat),\(long)&zoom=14"
        let browserUrl = "https://www.google.com/maps/search/?api=1&query=\(lat),\(long)"

        if let appUrl = URL(string: appScheme), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else if let webUrl = URL(string: browserUrl) {
            UIApplication.shared.open(webUrl)
        }
    }
}
