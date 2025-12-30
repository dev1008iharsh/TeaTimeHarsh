//
//  UITextField+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import UIKit

extension UITextField {

    func applySingleSelectionMenu(
        title: String,
        items: [String],
        selectedItem: String?,
        onSelect: @escaping (String) -> Void
    ) {

        // Disable keyboard
        inputView = UIView()

        // Create transparent button overlay
        let overlayButton = UIButton(type: .custom)
        overlayButton.backgroundColor = .clear
        overlayButton.frame = bounds
        overlayButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        overlayButton.menu = SingleSelectionMenuBuilder.makeMenu(
            title: title,
            items: items,
            selectedItem: selectedItem
        ) { selected in
            self.text = selected
            onSelect(selected)
        }

        overlayButton.showsMenuAsPrimaryAction = true

        addSubview(overlayButton)
    }
}
