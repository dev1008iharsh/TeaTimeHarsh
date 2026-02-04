//
//  ToastManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 02/02/26.
//

import UIKit

// MARK: - Toast Configuration Types
/// Defines the visual and haptic characteristics for different toast scenarios.
enum ToastType {
    case error      // System Red + Error Haptic
    case success    // System Green + Light Haptic
    case warning    // System Yellow + Warning Haptic
    case appTheme   // System Indigo + Light Haptic
    case info       // System Gray + Light Haptic (Default)

    var backgroundColor: UIColor {
        switch self {
        case .error: return .systemRed
        case .success: return .systemGreen
        case .warning: return .systemYellow
        case .appTheme: return .systemIndigo
        case .info: return .systemGray4
        }
    }

    var emoji: String {
        switch self {
        case .error: return " ❌"
        case .success: return " ✅"
        case .warning: return " ⚡️"
        case .appTheme: return " ✨"
        case .info: return " ℹ️"
        }
    }

    /// Triggers specific haptic feedback to improve user tactile experience.
    func triggerHaptic() {
        switch self {
        case .error: HapticHelper.error()
        case .success: HapticHelper.light()
        case .warning: HapticHelper.warning()
        default: HapticHelper.light()
        }
    }
}

// MARK: - Custom UI Components
/// A custom UILabel that supports internal text insets (Padding).
final class PaddingLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)

    override func drawText(in rect: CGRect) {
        // Draw text with specified insets
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        // Calculate size including padding
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}

// MARK: - Toast Manager (Singleton)
/// Thread-safe and Memory-safe manager for showing stacked toast notifications.
final class ToastManager {
    static let shared = ToastManager()
    
    // Private properties for layout management
    private var activeToasts: [UIView] = []
    private let maxToasts = 5
    private let toastSpacing: CGFloat = 16.0
    private let baseBottomPadding: CGFloat = 100.0
    private let sidePadding: CGFloat = 30.0

    private init() {}

    /// Public method to display a toast. Safe to call from any thread.
    func show(message: String, type: ToastType = .error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.handleToastLimit()
            self.createAndShowToast(message: message, type: type)
        }
    }

    /// Removes the oldest toast if the current count exceeds maxToasts (FIFO).
    private func handleToastLimit() {
        if activeToasts.count >= maxToasts {
            if let oldestToast = activeToasts.first {
                removeToast(oldestToast)
            }
        }
    }

    /// Primary logic for building, positioning, and animating the toast.
    private func createAndShowToast(message: String, type: ToastType) {
        // 1. Scene & Window Safety Check (iOS 13+ best practices)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        // 2. Tactile Feedback
        type.triggerHaptic()

        // 3. UI Setup using custom PaddingLabel
        let toastLabel = PaddingLabel()
        let horizontalInset: CGFloat = 20
        let verticalInset: CGFloat = 14
        toastLabel.textInsets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)

        // 4. Content Configuration
        toastLabel.text = message + type.emoji
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 15, weight: .bold)
        
        // --- Multi-line Support ---
        toastLabel.numberOfLines = 0
        toastLabel.lineBreakMode = .byWordWrapping

        // 5. Visual Styling
        toastLabel.layer.backgroundColor = type.backgroundColor.withAlphaComponent(0.95).cgColor
        toastLabel.layer.cornerRadius = 22
        
        // Premium Shadow Logic
        toastLabel.layer.shadowColor = UIColor.black.cgColor
        toastLabel.layer.shadowOffset = CGSize(width: 0, height: 4)
        toastLabel.layer.shadowRadius = 8
        toastLabel.layer.shadowOpacity = 0.15

        // 6. Dynamic Sizing Logic
        let availableWidth = window.frame.width - (sidePadding * 2)
        let constraintRect = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
        let targetSize = toastLabel.sizeThatFits(constraintRect)

        let width = availableWidth
        let height = max(targetSize.height, 50)

        // 7. Stacking Logic - Calculate Y based on existing activeToasts
        let currentStackHeight = activeToasts.reduce(0) { $0 + $1.frame.height + toastSpacing }
        let targetY = window.frame.height - (window.safeAreaInsets.bottom + baseBottomPadding) - height - currentStackHeight

        // 8. Set Initial Position & Appearance
        toastLabel.frame = CGRect(x: sidePadding, y: targetY, width: width, height: height)
        toastLabel.alpha = 0
        toastLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        // 9. Display & Track
        window.addSubview(toastLabel)
        activeToasts.append(toastLabel)

        // 10. Entrance Animation
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: .curveEaseOut) {
            toastLabel.alpha = 1
            toastLabel.transform = .identity
        } completion: { [weak self] _ in
            // 11. Auto-dismissal with memory-safe reference
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self?.removeToast(toastLabel)
            }
        }
    }

    /// Animates out and cleans up the toast from the hierarchy and tracking array.
    private func removeToast(_ toast: UIView) {
        guard let index = activeToasts.firstIndex(of: toast) else { return }
        activeToasts.remove(at: index)

        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 0
            toast.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [weak self] _ in
            toast.removeFromSuperview()
            self?.reStackToasts() // Slide remaining toasts down
        }
    }

    /// Re-calculates and animates the position of all active toasts when one is removed.
    private func reStackToasts() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) {
            var accumulatedHeight: CGFloat = 0
            for toast in self.activeToasts {
                let height = toast.frame.height
                let newY = window.frame.height - (window.safeAreaInsets.bottom + self.baseBottomPadding) - height - accumulatedHeight
                toast.frame.origin.y = newY
                accumulatedHeight += height + self.toastSpacing
            }
        }
    }
}
