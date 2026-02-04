//
//  UIImageView+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/01/26.
//

import UIKit

extension UIImageView {
    func applyCircularProfileStyle(borderColor: UIColor = .systemIndigo, borderWidth: CGFloat = 0.5) {
        // Ensure layout is updated before calculating cornerRadius
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = frame.height / 2
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
}
