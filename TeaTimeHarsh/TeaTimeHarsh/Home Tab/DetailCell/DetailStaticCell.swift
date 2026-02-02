//
//  DetailStaticCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import GoogleMaps
import UIKit

class DetailStaticCell: UITableViewCell {
    // MARK: - IBOutlets

    // Basic Information
    @IBOutlet var btnPlaceOwner: UIButton!

    @IBOutlet var btnPhone: UIButton!

    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var lblAddress: UILabel!

    // Extra Details
    @IBOutlet var lblServingSince: UILabel!
    @IBOutlet var lblPriceRange: UILabel!
    @IBOutlet var lblClosingTime: UILabel!
    @IBOutlet var lblOpeningTime: UILabel!
    @IBOutlet var lblWebsite: UILabel!

    @IBOutlet var imgVideoThumb: UIImageView!
    @IBOutlet var imgMenuImage: UIImageView!

    // Containers
    @IBOutlet var mapContainerView: UIView!

    @IBOutlet var videoContainerView: UIView!
    @IBOutlet var pdfContainerView: UIView!

    // Action Buttons
    @IBOutlet var btnEdit: UIButton!
    @IBOutlet var btnDelete: UIButton!
    @IBOutlet var btnShare: UIButton!

    // MARK: - 🆕 Closures (Actions for Controller)

    // These closures will tell the ViewController when a button is tapped.
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    var onShareTapped: (() -> Void)?
    var onPlaceOwnerTapped: (() -> Void)?
    var onCallTapped: (() -> Void)?
    var onWebsiteTapped: ((String) -> Void)?

    var onVideoThumbTapped: ((String) -> Void)?
    var onMenuImageTapped: ((String) -> Void)?

    // MARK: - Properties

    // Default Apple Campus Lat long
    private var targetLat = 37.331705
    private var targetLong = 122.030237
    private var googleMapView: GMSMapView?

    var placeOwnerUser: User?

    // Property Observer: Automatically configures the cell when data is assigned
    var teaPlace: TeaPlace? {
        didSet { configure() }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupPreviewGestures()
        if AppNetworkManager.shared.isConnected {
            mapContainerView.isHidden = false
            configureGoogleMap()
            addTapGestureToMap()
        } else {
            mapContainerView.isHidden = true
        }
    }

    private func setupUI() {
        btnPhone.layer.cornerRadius = btnPhone.bounds.height / 2
        btnPlaceOwner.layer.cornerRadius = btnPhone.bounds.height / 2

        mapContainerView.layer.cornerRadius = 20
        videoContainerView.layer.cornerRadius = 20
        pdfContainerView.layer.cornerRadius = 20

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapWebsite))
        lblWebsite.isUserInteractionEnabled = true
        lblWebsite.addGestureRecognizer(tap)
    }

    private func setupPreviewGestures() {
        // 1. Video Tap Gesture
        let videoTap = UITapGestureRecognizer(target: self, action: #selector(didTapVideoPreview))
        imgVideoThumb.isUserInteractionEnabled = true
        imgVideoThumb.addGestureRecognizer(videoTap)

        // 2. PDF Tap Gesture
        let pdfTap = UITapGestureRecognizer(target: self, action: #selector(didTapPDFPreview))
        imgMenuImage.isUserInteractionEnabled = true
        imgMenuImage.addGestureRecognizer(pdfTap)
    }

    @objc private func didTapWebsite() {
        HapticHelper.success()
        if let strWebsiteURL = teaPlace?.website {
            onWebsiteTapped?(strWebsiteURL)
        }
    }

    @objc private func didTapVideoPreview() {
        HapticHelper.light()
        if let strVideoURL = teaPlace?.videoURL {
            onVideoThumbTapped?(strVideoURL)
        }
    }

    @objc private func didTapPDFPreview() {
        HapticHelper.light()
        if let strPdfURL = teaPlace?.pdfURL {
            onMenuImageTapped?(strPdfURL)
        }
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
        lblWebsite.text = place.website ?? ""
 
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
        setOwnerName()

        // 7. set video thumbnail
        ImageManagerKF.setImage(from: place.videoThumbnailURL, into: imgVideoThumb)
        //imgMenuImage.image = UIImage(named: "placeholder") // placeholder
        
        // 8. set pdf thumbnail
        if let urlOfPDF = place.pdfURL {
            setPdfMenuThumbnail(pdfURL: urlOfPDF)
        }
    }

    private func setPdfMenuThumbnail(pdfURL: String) {
        if let url = URL(string: pdfURL) {
            let targetSize = imgMenuImage.bounds.size
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                // Generate Thumbnail using your PDFHelper
                if let thumbnail = PDFHelper.generateTwoPageThumbnail(of: targetSize, for: url) {
                    DispatchQueue.main.async {
                        self.imgMenuImage.image = thumbnail
                    }
                } else {
                    DispatchQueue.main.async {
                        LoaderManager.shared.stopLoading()
                        print("❌ Failed to generate PDF thumbnail")
                    }
                }
            }
        }
    }

    private func setOwnerName() {
        if let owner = placeOwnerUser {
            if let ownerName = owner.fullName {
                btnPlaceOwner.setTitle("Place Created by : " + ownerName, for: .normal)
            } else {
                if let email = placeOwnerUser?.email, !email.isEmpty {
                    let username = usernameFromEmail(email)

                    btnPlaceOwner.setTitle("Place Created by : \(username)", for: .normal)
                }
            }
        }
    }

    private func usernameFromEmail(_ email: String) -> String {
        // Split email by "@"
        let components = email.split(separator: "@")

        // Return part before "@"
        return String(components.first ?? "")
    }

    // MARK: - 🆕 IBActions (Triggers)

    @IBAction func btnPlaceOwnerTapped(_ sender: UIButton) {
        HapticHelper.light()
        onPlaceOwnerTapped?()
    }

    @IBAction func btnEditTappedDetail(_ sender: UIButton) {
        HapticHelper.light()
        // Trigger the closure to notify the ViewController
        onEditTapped?()
    }

    @IBAction func btnDeleteTappedDetail(_ sender: UIButton) {
        HapticHelper.light()
        onDeleteTapped?()
    }

    @IBAction func btnShareTappedDetail(_ sender: UIButton) {
        HapticHelper.light()
        onShareTapped?()
    }

    @IBAction func btnCallTapped(_ sender: UIButton) {
        HapticHelper.light()
        onCallTapped?()
    }

    @objc private func mapTapped() {
        HapticHelper.heavy()
        print("📍 Map Tapped! Redirecting...")
        guard AppNetworkManager.shared.isConnected else {
            return
        } 
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
