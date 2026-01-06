//
//  Utility.swift
//  ApiHarsh

/*
 func getHeaderAlmo()-> HTTPHeaders {
     return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
 }
 func getHeader()-> [String : String]? {
     return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
 }*/

import UIKit

final class Utility {
    // 🔒 Private Init: Object class of this class can not be created.
    private init() {}

    // MARK: - Alert Functions

    /// Shows a simple alert with an OK button.
    /// Call like: Utility.showAlert(title: "...", message: "...", vc: self)
    @MainActor
    static func showAlert(title: String, message: String, viewController: UIViewController?) {
        // ✅ Safety Check: vc 'nil' -> return 
        guard let targetVC = viewController else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        targetVC.present(alert, animated: true, completion: nil)
    }

    /// Shows an alert with a completion handler for the OK button.
    @MainActor
    static func showAlertHandler(title: String, message: String, viewController: UIViewController?, okAction: @escaping ((UIAlertAction) -> Void)) {
        guard let targetVC = viewController else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))
        targetVC.present(alert, animated: true, completion: nil)
    }

    /// Shows a Yes/No confirmation alert.
    @MainActor
    static func showYesNoConfirmAlert(title: String, message: String, viewController: UIViewController?, yesAction: @escaping ((UIAlertAction) -> Void), noAction: @escaping ((UIAlertAction) -> Void)) {
        guard let targetVC = viewController else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // Cancel implies 'No' usually
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: noAction))
        // Destructive implies dangerous action like Delete
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: yesAction))

        targetVC.present(alert, animated: true, completion: nil)
    }

    /// Shows a custom confirmation alert with custom button titles.
    @MainActor
    static func showCustomConfirmAlert(title: String, message: String, rightSideActionName: String, leftSideActionName: String, viewController: UIViewController?, rightAction: @escaping (UIAlertAction) -> Void, leftAction: @escaping (UIAlertAction) -> Void) {
        guard let targetVC = viewController else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Left Action
        alert.addAction(UIAlertAction(title: leftSideActionName, style: .default, handler: leftAction))

        // Right Action
        alert.addAction(UIAlertAction(title: rightSideActionName, style: .default, handler: rightAction))

        targetVC.present(alert, animated: true, completion: nil)
    }

    // 🗓️ Static function to calculate the duration
    static func getServingDuration(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        // 1. Ask the calendar to calculate the Years, Months, and Days between the saved date and Now.
        let components = calendar.dateComponents([.year, .month, .day], from: date, to: now)

        // 2. We will store the parts of the string here (e.g., ["1 Year", "2 Months"])
        var resultParts: [String] = []

        // --- YEAR LOGIC ---
        // If years are greater than 0, add it. If 0, we skip it (emit it).
        if let year = components.year, year > 0 {
            let yearString = year == 1 ? "Year" : "Years" // Handle plural
            resultParts.append("\(year) \(yearString)")
        }

        // --- MONTH LOGIC ---
        // If months are greater than 0, add it.
        if let month = components.month, month > 0 {
            let monthString = month == 1 ? "Month" : "Months"
            resultParts.append("\(month) \(monthString)")
        }

        // --- DAY LOGIC (Special Case) ---
        // We look at the calculated days.
        let calculatedDays = components.day ?? 0

        // YOUR RULE: If it is 0 days (meaning today), force it to 1.
        let finalDays = calculatedDays == 0 ? 1 : calculatedDays

        let dayString = finalDays == 1 ? "Day" : "Days"
        resultParts.append("\(finalDays) \(dayString)")

        // 3. Join all parts with space
        return resultParts.joined(separator: " ")
    }

    static func isPasswordValid(_ password: String) -> Bool {
        // Regex Explanation:
        // ^                 = Start
        // (?=.*[a-z])       = Must contain at least 1 lowercase
        // (?=.*[A-Z])       = Must contain at least 1 uppercase
        // (?=.*[^A-Za-z0-9])= Must contain at least 1 special character (anything that is NOT a letter or number)
        // .{6,}             = Must be at least 6 characters long

        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{6,}$"

        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }

    /// Checks if the email format is valid (e.g., name@domain.com)
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @discardableResult
        static func presentNetworkBlockingAlert(title: String, message: String, rightSideActionName: String, leftSideActionName: String, viewController: UIViewController?, rightAction: @escaping (UIAlertAction) -> Void, leftAction: @escaping (UIAlertAction) -> Void) -> UIAlertController? {
            
            guard let targetVC = viewController else { return nil }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            // Left Action
            alert.addAction(UIAlertAction(title: leftSideActionName, style: .default, handler: leftAction))

            // Right Action
            alert.addAction(UIAlertAction(title: rightSideActionName, style: .default, handler: rightAction))

            targetVC.present(alert, animated: true, completion: nil)
            
            return alert // Returning instance to manage dismissal
        }
}
