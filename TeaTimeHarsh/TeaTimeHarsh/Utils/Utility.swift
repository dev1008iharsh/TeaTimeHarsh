//
//  Utility.swift
//  ApiHarsh
 
 
import UIKit
 

class Utility {
    static let shared = Utility()
    private init() {}
 
    /*
    func getHeaderAlmo()-> HTTPHeaders {
        return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
    }
    func getHeader()-> [String : String]? {
        return [ "Authorization": "Bearer \(Constant.accessToken)","Content-Type": "application/json"]
    }*/
    
    public func showAlert(title:String, message: String, view:UIViewController) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        view.present(alert, animated: true, completion: nil)
    }
    
    public func showAlertHandler(title:String, message: String, view:UIViewController,okAction:@escaping ((UIAlertAction) -> Void)) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: okAction))
        view.present(alert, animated: true, completion: nil)
    }
    
    public func showYesNoConfirmAlert(title:String, message: String, view:UIViewController,YesAction:@escaping ((UIAlertAction) -> Void),NoAction:@escaping ((UIAlertAction) -> Void)) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: NoAction))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: YesAction)) 
        view.present(alert, animated: true, completion: nil)
    }
    
    public func showCustomConfirmAlert(title: String, message: String, rightSideActionName: String, leftSideActionName: String, viewController: UIViewController, rightAction: @escaping (UIAlertAction) -> Void, leftAction: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
       
        alert.addAction(UIAlertAction(title: leftSideActionName, style: .default, handler: leftAction))
        
        alert.addAction(UIAlertAction(title: rightSideActionName, style: .default, handler: rightAction))
       
        
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
