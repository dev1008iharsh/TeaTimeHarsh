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
        setupTappableLabels()
    }

    private func setupTappableLabels() {
        lblEmail.isUserInteractionEnabled = true
        lblContactNumber.isUserInteractionEnabled = true

        let emailTap = UITapGestureRecognizer(target: self, action: #selector(didTapEmailLabel))
        lblEmail.addGestureRecognizer(emailTap)

        let contactTap = UITapGestureRecognizer(target: self, action: #selector(didTapContactLabel))
        lblContactNumber.addGestureRecognizer(contactTap)
    }

    @objc private func didTapEmailLabel() {
        HapticHelper.success()
        if let ownerEmail = placeOwnerUser?.email {
            EmailHelper.shared.sendEmail(
                from: self,
                recipients: [ownerEmail, AppConstants.Strings.developerEmail],
                subject: "Support Request from \(UtilsProject.getAppName) - Owner Profile Screen",
                body: createdBodyForMail()
            )
        }
    }

    func createdBodyForMail() -> String {
        guard let user = UserDataManager.shared.user else { return "" }
        guard let ownerUser = placeOwnerUser else { return "" }
        let ownerName = ownerUser.fullName ?? "owner"
        let ownerEmail = ownerUser.email
        let ownerUserID = ownerUser.id ?? "owner id"
        let ownerUserProviderID = ownerUser.providerID ?? "owner provider id"

        let currentEmail = user.email
        let currentUserID = user.id ?? "user id"
        let currentUserProviderID = user.providerID ?? "user provider id"

        return "I want to connect to \(ownerName) due to this reasons...\n"
            + "Write your message here...\n\n\n\n\n\n\n\n\n"
            + "Owner details: \(ownerEmail) \n \(ownerUserID) \n \(ownerUserProviderID) \n\n"
            + "User details: \(currentEmail) \n \(currentUserID) \n \(currentUserProviderID) \n\n"
            + EmailMetaData.supportInfo
    }

    @objc private func didTapContactLabel() {
        HapticHelper.light()
        guard let ownerUser = placeOwnerUser else { return }
        if let phoneNumber = ownerUser.phoneNumber, let ownerName = ownerUser.fullName {
            ContactHelper.showContactMenu(on: self, phoneNumber: "91\(phoneNumber)", name: ownerName)
        } else {
            AlertHelper
                .showAlert(
                    title: "Error. Something went wrong.",
                    message: "Could not get name and phone number of owner.Try again after some time.",
                    vc: self
                )
        }
    }

    private func setUpOwnerDetails() {
        guard let ownerUser = placeOwnerUser else { return }
        
        //  Calling the internal helper function
        updateLabel(lblFullName, prefix: "(Tappable) Place Owner's Name", value: ownerUser.fullName)
        updateLabel(lblUserName, prefix: "Place Owner's Username", value: ownerUser.username)
        updateLabel(lblEmail, prefix: "Place Owner's Email", value: ownerUser.email)
        updateLabel(lblBio, prefix: "Place Owner's Bio", value: ownerUser.bio)
        updateLabel(lblBirthDate, prefix: "Place Owner's Birthdate", value: ownerUser.birthDateString)
        updateLabel(lblContactNumber, prefix: "(Tappable) Place Owner's Contact Number", value: ownerUser.phoneNumber)
        
        let imgValue = ownerUser.profileImageUrl
        if let value = imgValue, !value.isEmpty {
            ImageManagerKF.setImage(
                from: ownerUser.profileImageUrl,
                into: imgOwner
            )
            imgOwner.isHidden = false
        }else{
            imgOwner.isHidden = true
        }
        
    }

    private func setupImageCofiguration() {
        imgOwner.applyCircularProfileStyle()
        imgOwner.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        imgOwner.addGestureRecognizer(tap)
    }

    @objc private func didTapProfileImage() {
        HapticHelper.light()

        ImageZoomViewer.shared
            .showFullScreen(
                from: imgOwner ?? UIImageView(),
                backgroundColor: .white
            )
    }
    // MARK: - Helper Function
    /// This function updates the label text and hides it if the value is nil or empty.
    private func updateLabel(_ label: UILabel, prefix: String, value: String?) {
        if let value = value, !value.isEmpty {
            label.text = "\(prefix) : \(value)"
            label.isHidden = false
        } else {
            label.text = nil
            label.isHidden = true
        }
    }
}
