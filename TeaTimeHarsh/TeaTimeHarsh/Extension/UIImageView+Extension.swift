//
//  UIImageView+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/01/26.
//

import UIKit

extension UIImageView {
    
    func applyCircularProfileStyle(
        borderColor: UIColor = .systemIndigo,
        borderWidth: CGFloat = 0.5
    ) {
        // Ensure layout is updated before calculating cornerRadius
        self.layoutIfNeeded()
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }
}
