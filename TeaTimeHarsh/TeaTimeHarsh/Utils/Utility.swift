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
        // ✅ Safety Check: જો vc 'nil' હોય તો અહીંથી જ return થઈ જશે.
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
}
