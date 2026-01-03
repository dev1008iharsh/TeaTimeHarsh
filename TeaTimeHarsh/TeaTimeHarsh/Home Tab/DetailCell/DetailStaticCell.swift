//
//  DetailStaticCell.swift
//  TeaTimeHarsh
 

import GoogleMaps
import UIKit

class DetailStaticCell: UITableViewCell {
    
    // MARK: - IBOutlets

    // Basic Information
    @IBOutlet var btnPhone: UIButton! {
        didSet {
            btnPhone.layer.cornerRadius = btnPhone.bounds.height / 2
        }
    }

    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var lblAddress: UILabel!

    // Extra Details
    @IBOutlet var lblServingSince: UILabel!
    @IBOutlet var lblPriceRange: UILabel!
    @IBOutlet var lblClosingTime: UILabel!
    @IBOutlet var lblOpeningTime: UILabel!

    // Map Container with Corner Radius
    @IBOutlet var mapContainerView: UIView! {
        didSet {
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    // Action Buttons
    @IBOutlet var btnEdit: UIButton!
    @IBOutlet var btnDelete: UIButton!
    @IBOutlet var btnShare: UIButton!

    // MARK: - 🆕 Closures (Actions for Controller)
    
    // These closures will tell the ViewController when a button is tapped.
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    var onShareTapped: (() -> Void)?

    // MARK: - Properties

    // Default Apple Campus Lat long
    private var targetLat = 37.331705
    private var targetLong = 122.030237
    private var googleMapView: GMSMapView?

    // Property Observer: Automatically configures the cell when data is assigned
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
        // Initialize Google Map with minimal UI controls for a clean look
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
        // Add gesture recognizer to open full map on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        googleMapView?.addGestureRecognizer(tapGesture)
    }

    // MARK: - Data Population & Logic

    private func configure() {
        guard let place = teaPlace else { return }

        // 1. Set Basic Info
        let phoneText = place.phone ?? "N/A"
        btnPhone.setTitle("Connect via \(phoneText)", for: .normal)
        lblDesc.text = place.desc ?? "No description available."
        lblAddress.text = place.address ?? "Address not available."

        // 2. Set Extra Info
        lblPriceRange.text = "Rs." + (place.priceRange ?? "")
        lblOpeningTime.text = "Open at : " + (place.openingTime ?? "")
        lblClosingTime.text = "Close at : " + (place.closingTime ?? "")

        // 3. Calculate and Set Duration
        // This helper calculates how long the place has been serving (e.g., "1 Year, 4 Days")
        let durationString = Utility.getServingDuration(from: place.createdAt)
        lblServingSince.text = "Place registered in-app \(durationString) Ago"

        // 4. Update Map Location
        targetLat = place.latitude ?? 0.0
        targetLong = place.longitude ?? 0.0
        GoogleMapHelper.updateLocation(mapView: googleMapView, lat: targetLat, long: targetLong, showMarker: true)
        
        // 5. Check Owner Permissions
        // We use the TeaActionManager helper to check if the current user created this place.
        let isOwner = TeaActionManager.canModify(place: place)
        
        // 6. Manage Button Visibility
        // Hide Edit & Delete buttons if the user is not the owner.
        // Share button remains visible for everyone.
        btnEdit.isHidden = !isOwner
        btnDelete.isHidden = !isOwner
    }

    // MARK: - 🆕 IBActions (Triggers)

    @IBAction func btnEditTappedDetail(_ sender: UIButton) {
        // Trigger the closure to notify the ViewController
        onEditTapped?()
    }

    @IBAction func btnDeleteTappedDetail(_ sender: UIButton) {
        onDeleteTapped?()
    }

    @IBAction func btnShareTappedDetail(_ sender: UIButton) {
        onShareTapped?()
    }

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
        // Construct URLs for Google Maps App and Browser fallback
        let appScheme = "comgooglemaps://?q=\(lat),\(long)&zoom=14"
        let browserUrl = "http://googleusercontent.com/maps.google.com/?q=\(lat),\(long)"

        if let appUrl = URL(string: appScheme), UIApplication.shared.canOpenURL(appUrl) {
            // Open in App
            UIApplication.shared.open(appUrl)
        } else if let webUrl = URL(string: browserUrl), let url = URL(string: webUrl.absoluteString) {
            // Open in Browser
            UIApplication.shared.open(url)
        }
    }
}
