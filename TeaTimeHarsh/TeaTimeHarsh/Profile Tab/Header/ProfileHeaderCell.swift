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

        imgProfile.applyCircularProfileStyle()
        imgProfile.layer.cornerRadius = 65
        setProfileImage()
    }

    func setProfileImage() {

        // 1️⃣ Check if profile is completed
        guard let user = UserDataManager.shared.user,
              let fullName = user.fullName,
              !fullName.isEmpty else {

            print("❌ Profile not completed → default system image")
            imgProfile.image = UIImage(systemName: "person.circle.fill")
            return
        }

        // 2️⃣ Profile completed → check internet
        if AppNetworkManager.shared.isConnected {

            print("🌐 Online → load image from URL")
            
            if let profileUrl = user.profileImageUrl, !profileUrl.isEmpty {
                ImageManagerKF.setImage(
                    from: profileUrl,
                    into: imgProfile,
                    placeholderName: ""
                )
            } else {
                // Safety fallback
                print("🌐 ❌ there is internet but url of image is nil(empty)")
                imgProfile.image = UIImage(systemName: "person.circle.fill")
            }

        } else {

            print("📁 Offline → load image from local storage")
            
            if let offlineImage = UserProfileImageStorage.loadUserProfileImage() {
                imgProfile.image = offlineImage
            } else {
                print("❌Offline but url from userdefault is nil (empty)")
                imgProfile.image = UIImage(systemName: "person.circle.fill")
            }
        }
    }

    @objc func handleTap() {
        // 4. Ring the phone! (Trigger the action)
        didTapProfileImage?()
    }
}
