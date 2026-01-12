//
//  RatingReviewVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 12/01/26.
//

import Cosmos
import UIKit

class PlaceReviewVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet var tblReview: UITableView!
    @IBOutlet var imgReview: UIImageView!
    @IBOutlet var viewRating: CosmosView!
    @IBOutlet var txtViewReview: UITextView!
    @IBOutlet var lblShareExp: UILabel!
    @IBOutlet var titleReview: UILabel!
    @IBOutlet var btnSubmitReview: UIButton!

    // MARK: - Properties

    var selectedRating: Double = 0.0 // Default 0

    var arrReviews: [PlaceReview]? {
        didSet {
            // Reload table automatically when data is set
            DispatchQueue.main.async { [weak self] in
                self?.tblReview.reloadData()
            }
        }
    }

    var place: TeaPlace?
    private var hasSelectedNewImage = false

    var reloadRating: (() -> Void)?

    // Constants for TextView
    private let placeholderText = "Share your experience here... (Max 200 chars)"
    private let placeholderColor = UIColor.systemGray2
    private let activeTextColor = UIColor.label

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        // TableView
        tblReview.delegate = self
        tblReview.dataSource = self
        tblReview.separatorStyle = .none // Cleaner look

        // TextView
        setupTextView()

        // Image View
        setupImageConfiguration()

        // Star Rating (Using Extension) 🔥
        viewRating.applyTeaThemeStyle(starSize: 30, isEditable: true, color: .systemOrange)
        viewRating.rating = 0.0
        viewRating.text = "Rating"

        // Callback for rating
        viewRating.didFinishTouchingCosmos = { [weak self] rating in
            print("Selected Rating: \(rating)")
            self?.selectedRating = rating
        }
    }

    private func setupTextView() {
        txtViewReview.delegate = self
        txtViewReview.backgroundColor = .tertiarySystemBackground

        // Set Initial Placeholder
        txtViewReview.text = placeholderText
        txtViewReview.textColor = placeholderColor
        Utility.styleTextView(txtViewReview)
    }

    private func setupImageConfiguration() {
        imgReview.clipsToBounds = true
        imgReview.layer.cornerRadius = 10
        imgReview.layer.borderWidth = 1
        imgReview.layer.borderColor = UIColor.systemGray4.cgColor
        imgReview.contentMode = .scaleAspectFit
        imgReview.backgroundColor = .tertiarySystemBackground

        // Improved UX: Camera icon indicates action
        imgReview.image = UIImage(systemName: "plus")
        imgReview.tintColor = .systemIndigo
        imgReview.contentMode = .scaleAspectFit

        imgReview.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSelectReviewImage))
        imgReview.addGestureRecognizer(tap)
    }

    private func setupData() {
        if let placeName = place?.name {
            titleReview.text = "\(placeName) Reviews"
            lblShareExp.text = "How was your chai at \(placeName)?"
        }
    }

    // MARK: - Actions

    @objc private func didTapSelectReviewImage() {
        HapticHelper.success()
        view.endEditing(true) // Dismiss keyboard

        ImagePickerManager.shared.pickSingleImage(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }
            self.hasSelectedNewImage = true
            self.imgReview.image = image
        }
    }

    @IBAction func btnSubmitReviewTapped(_ sender: UIButton) {
        view.endEditing(true) // Dismiss keyboard first

        // 1. Validation Logic
        if !validateInput() { return }

        // 2. Prepare Data
        guard let currentLoggedInUser = UserDataManager.shared.user,
              let currentPlaceId = place?.id,
              let reviewText = txtViewReview.text,
              let selectedImageReview = imgReview.image else { return }

        // 3. Submit Review

        Utility
            .showYesNoConfirmAlert(
                title: "Submit Review? ⚠️",
                message: "You can submit a review for every place only once. If a review already exists, it will be replaced. Each user can submit only one review per place. Do you want to continue?",
                viewController: self) { _ in
                    self.submitReview(placeId: currentPlaceId, user: currentLoggedInUser, text: reviewText, image: selectedImageReview)
            } noAction: { _ in
                print("no tapped at review replace dialogue")
            }
    }

    // Separated Validation Logic for cleaner code
    private func validateInput() -> Bool {
        // Check Image
        guard hasSelectedNewImage, imgReview.image != nil else {
            Utility.showAlert(title: "Photo Required 📸",
                              message: "We'd love to see your visit of tea place! Please attach a photo to make your review authentic.",
                              viewController: self)
            return false
        }

        // Check User Login
        guard UserDataManager.shared.user != nil else {
            Utility.showAlert(title: "Login Required 👤",
                              message: "Please log in to share your experience.Logout from profile and re-login to continue.",
                              viewController: self)
            return false
        }

        // Check Text Content
        guard let reviewText = txtViewReview.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reviewText.isEmpty, reviewText != placeholderText else {
            Utility.showAlert(title: "Review Empty ✍️",
                              message: "Please tell us a little bit about the place.",
                              viewController: self)
            return false
        }

        // Check Text Length
        guard reviewText.count <= 200 else {
            Utility.showAlert(title: "Too Long 📏",
                              message: "Please keep your review under 200 characters.",
                              viewController: self)
            return false
        }

        // Check Rating
        guard selectedRating > 0.0 else {
            Utility.showAlert(title: "Rating Missing ⭐️",
                              message: "Please give a star rating as per your experience.",
                              viewController: self)
            return false
        }

        return true
    }

    private func submitReview(placeId: String, user: User, text: String, image: UIImage) {
        // UI Safety: Prevent double tapping
        btnSubmitReview.isEnabled = false
        LoaderManager.shared.startLoading()

        Task {
            do {
                try await FirebaseManager.shared.submitReview(
                    placeId: placeId,
                    user: user,
                    rating: selectedRating,
                    reviewText: text,
                    reviewImage: image
                )

                // Success Handling
                LoaderManager.shared.stopLoading()
                self.reloadRating?()
                print("✅ Review Submitted Successfully!")

                Utility.showAlertHandler(
                    title: "Thank You.☕️ Review Submitted Successfully! ",
                    message: "Your review has been shared with the community.✅",
                    viewController: self) { [weak self] _ in
                        self?.dismiss(animated: true)
                    }

            } catch {
                // Error Handling
                LoaderManager.shared.stopLoading()
                btnSubmitReview.isEnabled = true // Re-enable button on error

                print("❌ Error: \(error.localizedDescription)")
                Utility.showAlert(title: "Upload Failed. please try again.",
                                  message: error.localizedDescription,
                                  viewController: self)
            }
        }
    }
}

// MARK: - TextView Delegate

extension PlaceReviewVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = activeTextColor
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = placeholderColor
        }
    }
}

// MARK: - TableView Delegate & DataSource

extension PlaceReviewVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrReviews?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceReviewTableCell", for: indexPath) as! PlaceReviewTableCell

        if let review = arrReviews?[indexPath.row] {
            cell.configurePlaceReviews(with: review)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }
}

class PlaceReviewTableCell: UITableViewCell {
    @IBOutlet var viewBg: UIView! {
        didSet {
            viewBg.layer.cornerRadius = 10
            // Optional: Add shadow for better look
            viewBg.layer.shadowColor = UIColor.systemGray3.cgColor
            viewBg.layer.shadowOpacity = 0.1
            viewBg.layer.shadowOffset = CGSize(width: 0, height: 2)
            viewBg.layer.shadowRadius = 4
        }
    }

    @IBOutlet var imgReview: UIImageView!
    @IBOutlet var lblReview: UILabel!
    @IBOutlet var viewRatingCell: CosmosView!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var imgUser: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        // User Image
        imgUser.layer.cornerRadius = imgUser.frame.height / 2
        imgUser.contentMode = .scaleAspectFill
        imgUser.clipsToBounds = true

        // Review Image
        imgReview.layer.cornerRadius = 10
        imgReview.contentMode = .scaleAspectFill
        imgReview.clipsToBounds = true

        // Tap Gesture
        imgReview.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapReviewImage))
        imgReview.addGestureRecognizer(tap)

        // Star Rating (Using Extension) ⭐️
        viewRatingCell.applyTeaThemeStyle(starSize: 20, isEditable: false, color: .systemIndigo)
    }

    func configurePlaceReviews(with review: PlaceReview) {
        viewRatingCell.rating = review.rating
        lblReview.text = review.reviewText
        lblUserName.text = review.userName
        ImageManagerKF
            .setImage(
                from: review.userImage,
                into: imgUser,
                placeholderName: ""
            )
        ImageManagerKF
            .setImage(
                from: review.reviewImageURL,
                into: imgReview,
                placeholderName: ""
            )
    }

    @objc private func didTapReviewImage() {
        HapticHelper.medium()
        if imgReview.image != nil {
            ImageZoomViewer.shared.showFullScreen(from: imgReview, backgroundColor: .black)
        }
    }
}
