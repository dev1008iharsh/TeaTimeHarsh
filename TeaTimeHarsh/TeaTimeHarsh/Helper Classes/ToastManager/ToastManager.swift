//
//  ToastManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 02/02/26.
//
import UIKit

class ToastManager {
    static let shared = ToastManager()
    private init() {}

    func show(message: String) {
        DispatchQueue.main.async {
            self.createAndShowToast(message: message)
        }
    }

    private func createAndShowToast(message: String) {
        // 1. Get the Key Window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        // 2. Haptic Feedback - Light tick for tactile feel
        HapticHelper.light()

        // 3. UI Setup (Modern Industry Look)
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 15, weight: .bold)
        toastLabel.numberOfLines = 0

        // --- IMPORTANT: Use layer background color for shadow + corner compatibility ---
        toastLabel.layer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.95).cgColor
        toastLabel.layer.cornerRadius = 22

        toastLabel.layer.masksToBounds = false
        toastLabel.clipsToBounds = false

        // 2. Premium Shadow logic
        toastLabel.layer.shadowColor = UIColor.black.cgColor
        toastLabel.layer.shadowOffset = CGSize(width: 0, height: 8)
        toastLabel.layer.shadowRadius = 12
        toastLabel.layer.shadowOpacity = 0.25
        // 4. Dynamic Sizing
        let maxSize = CGSize(width: window.frame.width - 60, height: window.frame.height)
        let expectedSize = toastLabel.sizeThatFits(maxSize)
        let width = min(expectedSize.width + 44, window.frame.width - 40)
        let height = max(expectedSize.height + 24, 48)

        // 5. Precise Position: Bottom Safe Area + 120 Points
        let safeAreaBottom = window.safeAreaInsets.bottom
        let targetY = window.frame.height - (safeAreaBottom + 120) - height

        toastLabel.frame = CGRect(
            x: (window.frame.width - width) / 2,
            y: targetY,
            width: width,
            height: height
        )

        window.addSubview(toastLabel)

        // 6. 3D Animation: Start Small (Inside the screen)
        toastLabel.alpha = 0
        toastLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)

        // Pop Animation (Jump towards user)
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            toastLabel.alpha = 1
            toastLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) // Scale to normal

        } completion: { _ in

            // Go back inside and Fade out
            UIView.animate(withDuration: 0.4, delay: 2.0, options: .curveEaseIn) {
                toastLabel.alpha = 0
                toastLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            } completion: { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
