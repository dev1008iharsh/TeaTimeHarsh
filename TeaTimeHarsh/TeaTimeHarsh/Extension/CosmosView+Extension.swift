//
//  CosmosView+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 12/01/26.
//

import Cosmos
import UIKit

// MARK: - CosmosView Helper Extension

extension CosmosView {
    /// Applies the common theme style for the app
    func applyTeaThemeStyle(starSize: Double, isEditable: Bool, color: UIColor = .systemOrange) {
        settings.updateOnTouch = isEditable
        settings.fillMode = .full
        settings.emptyBorderWidth = 1.5
        settings.starSize = starSize
        settings.starMargin = 2
        settings.filledColor = color
        settings.emptyBorderColor = color
        settings.filledBorderColor = color
    }
}
