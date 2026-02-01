//
//  ProfileHeaderCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import Kingfisher
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
            print("❌ Profile not completed(Updated) → default system image")
            imgProfile.image = UIImage(systemName: "person.circle.fill")
            return
        }

        // 2️⃣ Profile completed → check internet
        if AppNetworkManager.shared.isConnected {
            print("🌐 Online → load image from URL")

            if let profileUrl = user.profileImageUrl, !profileUrl.isEmpty {
                imgProfile.kf.setImage(with: URL(string: profileUrl), placeholder: UIImage(systemName: "person.circle.fill"), options: nil, completionHandler: { result in
                    switch result {
                    case .success(let value):
                        // 1️⃣ Extract image and 2️⃣ Validate if it's not empty
                        let downloadedImage = value.image
                        
                        // Checking if image has valid CGImage or CIImage data
                        if downloadedImage.size.width > 0 && downloadedImage.size.height > 0 {
                            // Valid image found, now safe to save
                            UserProfileImageStorage.saveUserProfileImage(downloadedImage)
                        } else {
                            print("🌐❌ Online but Downloaded image is empty or invalid size.")
                        }

                    case .failure(let error):
                        print("🌐❌ Online but Kingfisher Error: \(error.localizedDescription)")
                    }
                })
                
            } else {
                print("🌐❌ Online but url from api server is nil (empty)")
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
