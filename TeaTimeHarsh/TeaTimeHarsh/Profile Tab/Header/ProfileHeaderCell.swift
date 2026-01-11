//
//  ProfileHeaderCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import UIKit

class ProfileHeaderCell: UIView {
    @IBOutlet var imgProfile: UIImageView!

    var didTapProfileImage: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        setupView()
    }

    func setupView() {
        imgProfile.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imgProfile.addGestureRecognizer(tap)

        imgProfile.clipsToBounds = true
        imgProfile.layer.cornerRadius = 65
        imgProfile.layer.borderColor = UIColor.systemIndigo.cgColor
        imgProfile.layer.borderWidth = 0.5

        setProfileImage()
    }

    func setProfileImage() {
        if let profileUrl = UserDataManager.shared.user?.profileImageUrl {
            ImageManagerKF
                .setImage(
                    from: profileUrl,
                    into: imgProfile,
                    placeholderName: ""
                )
        }
    }

    @objc func handleTap() {
        // 4. Ring the phone! (Trigger the action)
        didTapProfileImage?()
    }
}
