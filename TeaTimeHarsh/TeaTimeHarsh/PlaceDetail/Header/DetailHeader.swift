//
//  DetailHeader.swift
//  TeaTimeHarsh


import UIKit

class DetailHeader: UIView {
    
    // MARK: - Enums
    enum HeaderButtonType {
        case visit
        case favourite
    }

    // MARK: - IBOutlets
    @IBOutlet var lblOpenCloseNow: UILabel!
    @IBOutlet var lblRating: UILabel!
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
    var onButtonTap: ((HeaderButtonType) -> Void)?

    // MARK: - Configuration Method
    func configure(place: TeaPlace) {
        lblName.text = place.name
        lblOpenCloseNow.text = place.isOpenNow ? "🔴 Open Now" : "🔴 Closed Now"
        lblRating.text = "⭐️ " + (place.rating?.description ?? "5")
        lblCityLocaton.text = "\(place.location ?? "Default Location")"
        
        // Load Image using our Kingfisher Manager 🖼️
        ImageManagerKF.setImage(
            from: place.imageURL,
            into: imgPlace,
            placeholderName: "photo"
        )
        
        // Set Initial Button States
        updateVisitedButton(isVisited: place.isVisited)
        updateFavouriteButton(isFavourite: place.isFav)
    }

    // MARK: - Button Actions
    @IBAction func visitButtonTapped(_ sender: UIButton) {
        onButtonTap?(.visit)
    }

    @IBAction func favouriteButtonTapped(_ sender: UIButton) {
        onButtonTap?(.favourite)
    }
    
    // MARK: - UI Updates (Animatable)
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
}
