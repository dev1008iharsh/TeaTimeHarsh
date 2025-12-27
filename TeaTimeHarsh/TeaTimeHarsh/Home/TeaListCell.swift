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

    @IBOutlet var lblLocationTeaPlace: UILabel!
    @IBOutlet var lblPhoneTeaPlace: UILabel!
    @IBOutlet var lblNameTeaPlace: UILabel!

    @IBOutlet var isFavImage: UIImageView! {
        didSet {
            isFavImage.tintColor = .red
            isFavImage.backgroundColor = .white
            isFavImage.layer.cornerRadius = 5
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
        imgTeaPlace.image = teaPlace.image
        lblLocationTeaPlace.text = teaPlace.location
        lblPhoneTeaPlace.text = teaPlace.phone?.description ?? "N/A"
        lblNameTeaPlace.text = teaPlace.name
        // lblVisited.isHidden = !teaPlace.isVisited
        lblVisited.isHidden = teaPlace.isVisited ? false : true
    }
}
