//
//  UIBUtton+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 28/12/25.
//

import UIKit

extension UIButton {

    func applySingleSelectionMenu(
        title: String,
        items: [String],
        selectedItem: String?,
        onSelect: @escaping (String) -> Void
    ) {

        self.menu = SingleSelectionMenuBuilder.makeMenu(
            title: title,
            items: items,
            selectedItem: selectedItem
        ) { selected in
            self.setTitle(selected, for: .normal)
            onSelect(selected)
        }

        self.showsMenuAsPrimaryAction = true
    }
    
    func animateAndConfigure(
        title: String,
        systemImageName: String,
        backgroundColor: UIColor
    ) {
        // Step 1: Zoom up
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in

            // Step 2: Change state
            UIView.transition(
                with: self,
                duration: 0.18,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                var config = UIButton.Configuration.plain()
                config.title = title
                config.image = UIImage(systemName: systemImageName)
                config.imagePlacement = .leading
                config.imagePadding = 5
                config.baseForegroundColor = .white

                self.configuration = config
                self.backgroundColor = backgroundColor
            }

            // Step 3: Zoom back
            UIView.animate(
                withDuration: 0.15,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                self.transform = .identity
            }
        }
    }
}
