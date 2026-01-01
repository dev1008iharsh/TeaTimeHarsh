//
//  DetailStaticCell.swift


import GoogleMaps
import UIKit

class DetailStaticCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet var btnPhone: UIButton!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var lblAddress: UILabel!
    
    @IBOutlet weak var lblServingSince: UILabel!
    @IBOutlet weak var lblPriceRange: UILabel!
    
    @IBOutlet weak var lblClosingTime: UILabel!
    @IBOutlet weak var lblOpeningTime: UILabel!
    
    @IBOutlet var mapContainerView: UIView! {
        didSet {
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    // MARK: - Properties
    private var targetLat = 0.0
    private var targetLong = 0.0
    private var googleMapView: GMSMapView?
    
    var teaPlace: TeaPlace? {
        didSet { configure() }
    }

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureGoogleMap()
        addTapGestureToMap()
    }

    // MARK: - Map Configuration
    private func configureGoogleMap() {
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
    
    private func addTapGestureToMap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        googleMapView?.addGestureRecognizer(tapGesture)
    }

    // MARK: - Data Population
    private func configure() {
        guard let place = teaPlace else { return }
        
        // Basic Info
        let phoneText = place.phone ?? "N/A"
        btnPhone.setTitle("Connect via \(phoneText)", for: .normal)
        lblDesc.text = place.desc ?? "No description available."
        lblAddress.text = place.address ?? "Address not available."
        
        // Extra Info
        lblPriceRange.text = "Rs." + (place.priceRange ?? "")
        lblOpeningTime.text = "Open at : " + (place.openingTime ?? "")
        lblClosingTime.text = "Close at : " + (place.closingTime ?? "")
        
        // This calculates the duration logic
        let durationString = Utility.getServingDuration(from: place.createdAt)
        // Result examples:
        // "1 Day"
        // "2 Months, 5 Days"
        // "1 Year, 4 Days"
        lblServingSince.text = "Serving since \(durationString) from opening"
        
        // Map Update
        targetLat = place.latitude ?? 0.0
        targetLong = place.longitude ?? 0.0
        GoogleMapHelper.updateLocation(mapView: googleMapView, lat: targetLat, long: targetLong, showMarker: true)
    }

    // MARK: - Actions
    @IBAction func btnCallTapped(_ sender: UIButton) {
        guard let phone = teaPlace?.phone,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else { return }
        
        HapticHelper.medium()
        UIApplication.shared.open(url)
    }

    @objc private func mapTapped() {
        print("📍 Map Tapped! Redirecting...")
        HapticHelper.heavy()
        openGoogleMaps(lat: targetLat, long: targetLong)
    }

    private func openGoogleMaps(lat: Double, long: Double) {
        let appScheme = "comgooglemaps://?q=\(lat),\(long)&zoom=14"
        let browserUrl = "http://googleusercontent.com/maps.google.com/?q=\(lat),\(long)"

        if let appUrl = URL(string: appScheme), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else if let webUrl = URL(string: browserUrl), let url = URL(
            string: webUrl.absoluteString
        ) {
            UIApplication.shared.open(url)
        }
    }
}
