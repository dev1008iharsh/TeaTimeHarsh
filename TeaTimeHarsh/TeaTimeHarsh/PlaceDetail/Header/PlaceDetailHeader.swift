//
//  PlaceDetailHeader.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

class PlaceDetailHeader: UIView {
    // MARK: - IBOutlet

    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblLocaton: UILabel! {
        didSet {
            lblLocaton.textColor = .systemBackground
            lblLocaton.backgroundColor = .systemYellow
        }
    }

    @IBOutlet var imgPlace: UIImageView!

    @IBOutlet var btnFav: UIButton! {
        didSet {
            btnFav.layer.cornerRadius = 20
        }
    }

    @IBOutlet var btnVisited: UIButton! {
        didSet {
            btnVisited.layer.cornerRadius = 20
        }
    }

    // MARK: - Properties

    // ONE closure, not two
    var onButtonTap: ((HeaderButtonType) -> Void)?

    enum HeaderButtonType {
        case visit
        case favourite
    }

    // MARK: - Lifecycle

    func configure(place: TeaPlace) {
        lblName.text = place.name
        lblLocaton.text = place.location
        imgPlace.image = place.image

        updateVisitedButton(isVisited: place.isVisited)

        if FavouritePlacesStore.favourites.contains(place.id) {
            updateFavouriteButton(isFavourite: true)
        } else {
            updateFavouriteButton(isFavourite: false)
        }
    }

    // MARK: - Button Actions

    @IBAction func visitButtonTapped(_ sender: UIButton) {
        onButtonTap?(.visit)
    }

    @IBAction func favouriteButtonTapped(_ sender: UIButton) {
        onButtonTap?(.favourite)
    }

    // MARK: - Helpers

    func configureButtonwithImage(
        _ button: UIButton,
        backgroundColor: UIColor,
        title: String,
        systemImageName: String
    ) {
        // Step 1: Zoom up
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            button.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in

            // Step 2: Change state (icon, text, color)
            UIView.transition(
                with: button,
                duration: 0.18,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                var config = UIButton.Configuration.plain()
                config.title = title
                config.image = UIImage(systemName: systemImageName)
                config.imagePlacement = .leading
                config.imagePadding = 5
                config.baseForegroundColor = .white

                button.configuration = config
                button.backgroundColor = backgroundColor
            }

            // Step 3: Zoom back to normal
            UIView.animate(
                withDuration: 0.15,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                button.transform = .identity
            }
        }
    }

    func updateVisitedButton(isVisited: Bool) {
        if isVisited {
            configureButtonwithImage(
                btnVisited,
                backgroundColor: .systemGreen,
                title: "Remove from Visited",
                systemImageName: "checkmark.circle.fill"
            )
        } else {
            configureButtonwithImage(
                btnVisited,
                backgroundColor: .systemGray,
                title: "Mark Visited",
                systemImageName: "checkmark.circle"
            )
        }
    }

    func updateFavouriteButton(isFavourite: Bool) {
        if isFavourite {
            configureButtonwithImage(
                btnFav,
                backgroundColor: .systemPink,
                title: "Remove Favourite",
                systemImageName: "heart.fill"
            )
        } else {
            configureButtonwithImage(
                btnFav,
                backgroundColor: .systemGray,
                title: "Mark Favourite",
                systemImageName: "heart"
            )
        }
    }

    /*
     var onSubmitTap: (() -> Void)?

     @IBAction func submitButton(_ sender: UIButton) {
     print("Header button tapped - UserHeaderView: UIView")
     onSubmitTap?()
     }*/
}
