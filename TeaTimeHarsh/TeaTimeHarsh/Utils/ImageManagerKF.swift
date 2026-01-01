//
//  ImageManagerKF.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//

import UIKit
import Kingfisher // 📦 Ensure Kingfisher is added via SPM

// File Name: ImageManagerKF.swift

/// A specialized Manager to handle Image Downloading & Caching using Kingfisher.
/// This acts as a 'Facade' so the rest of the app doesn't need to know about Kingfisher directly.
final class ImageManagerKF {
    
    // MARK: - Static Helper Method
    // 'static' means you don't need to create an instance (let img = ImageManagerKF())
    // You can just call ImageManagerKF.setImage(...) directly.
    
    /// Downloads an image from a URL and sets it to the provided UIImageView.
    /// - Parameters:
    ///   - urlString: The string URL of the image.
    ///   - imageView: The UIImageView to display the image.
    ///   - placeholderName: System symbol name to show while loading (default: "photo").
    static func setImage(from urlString: String?, into imageView: UIImageView, placeholderName: String = "photo") {
        
        // 1. Validate URL
        guard let urlString = urlString, let url = URL(string: urlString) else {
            // If URL is invalid/nil, show placeholder
            imageView.image = UIImage(systemName: placeholderName)
            return
        }
        
        // 2. Define Placeholder
        let placeholder = UIImage(systemName: placeholderName)
        
        // 3. Set Options (Animation, Caching, etc.)
        let options: KingfisherOptionsInfo = [
            .transition(.fade(0.3)),       // Smooth fade-in effect
            .cacheOriginalImage,           // Cache the raw image
            .scaleFactor(UIScreen.main.scale) // Handle retina displays
        ]
        
        // 4. Load Image using Kingfisher
        imageView.kf.indicatorType = .activity // Show spinner while loading
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: options
        ) { result in
            switch result {
            case .success(let value):
                // Optional: Log success for debugging
                print("✅ Kingfisher: Image loaded from \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("❌ Kingfisher Error: \(error.localizedDescription)")
            }
        }
    }
}
