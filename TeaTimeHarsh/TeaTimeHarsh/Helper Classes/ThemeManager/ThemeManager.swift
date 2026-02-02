//
//  ThemeManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import UIKit

// 1. Simple Enum for your options
enum AppTheme: Int {
    case system = 0 // Follow iPhone Settings
    case light = 1 // Force Light Mode
    case dark = 2 // Force Dark Mode

    // Helper to get a readable name
    var title: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }
}

class ThemeManager {
    // Singleton - We only need one manager for the whole app
    static let shared = ThemeManager()

    private let key = "selected_theme"

    // 2. Function to Get Current Saved Theme 💾
    func getCurrentTheme() -> AppTheme {
        let rawValue = UserDefaults.standard.integer(forKey: key)
        return AppTheme(rawValue: rawValue) ?? .system
    }

    // 3. Check if we are currently visually in Dark Mode 🌑
    // (Useful if you want to update icons based on mode)
    func isDarkMode(in traitCollection: UITraitCollection) -> Bool {
        return traitCollection.userInterfaceStyle == .dark
    }

    // 4. The Magic Function to Force the Mode ✨
    func apply(theme: AppTheme) {
        // Save to memory
        UserDefaults.standard.set(theme.rawValue, forKey: key)

        // Find the main window to apply the style globally
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        // Apply the style
        switch theme {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified // Follows System
        }
    }

    // Returns true if the app is currently looking Dark (whether forced or system)
    var isDarkModeActive: Bool {
        let theme = getCurrentTheme()

        // 1. If we forced it, return that value
        if theme == .dark { return true }
        if theme == .light { return false }

        // 2. If it's System, check the actual device setting
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}
