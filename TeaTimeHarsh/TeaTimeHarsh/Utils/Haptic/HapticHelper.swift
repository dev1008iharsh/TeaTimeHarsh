//
//  HapticHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 30/12/25.
//

import UIKit

class HapticHelper {
    // Private init: No one can create an instance of this class
    private init() {}

    // MARK: - Standard Feedback (Static)

    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // ✅ Use for: Payment Done, Save Success, Task Done
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    // ❌ Use for: Wrong Password, No Internet, Validation Fail
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // ⚠️ Use for: Delete Confirmation, Low Battery
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
