//
//  UIViewController+Ext.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

import UIKit

extension UIViewController {
    func hideBackButton(hidden: Bool, swipeEnabled: Bool) {
        // 1. Control the Visual Button (The Arrow)
        // animated: false is best for viewDidLoad to prevent "flickering"
        navigationItem.setHidesBackButton(hidden, animated: false)

        // 2. Control the Gesture (The Swipe)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = swipeEnabled
    }

    /// Replaces the default iOS Back Button with your Custom Image and Text
    /// Replaces the default iOS Back Button with your Custom Image and Text (Fixed Aspect Ratio)
    func setCustomBackButton(image: UIImage, text: String, color: UIColor) {
        // 1. Create the Button
        let backButton = UIButton(type: .system)

        // 2. Configure the Image
        backButton.setImage(image, for: .normal)

        // 🛠️ THE FIX: This tells the image to keep its original shape (1:1)
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

    func removeBackButtonText() {
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

    /// Adds padding to the Left side of the Large Title
    func setLargeTitleSpacing(_ spacing: CGFloat = 16) {
        // 1. Get the current navigation controller (guard check to be safe)
        guard let navController = navigationController else {
            print("⚠️ Warning: No Navigation Controller found!")
            return
        }

        // 2. Create the appearance settings
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        // 3. Create the indentation style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = spacing // 📏 Uses the number you pass in

        // 4. Apply the style
        appearance.largeTitleTextAttributes = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label, // ⚫️ Standard text color
        ]

        // 5. Update the Navigation Bar
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
    }

    /// Sets the Font and Color for Navigation Titles.
    /// Sizes are automatically set to iOS Standards (Large: 34, Small: 17).
    func setNavigationTitleStyle(font: UIFont, color: UIColor) {
        // 1. Safety Check
        guard let navController = navigationController else { return }

        // 2. Define Standard Sizes (The "Defaults" you asked for)
        let defaultLargeSize: CGFloat = 34.0
        let defaultSmallSize: CGFloat = 17.0

        // 3. Get current appearance (Copy to keep your previous Spacing settings! 🛡️)
        let appearance = navController.navigationBar.standardAppearance.copy()

        // --- LARGE TITLE CONFIG ---
        let largeFont = font.withSize(defaultLargeSize) // Force size 34
        var largeAttributes = appearance.largeTitleTextAttributes
        largeAttributes[.font] = largeFont
        largeAttributes[.foregroundColor] = color
        appearance.largeTitleTextAttributes = largeAttributes

        // --- SMALL TITLE CONFIG ---
        let smallFont = font.withSize(defaultSmallSize) // Force size 17
        var smallAttributes = appearance.titleTextAttributes
        smallAttributes[.font] = smallFont
        smallAttributes[.foregroundColor] = color
        appearance.titleTextAttributes = smallAttributes

        // 4. Update Navigation Bar
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.compactAppearance = appearance
    }
}
