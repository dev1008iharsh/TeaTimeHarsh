//
//  ChangeAppIconVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 12/01/26.
//

import UIKit

class ChangeAppIconVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
 
    }
    
    @IBAction func didTapDefaultIcon(_ sender: UIButton) {
        changeAppIcon(to: nil)
    }
    @IBAction func didTapIcon1(_ sender: UIButton) {
        changeAppIcon(to: "icon1")
    }
    @IBAction func didTapIcon2(_ sender: UIButton) {
        changeAppIcon(to: "icon2")
    }
    @IBAction func didTapIcon3(_ sender: UIButton) {
        changeAppIcon(to: "icon3")
    }
    @IBAction func didTapIcon4(_ sender: UIButton) {
        changeAppIcon(to: "icon4")
    }
    
    /// Centralized function to handle icon change safely
        private func changeAppIcon(to iconName: String?) {
            // 1. Check if the app supports alternate icons
            guard UIApplication.shared.supportsAlternateIcons else {
                print("⚠️ This device does not support alternate icons")
                return
            }

            // 2. Check if we are already using this icon to avoid unnecessary reload
            if let currentIcon = UIApplication.shared.alternateIconName, currentIcon == iconName {
                print("ℹ️ Icon is already set to \(iconName ?? "Default")")
                return
            }
            
            // 3. Change the icon
            // Note: iOS will automatically show an alert to the user.
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    print("❌ Error changing icon: \(error.localizedDescription)")
                } else {
                    print("✅ Icon changed successfully to: \(iconName ?? "Default")")
                }
            }
        }

}
