//
//  EmailHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import MessageUI
import UIKit

// MARK: - Email Manager (Singleton)

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    // 1. Shared Instance (Singleton)
    static let shared = EmailHelper()

    override private init() {}

    // 2. Main Function to Send Email
    func sendEmail(from viewController: UIViewController, recipients: [String], subject: String, body: String) {
        // Check Capability
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Error", message: "Mail services are not available.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
            return
        }

        // Configure Mail Composer
        let mailComposer = MFMailComposeViewController()

        mailComposer.mailComposeDelegate = self

        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)

        // Present
        viewController.present(mailComposer, animated: true)
    }

    // MARK: - Delegate Method

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Close the mail sheet
        controller.dismiss(animated: true)
    }
}
