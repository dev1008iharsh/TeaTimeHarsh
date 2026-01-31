//
//  UIViewController+Ext.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import SafariServices
import UIKit

extension UIViewController {
    func hideBackButtonNavBar(hidden: Bool, swipeEnabled: Bool) {
        // 1. Control the Visual Button (The Arrow)
        // animated: false is best for viewDidLoad to prevent "flickering"
        navigationItem.setHidesBackButton(hidden, animated: false)

        // 2. Control the Gesture (The Swipe)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = swipeEnabled
    }

    /// Replaces the default iOS Back Button with your Custom Image and Text
    /// Replaces the default iOS Back Button with your Custom Image and Text (Fixed Aspect Ratio)
    func setCustomBackButtonNavBar(image: UIImage, text: String, color: UIColor) {
        // 1. Create the Button
        let backButton = UIButton(type: .system)

        // 2. Configure the Image
        backButton.setImage(image, for: .normal)

        // 🛠️  This tells the image to keep its original shape (1:1)
        // and NOT stretch to fill the rectangle.
        backButton.imageView?.contentMode = .scaleAspectFit

        // 3. Configure the Text
        backButton.setTitle(" " + text, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)

        // 4. Set the Color
        backButton.tintColor = color

        // 5. Add Constraints (Optional but Professional) 📐
        // This ensures the image doesn't get squashed if the text is huge
        backButton.imageView?.translatesAutoresizingMaskIntoConstraints = false
        if let imageView = backButton.imageView {
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: backButton.topAnchor, constant: 5),
                imageView.heightAnchor.constraint(equalToConstant: 35), // Standard Icon Height
                imageView.widthAnchor.constraint(equalToConstant: 35), // Standard Icon Width (1:1)
            ])
        }

        // 6. Add Action
        backButton.addTarget(self, action: #selector(customBackAction), for: .touchUpInside)

        // 7. Assign to Navigation Bar
        let barButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = barButtonItem

        // 8. Fix Gesture
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    /// The action called when your custom back button is tapped
    @objc func customBackAction() {
        navigationController?.popViewController(animated: true)
    }

    func removeBackButtonTextNavBar() {
        // 1. Safety check: Do we have a navigation controller?
        guard let navigationController = navigationController else { return }

        // 2. Get the list of all screens currently in the stack
        let stack = navigationController.viewControllers

        // 3. We need at least 2 screens to have a "back" button (Current + Previous)
        if stack.count >= 2 {
            // 4. Find the Previous Screen (it's the one just before the last one)
            let previousController = stack[stack.count - 2]

            // 5. 🪄 THE MAGIC: Set display mode to .minimal
            // .minimal means "Show the arrow, but hide the title"
            previousController.navigationItem.backButtonDisplayMode = .minimal
        }
    }

    /// Sets navigation title and bar button item color only
    /// Sets navigation title font, size, and color without resetting appearance
    func setCustomNavigationBarStyle(
        font: UIFont = .systemFont(ofSize: 20, weight: .bold),
        color: UIColor = .systemIndigo
    ) {
        guard let navController = navigationController else { return }

        let navBar = navController.navigationBar

        // Large title attributes
        navBar.standardAppearance.largeTitleTextAttributes[.font] = font.withSize(35)
        navBar.standardAppearance.largeTitleTextAttributes[.foregroundColor] = color

        // Small title attributes
        navBar.standardAppearance.titleTextAttributes[.font] = font.withSize(20)
        navBar.standardAppearance.titleTextAttributes[.foregroundColor] = color

        // Bar button items color
        navBar.tintColor = color
    }

    /*

     /// Adds left spacing for Large Title safely (iOS 26 compatible)
     func setLargeTitleSpacingNavBar(_ spacing: CGFloat = 16) {
         guard let navBar = navigationController?.navigationBar else { return }

         // Use layout margins instead of text indentation (Apple-safe)
         navBar.directionalLayoutMargins = NSDirectionalEdgeInsets(
             top: 0,
             leading: spacing,
             bottom: 0,
             trailing: 0
         )
     }

     /// Sets font and color for Large and Small navigation titles
     func setNavigationTitleStyleNavBar(font: UIFont, color: UIColor) {
         guard let navController = navigationController else { return }

         let appearance = UINavigationBarAppearance()
         appearance.configureWithOpaqueBackground()
         appearance.shadowColor = .clear

         // Large title styling
         appearance.largeTitleTextAttributes = [
             .font: font.withSize(34),
             .foregroundColor: color
         ]

         // Small title styling
         appearance.titleTextAttributes = [
             .font: font.withSize(17),
             .foregroundColor: color
         ]

         // Apply appearance
         navController.navigationBar.standardAppearance = appearance
         navController.navigationBar.scrollEdgeAppearance = appearance
         navController.navigationBar.compactAppearance = appearance
     }*/

    /// 🌍 Opens a URL in the internal Safari Browser
    func openSafari(url urlString: String) {
        // 1. Validate the URL
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }

        // 2. Create the Safari View Controller
        let safariVC = SFSafariViewController(url: url)

        // 3. Customize it (Make it look like YOUR app)
        safariVC.preferredControlTintColor = .systemIndigo // Your Theme Color 💜
        safariVC.modalPresentationStyle = .pageSheet

        // 4. Present it
        // 'self' here refers to whichever screen calls this function
        present(safariVC, animated: true, completion: nil)
    }
}
