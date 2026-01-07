//
//  ImageZoomViewer.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import UIKit

import UIKit

class ImageZoomViewer {
    
    static let shared = ImageZoomViewer()
    
    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0
    private var zoomImageView: UIImageView?
    private var backgroundView: UIView? // Renamed from blackBackground
    
    // 🚀 NEW: Added 'backgroundColor' parameter
    // Default is .black, so if you don't send a color, it uses black automatically.
    func showFullScreen(from sourceImageView: UIImageView, backgroundColor: UIColor = .black) {
        
        guard let window = getWindow(), let image = sourceImageView.image else { return }
        
        // 1. Save Position
        originalFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil) ?? .zero
        originalCornerRadius = sourceImageView.layer.cornerRadius
        
        // 2. Create Background (With your custom color!) 🎨
        backgroundView = UIView(frame: window.bounds)
        backgroundView?.backgroundColor = backgroundColor // 👈 SETTING THE COLOR HERE
        backgroundView?.alpha = 0
        window.addSubview(backgroundView!)
        
        // 3. Setup Image
        zoomImageView = UIImageView(frame: originalFrame)
        zoomImageView?.image = image
        zoomImageView?.tintColor = .systemIndigo
        zoomImageView?.contentMode = .scaleAspectFill
        zoomImageView?.clipsToBounds = true
        zoomImageView?.layer.cornerRadius = originalCornerRadius
        zoomImageView?.isUserInteractionEnabled = true
        window.addSubview(zoomImageView!)
        
        // 4. Gestures to Close
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        backgroundView?.addGestureRecognizer(tap)
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        zoomImageView?.addGestureRecognizer(imageTap)
        
        // 5. Animate Open
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            
            self.zoomImageView?.frame = CGRect(x: 0,
                                               y: (window.frame.height - window.frame.width) / 2,
                                               width: window.frame.width,
                                               height: window.frame.width)
            
            self.zoomImageView?.layer.cornerRadius = 0
            self.backgroundView?.alpha = 1 // Fade in
            
        }
    }
    
    @objc private func dismissFullScreen() {
        // 6. Animate Close
        UIView.animate(withDuration: 0.4, animations: {
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.backgroundView?.alpha = 0
        }) { _ in
            self.zoomImageView?.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
        }
    }
    
    private func getWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
    }
}
