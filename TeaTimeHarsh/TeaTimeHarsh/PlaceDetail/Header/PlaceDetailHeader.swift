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
            lblLocaton.clipsToBounds = true
            lblLocaton.layer.cornerRadius = 10
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
        lblLocaton.text = "  \(place.location ?? "")  "
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

    

    func updateVisitedButton(isVisited: Bool) {
        if isVisited {
            btnVisited.animateAndConfigure(title: "Remove from Visited", systemImageName: "checkmark.circle.fill", backgroundColor: .systemGreen)
        } else {
            btnVisited.animateAndConfigure(title: "Mark Visited", systemImageName: "checkmark.circle", backgroundColor: .systemGray)
        }
    }

    func updateFavouriteButton(isFavourite: Bool) {
        if isFavourite {
            btnFav.animateAndConfigure(title: "Remove Favourite", systemImageName: "heart.fill", backgroundColor: .systemPink)
        } else {
            btnFav.animateAndConfigure(title: "Mark Favourite", systemImageName: "heart", backgroundColor: .systemGray)
        }
    }

    /*
     var onSubmitTap: (() -> Void)?

     @IBAction func submitButton(_ sender: UIButton) {
     print("Header button tapped - UserHeaderView: UIView")
     onSubmitTap?()
     }*/
}
