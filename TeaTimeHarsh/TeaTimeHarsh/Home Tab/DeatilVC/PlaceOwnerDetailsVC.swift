//
//  PlaceOwnerDetailsVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/01/26.
//

import UIKit

class PlaceOwnerDetailsVC: UIViewController {
    @IBOutlet var lblBirthDate: UILabel!
    @IBOutlet var lblFullName: UILabel!
    @IBOutlet var lblContactNumber: UILabel!

    @IBOutlet var lblBio: UILabel!
    @IBOutlet var lblEmail: UILabel!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var imgOwner: UIImageView!

    var placeOwnerUser: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageCofiguration()
        setUpOwnerDetails()
    }

    private func setUpOwnerDetails() {
        guard let ownerUser = placeOwnerUser else { return }
        lblFullName.text = "Place Owner's Name : " + (ownerUser.fullName ?? "Not Updated")
        lblUserName.text = "Place Owner's username : " + (ownerUser.username ?? "Not Updated")
        lblEmail.text = "Place Owner's email : " + (ownerUser.email)
        lblBio.text = "Place Owner's Bio : " + (ownerUser.bio ?? "Not Updated")
        lblBirthDate.text = "Place Owner's Birthdate : " + (ownerUser.birthDateString)
        lblContactNumber.text = "Place Owner's Contact number : " + (ownerUser.phoneNumber ?? "Not Updated")
        ImageManagerKF
            .setImage(
                from: ownerUser.profileImageUrl,
                into: imgOwner,
                placeholderName: ""
            )
    }
    
    private func setupImageCofiguration() {
        imgOwner.applyCircularProfileStyle()
        imgOwner.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        imgOwner.addGestureRecognizer(tap)
    }
    
    @objc private func didTapProfileImage() {
        HapticHelper.medium()

        ImageZoomViewer.shared
            .showFullScreen(
                from: imgOwner ?? UIImageView(),
                backgroundColor: .white
            )
    }
    
}
