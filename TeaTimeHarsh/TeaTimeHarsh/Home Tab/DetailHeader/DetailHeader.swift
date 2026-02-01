//
//  DetailHeader.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import UIKit

class DetailHeader: UIView {
    // MARK: - IBOutlets

    @IBOutlet var lblOpenCloseNow: UILabel!
    @IBOutlet var lblReview: UILabel!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblCityLocaton: UILabel!

    @IBOutlet var imgPlace: UIImageView! {
        didSet {
            imgPlace.contentMode = .scaleAspectFill
            imgPlace.clipsToBounds = true
        }
    }

    @IBOutlet var btnFav: UIButton! {
        didSet { btnFav.layer.cornerRadius = 20 }
    }

    @IBOutlet var btnVisited: UIButton! {
        didSet { btnVisited.layer.cornerRadius = 20 }
    }

    // MARK: - Properties

    // ⚠️ We need to store these to send in the Notification
    private var currentPlaceID: String?
    private var isFavState: Bool = false
    private var isVisitState: Bool = false

    var onReviewTapped: (() -> Void)?

    // MARK: - Init

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Do nothing here
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        lblReview.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapReviewLabel))
        lblReview.addGestureRecognizer(tap)
        
        imgPlace.isUserInteractionEnabled = true
        let placeImgTap = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgPlace.addGestureRecognizer(placeImgTap)
    }

    @objc private func didTapReviewLabel() {
        onReviewTapped?()
    }
    @objc private func didTapPlaceImage() {
        HapticHelper.medium()
        if imgPlace.image != nil {
            ImageZoomViewer.shared.showFullScreen(from: imgPlace, backgroundColor: .black)
        }
    }

    // MARK: - Configuration Method

    func configure(place: TeaPlace) {
        currentPlaceID = place.id
        isFavState = place.isFav
        isVisitState = place.isVisited

        lblName.text = place.name
        lblOpenCloseNow.text = place.isOpenNow ? "🟢 Open Now" : "🔴 Closed Now"
        if let rating = place.rating, let totalReviews = place.totalReviewCount {
            lblReview.text = "Average " + rating.description + " ⭐️ " + "(\(totalReviews.description))"
        }

        lblCityLocaton.text = "\(place.city ?? "Default Location")"

        ImageManagerKF.setImage(
            from: place.imageURL,
            into: imgPlace,
            placeholderName: ""
        )

        // Set Initial Button States
        updateVisitedButton(isVisited: place.isVisited)
        updateFavouriteButton(isFavourite: place.isFav)

        // 🆕 LISTEN FOR REVERT: If HomeVC says API failed, we must revert visual state
        NotificationCenter.default.addObserver(self, selector: #selector(handleAPIFailure(_:)), name: .teaPlaceUpdateFailed, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 🔔 Notification Actions (Fav / Visit)

    @IBAction func visitButtonTapped(_ sender: UIButton) {
        guard let placeID = currentPlaceID else { return }

        // 1. Optimistic UI Update (Visual Only)
        isVisitState.toggle()
        updateVisitedButton(isVisited: isVisitState)
        HapticHelper.heavy()

        // 2. Post Notification - update backend using api
        NotificationCenter.default.post(
            name: .teaPlaceDidTapVisit,
            object: nil,
            userInfo: ["placeID": placeID, "isVisited": isVisitState]
        )
    }

    @IBAction func favouriteButtonTapped(_ sender: UIButton) {
        guard let placeID = currentPlaceID else { return }

        // 1. Optimistic UI Update (Visual Only)
        isFavState.toggle()
        updateFavouriteButton(isFavourite: isFavState)
        HapticHelper.heavy()

        // 2. Post Notification - update backend using api
        NotificationCenter.default.post(
            name: .teaPlaceDidTapFav,
            object: nil,
            userInfo: ["placeID": placeID, "isFav": isFavState]
        )
    }

    // MARK: - ⚠️ Revert Logic (If API Fails)

    @objc func handleAPIFailure(_ notification: Notification) {
        guard let failedID = notification.userInfo?["placeID"] as? String,
              failedID == currentPlaceID,
              let actionType = notification.userInfo?["actionType"] as? String else { return }

        // Revert the visual state back
        if actionType == "fav" {
            isFavState.toggle() // Flip back
            updateFavouriteButton(isFavourite: isFavState)
        } else if actionType == "visit" {
            isVisitState.toggle() // Flip back
            updateVisitedButton(isVisited: isVisitState)
        }
    }

    // MARK: - UI Updates

    private func updateVisitedButton(isVisited: Bool) {
        if isVisited {
            btnVisited.animateAndConfigure(title: "Remove from Visited", systemImageName: "checkmark.circle.fill", backgroundColor: .systemGreen)
        } else {
            btnVisited.animateAndConfigure(title: "Mark Visited", systemImageName: "checkmark.circle", backgroundColor: .systemGray)
        }
    }

    private func updateFavouriteButton(isFavourite: Bool) {
        if isFavourite {
            btnFav.animateAndConfigure(title: "Remove Favourite", systemImageName: "heart.fill", backgroundColor: .systemPink)
        } else {
            btnFav.animateAndConfigure(title: "Mark Favourite", systemImageName: "heart", backgroundColor: .systemGray)
        }
    }
}
