//
//  UITextField+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import UIKit

extension UITextField {
    func applyDefaultStyle() {
        // 1. Layer Styling
        layer.borderColor = UIColor.systemGray5.cgColor
        layer.cornerRadius = 10.0
        layer.borderWidth = 1.0
        backgroundColor = .systemBackground

        // 2. Padding (Left)
        // We use 'self.frame.height' to match the text field's height
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: frame.height))
        leftView = leftPaddingView
        leftViewMode = .always

        // 3. Padding (Right)
        // We must create a NEW view for the right side (cannot reuse the left one)
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: frame.height))
        rightView = rightPaddingView
        rightViewMode = .always
    }

    func applySingleSelectionMenu(title: String, items: [String], selectedItem: String?,
                                  onSelect: @escaping (String) -> Void) {
        // Disable keyboard
        inputView = UIView()

        // Create transparent button overlay
        let overlayButton = UIButton(type: .custom)
        overlayButton.backgroundColor = .clear
        overlayButton.frame = bounds
        overlayButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        overlayButton.menu = SingleSelectionMenuBuilder.makeMenu(title: title, items: items, selectedItem: selectedItem) { selected in
            self.text = selected
            onSelect(selected)
        }

        overlayButton.showsMenuAsPrimaryAction = true

        addSubview(overlayButton)
    }
}
