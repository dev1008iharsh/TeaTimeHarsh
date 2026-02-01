//
//  TeaListCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import UIKit

class TeaListCell: UITableViewCell {
    // MARK: - Outlets

    @IBOutlet var bgView: UIView!
    @IBOutlet var lblRating: UILabel!
    @IBOutlet var lblLocationTeaPlace: UILabel!
    @IBOutlet var lblPhoneTeaPlace: UILabel!
    @IBOutlet var lblNameTeaPlace: UILabel!
    @IBOutlet var lblVisited: UILabel!

    @IBOutlet var imgTeaPlace: UIImageView!
    @IBOutlet var imgFav: UIImageView!

    // MARK: - Properties

    var onFavTapped: (() -> Void)?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGestures()
    }

    // 🔥 Optimization: Reset cell before reuse to prevent wrong data/images during fast scroll
    override func prepareForReuse() {
        super.prepareForReuse()
        imgTeaPlace.image = nil
        imgFav.image = nil
        lblVisited.isHidden = true
    }

    // MARK: - 🎨 UI Configuration

    private func setupUI() {
        // Background & Selection
        selectionStyle = .none

        // Image Styling
        imgTeaPlace.layer.cornerRadius = 10
        imgTeaPlace.contentMode = .scaleAspectFill
        imgTeaPlace.clipsToBounds = true

        // Fav Icon Styling
        imgFav.tintColor = .systemRed
        imgFav.backgroundColor = .tertiarySystemGroupedBackground
        imgFav.layer.cornerRadius = 5
        imgFav.isUserInteractionEnabled = true
        
        imgTeaPlace.isUserInteractionEnabled = true
        let placeImgTap = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgTeaPlace.addGestureRecognizer(placeImgTap)
    }

    // MARK: - 👆 Interactions

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapFavPlace))
        imgFav.addGestureRecognizer(tap)
    }

    @objc private func didTapFavPlace() {
        // ✨ Haptic Feedback for better UX
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Trigger Action
        onFavTapped?()

        // Optional: Local bounce animation for instant feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.imgFav.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.imgFav.transform = .identity
            }
        }
    }

    // MARK: - 📦 Data Injection

    func configure(teaPlace: TeaPlace) {
        // 1. Load Image
        ImageManagerKF.setImage(
            from: teaPlace.imageURL,
            into: imgTeaPlace,
            placeholderName: ""
        )

        // 2. Set Text Data
        lblRating.text = "⭐️ \(teaPlace.rating?.description ?? "5")"
        lblLocationTeaPlace.text = teaPlace.city
        lblPhoneTeaPlace.text = teaPlace.phone?.description ?? "N/A"
        lblNameTeaPlace.text = teaPlace.name

        // 3. Update Status
        lblVisited.isHidden = !teaPlace.isVisited

        let heartIcon = teaPlace.isFav ? "heart.fill" : "heart"
        imgFav.image = UIImage(systemName: heartIcon)
    }
    @objc private func didTapPlaceImage() {
        HapticHelper.medium()
        if imgTeaPlace.image != nil {
            ImageZoomViewer.shared.showFullScreen(from: imgTeaPlace, backgroundColor: .black)
        }
    }
}
