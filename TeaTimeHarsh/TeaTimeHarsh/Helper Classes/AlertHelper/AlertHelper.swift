//
//  AlertHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import UIKit

// MARK: - Action Model
struct SheetAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: () -> Void
    
    init(title: String, style: UIAlertAction.Style = .default, handler: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

// MARK: - Universal Alert Helper
class AlertHelper {
    
    // MARK: - Action Sheet Logic
    
    /// Shows Action Sheet with multiple options and a cancel button
    @MainActor
    static func showActionSheet(on vc: UIViewController?, title: String?, message: String?, actions: [SheetAction]) {
        guard let targetVC = vc else { return }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        // Add dynamic actions
        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler()
            })
        }
        
        // Mandatory cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        targetVC.present(alert, animated: true)
    }

    // MARK: - Standard Alert Functions
    
    /// Basic alert with OK button
    @MainActor
    static func showAlert(title: String, message: String, vc: UIViewController?) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        targetVC.present(alert, animated: true)
    }

    /// Alert with completion handler for OK
    @MainActor
    static func showAlertHandler(title: String, message: String, vc: UIViewController?, okAction: @escaping (UIAlertAction) -> Void) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))
        targetVC.present(alert, animated: true)
    }

    /// Shows a mandatory two-button alert.
    /// Useful for Confirmations, Custom Choices, and Network Blocking alerts.
    @discardableResult
    @MainActor
    static func showConfirmationAlert(
        title: String,
        message: String,
        vc: UIViewController?,
        rightBtnTitle: String,
        rightBtnStyle: UIAlertAction.Style = .destructive,
        leftBtnTitle: String,
        leftBtnStyle: UIAlertAction.Style = .cancel,
        rightAction: @escaping (UIAlertAction) -> Void,
        leftAction: @escaping (UIAlertAction) -> Void
    ) -> UIAlertController? {
        
        // ✅ Safety Check
        guard let targetVC = vc else { return nil }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // 1. Left Action (Mandatory)
        let left = UIAlertAction(title: leftBtnTitle, style: leftBtnStyle, handler: leftAction)
        alert.addAction(left)

        // 2. Right Action (Mandatory)
        let right = UIAlertAction(title: rightBtnTitle, style: rightBtnStyle, handler: rightAction)
        alert.addAction(right)

        // 3. Present
        targetVC.present(alert, animated: true)
        
        // 4. Return instance (To manage dismissal manually if needed)
        return alert
    }
}
