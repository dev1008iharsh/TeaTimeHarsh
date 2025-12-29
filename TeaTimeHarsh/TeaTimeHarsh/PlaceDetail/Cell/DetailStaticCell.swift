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
    @IBOutlet var mapContainerView: UIView!{
        didSet{
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    let targetLat = 23.0225
    let targetLong = 72.5714

    var teaPlace: TeaPlace? {
        didSet {
            configure()
        }
    }

    // MARK: - Properties

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupGoogleMap()
    }

    // MARK: - Configure Data

    func configure() {
        btnPhone.setTitle("Connect via \(teaPlace?.phone, default: "")", for: .normal)
        lblDesc.text = teaPlace?.desc ?? ""
        lblAddress.text = teaPlace?.address ?? ""
    }

    @IBAction func btnCallTapped(_ sender: UIButton) {
        guard let phone = teaPlace?.phone,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    func setupGoogleMap() {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: targetLat, longitude: targetLong, zoom: 15.0)
        options.frame = mapContainerView.bounds

        let mapView = GMSMapView(options: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mapView.settings.setAllGesturesEnabled(false)

        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: targetLat, longitude: targetLong)
 
        marker.map = mapView

        mapContainerView.addSubview(mapView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(tapGesture)
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
