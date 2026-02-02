//
//  EmailMetaData.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import UIKit

// MARK: - Device Info Helper

import UIKit

struct EmailMetaData {
    // ⭐️ Computed Property to generate the full email body text
    static var supportInfo: String {
        // 1. App Details
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"

        // 2. Device Details
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = getDeviceModel() // Calling our helper function
        let appName = UtilsProject.getAppName // Calling our helper function

        // 3. User Settings
        let language = Locale.current.identifier
        let timezone = TimeZone.current.identifier

        // 4. Return Formatted String
        return """

        --------------------------------------
        ⚠️ Debug Info (Do not delete)
        This helps developers find issues.
        --------------------------------------
        📱 Device Info:
        - Model: \(deviceModel)
        - OS: iOS \(osVersion)

        📦 App Info:
        - Name: \(appName)
        - Version: \(appVersion)
        - Build: \(buildNumber)
        - Bundle ID: \(bundleID)

        ⚙️ User Settings:
        - Language: \(language)
        - Timezone: \(timezone)
        --------------------------------------
        """
    }

    // MARK: - Helper Methods

    // Helper to get exact model identifier (e.g., iPhone15,3)
    // This is more accurate than UIDevice.current.name for debugging
    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
