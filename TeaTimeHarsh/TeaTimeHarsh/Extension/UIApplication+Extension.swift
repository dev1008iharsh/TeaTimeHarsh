//
//  UIApplication+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 03/01/26.
//
import UIKit
import Foundation
extension UIApplication {
    
    func getTopViewController(base: UIViewController? = UIApplication.shared.connectedScenes
                                .filter({$0.activationState == .foregroundActive})
                                .compactMap({$0 as? UIWindowScene})
                                .first?.windows
                                .filter({$0.isKeyWindow}).first?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
