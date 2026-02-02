//
//  PaddedLabel.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//

import UIKit

@IBDesignable
class PaddedLabel: UILabel {
    // MARK: - 1. Unified Padding Property

    /// This property adds padding to BOTH the left (leading) and right (trailing) sides.
    @IBInspectable var padding: CGFloat = 0 {
        didSet {
            // When we change padding, we need to tell the view to redraw and update its layout size
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - 2. Border Width

    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    // MARK: - 3. Border Color

    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }

    // MARK: - Internal Setup

    // This is the magic method 🪄. It tells the label to draw the text
    // strictly inside a specific rectangle (inset by our padding).
    override func drawText(in rect: CGRect) {
        // Create insets: Top: 0, Left: padding, Bottom: 0, Right: padding
        let insets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)

        // Shrink the drawing rectangle by these insets
        super.drawText(in: rect.inset(by: insets))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 📏 Calculate half of the height automatically
        layer.cornerRadius = bounds.height / 2

        // ✂️ This makes sure the content/background is actually clipped to the rounded corners
        layer.masksToBounds = true
    }

    // This ensures Auto Layout knows the label is now wider because of the padding
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + (padding * 2), height: size.height)
    }
}
