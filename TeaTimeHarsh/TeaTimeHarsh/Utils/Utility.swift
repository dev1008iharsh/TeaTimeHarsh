//
//  Utility.swift
//  ApiHarsh
 
 
import UIKit
 


import UIKit

class Utility {
    /*
    func getHeaderAlmo()-> HTTPHeaders {
        return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
    }
    func getHeader()-> [String : String]? {
        return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
    }*/
    
    
    // Singleton instance to access it like Utility.shared.showAlert(...)
    static let shared = Utility()
    
    private init() {} // Prevents others from creating a new instance
    
    // MARK: - Alert Functions
    
    /// Shows a simple alert with an OK button.
    /// 🟢 @MainActor ensures this runs on the main UI thread (iOS 18 Requirement).
    @MainActor
    public func showAlert(title: String, message: String, view: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        view.present(alert, animated: true, completion: nil)
    }
    
    /// Shows an alert with a completion handler for the OK button.
    @MainActor
    public func showAlertHandler(title: String, message: String, view: UIViewController, okAction: @escaping ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))
        view.present(alert, animated: true, completion: nil)
    }
    
    /// Shows a Yes/No confirmation alert.
    @MainActor
    public func showYesNoConfirmAlert(title: String, message: String, view: UIViewController, YesAction: @escaping ((UIAlertAction) -> Void), NoAction: @escaping ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // Cancel usually goes on the left/bottom
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: NoAction))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: YesAction))
        view.present(alert, animated: true, completion: nil)
    }
    
    /// Shows a custom confirmation alert with custom button titles.
    @MainActor
    public func showCustomConfirmAlert(title: String, message: String, rightSideActionName: String, leftSideActionName: String, viewController: UIViewController, rightAction: @escaping (UIAlertAction) -> Void, leftAction: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add Left Action
        alert.addAction(UIAlertAction(title: leftSideActionName, style: .default, handler: leftAction))
        
        // Add Right Action
        alert.addAction(UIAlertAction(title: rightSideActionName, style: .default, handler: rightAction))
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
