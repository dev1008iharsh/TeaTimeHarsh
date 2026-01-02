//
//  TeaListTableList.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import UIKit

class TeaListCell: UITableViewCell {
    // MARK: - IBOutlet

    @IBOutlet var imgTeaPlace: UIImageView! {
        didSet {
            imgTeaPlace.layer.cornerRadius = 10
        }
    }
    @IBOutlet var lblRating: UILabel!
    @IBOutlet var lblLocationTeaPlace: UILabel!
    @IBOutlet var lblPhoneTeaPlace: UILabel!
    @IBOutlet var lblNameTeaPlace: UILabel!

    @IBOutlet var imgFav: UIImageView! {
        didSet {
            imgFav.tintColor = .red
            imgFav.backgroundColor = .white
            imgFav.layer.cornerRadius = 5
        }
    }

    @IBOutlet var lblVisited: UILabel!

    // MARK: - Properties

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Configure Data

    func configure(teaPlace: TeaPlace) {
        //imgTeaPlace.image = teaPlace.image
        ImageManagerKF
            .setImage(
                from: teaPlace.imageURL,
                into: imgTeaPlace,
                placeholderName: "photo"
            )
        lblRating.text = "⭐️ " + (teaPlace.rating?.description ?? "5") 
        lblLocationTeaPlace.text = teaPlace.location
        lblPhoneTeaPlace.text = teaPlace.phone?.description ?? "N/A"
        lblNameTeaPlace.text = teaPlace.name
        
        // lblVisited.isHidden = !teaPlace.isVisited //same as under 
        lblVisited.isHidden = teaPlace.isVisited ? false : true
        imgFav.image = UIImage(
            systemName: teaPlace.isFav ? "heart.fill" : "heart"
        )
    }
}
