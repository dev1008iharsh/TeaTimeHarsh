//
//  ContactHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import Contacts
import ContactsUI
import UIKit

class ContactHelper: NSObject, CNContactViewControllerDelegate {
    static let shared = ContactHelper()
    override private init() {}

    static func isValidPhone(phone: String) -> Bool {
        let phoneRegex = "^[0-9+]{10,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phone)
    }

    static func showContactMenu(on vc: UIViewController, phoneNumber: String, name: String) {
        guard isValidPhone(phone: phoneNumber) else {
            AlertHelper.showAlertHandler(title: "Invalid Number", message: "This phone number is not valid.", vc: vc) { _ in }
            return
        }

        let actions = [
            // 1. Call
            SheetAction(title: "Call \(phoneNumber)") {
                if let url = URL(string: "tel://\(phoneNumber)") { UIApplication.shared.open(url) }
            },
            // 2. WhatsApp Message with Predefined Message
            SheetAction(title: "WhatsApp Message") {
                let cleanNumber = phoneNumber.replacingOccurrences(of: "+", with: "")
                let message = "Greetings! I'm reaching out via the \(UtilsProject.getAppName). 🍵"

                // URL Encoding for emojis and spaces
                let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                // WhatsApp Format: https://wa.me/number?text=message
                let waURL = "https://wa.me/\(cleanNumber)?text=\(encodedMessage)"

                if let url = URL(string: waURL) {
                    UIApplication.shared.open(url)
                }
            },
            // 3. Standard SMS with Predefined Message
            SheetAction(title: "Send Message (SMS)") {
                let message = "Greetings! I'm reaching out via the \(UtilsProject.getAppName). 🍵"
                // URL Encoding is mandatory for spaces and emojis
                let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                // Format: sms:1234567890&body=Hello
                let smsURL = "sms:\(phoneNumber)&body=\(encodedMessage)"

                if let url = URL(string: smsURL) {
                    UIApplication.shared.open(url)
                }
            },
            // 4. FaceTime
            SheetAction(title: "FaceTime") {
                if let url = URL(string: "facetime://\(phoneNumber)") { UIApplication.shared.open(url) }
            },
            // 5. Save Contact
            SheetAction(title: "Save to Contacts") {
                shared.openCreateContact(on: vc, phoneNumber: phoneNumber, name: name + " " + UtilsProject.getAppName)
            },
            // 6. Copy
            SheetAction(title: "Copy Number") {
                UIPasteboard.general.string = phoneNumber
                HapticHelper.success()
            },
        ]

        AlertHelper.showActionSheet(on: vc, title: "Connect with \(name)", message: nil, actions: actions)
    }

    private func openCreateContact(on vc: UIViewController, phoneNumber: String, name: String) {
        let contact = CNMutableContact()
        contact.givenName = name
        let phoneValue = CNPhoneNumber(stringValue: phoneNumber)
        contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: phoneValue)]

        let contactVC = CNContactViewController(forNewContact: contact)
        contactVC.delegate = self
        let navVC = UINavigationController(rootViewController: contactVC)
        vc.present(navVC, animated: true)
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }
}
