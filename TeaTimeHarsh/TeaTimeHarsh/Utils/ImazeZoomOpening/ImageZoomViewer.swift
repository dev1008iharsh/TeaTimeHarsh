//
//  ImageZoomViewer.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit

// 1. Inherit from NSObject and UIScrollViewDelegate to handle Zoom events
class ImageZoomViewer: NSObject, UIScrollViewDelegate {
    static let shared = ImageZoomViewer()

    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0
    private var zoomImageView: UIImageView?
    private var backgroundView: UIView?
    private var scrollView: UIScrollView? // 🆕 Added ScrollView for Zooming support

    // Default is .black
    func showFullScreen(from sourceImageView: UIImageView, backgroundColor: UIColor = .black) {
        guard let window = getWindow(), let image = sourceImageView.image else { return }

        // 1. Save Position
        originalFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil) ?? .zero
        originalCornerRadius = sourceImageView.layer.cornerRadius

        // 2. Create Background
        backgroundView = UIView(frame: window.bounds)
        backgroundView?.backgroundColor = backgroundColor
        backgroundView?.alpha = 0
        window.addSubview(backgroundView!)

        // 3. Setup ScrollView (For Zooming) 🔍
        scrollView = UIScrollView(frame: window.bounds)
        scrollView?.delegate = self
        scrollView?.minimumZoomScale = 1.0
        scrollView?.maximumZoomScale = 4.0 // Max zoom level set to 4x
        scrollView?.showsVerticalScrollIndicator = false
        scrollView?.showsHorizontalScrollIndicator = false
        scrollView?.backgroundColor = .clear

        // Enable interaction so gestures work
        scrollView?.isUserInteractionEnabled = true
        window.addSubview(scrollView!)

        // 4. Setup Image INSIDE ScrollView 🖼️
        // Initially set frame to original position for animation
        zoomImageView = UIImageView(frame: originalFrame)
        zoomImageView?.image = image
        zoomImageView?.tintColor = .systemIndigo
        zoomImageView?.contentMode = .scaleAspectFill
        zoomImageView?.clipsToBounds = true
        zoomImageView?.layer.cornerRadius = originalCornerRadius
        zoomImageView?.isUserInteractionEnabled = true

        // Important: Add image to scrollview, not window directly
        if let zoomImageView = zoomImageView {
            scrollView?.addSubview(zoomImageView)
        }

        // 5. Gestures (Only Swipe/Pan to dismiss) 👆👇
        // Removed Tap gestures as per your request
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        scrollView?.addGestureRecognizer(panGesture)

        // 6. Animate Open
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.backgroundView?.alpha = 1

            // Center the image in the scrollview
            let width = window.frame.width
            let height = image.size.height * (width / image.size.width) // Maintain aspect ratio

            let finalFrame = CGRect(x: 0,
                                    y: (window.frame.height - height) / 2,
                                    width: width,
                                    height: height)

            self.zoomImageView?.frame = finalFrame
            self.zoomImageView?.layer.cornerRadius = 0

        } completion: { _ in
            // Logic to center content size after animation
            self.scrollView?.contentSize = self.zoomImageView?.frame.size ?? .zero
        }
    }

    // MARK: - Pan Gesture Logic (Swipe Up/Down to Dismiss) 🖐️

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView, let window = getWindow() else { return }

        // Rule: Only allow dismiss if we are NOT zoomed in
        guard scrollView.zoomScale == 1.0 else { return }

        let translation = sender.translation(in: window)
        let velocity = sender.velocity(in: window)

        switch sender.state {
        case .changed:
            // Move image with finger
            zoomImageView.center = CGPoint(x: window.center.x + translation.x, y: window.center.y + translation.y)

            // Fade background based on distance moved (Visual feedback)
            let verticalDist = abs(translation.y)
            let alpha = 1.0 - (verticalDist / 400.0)
            backgroundView?.alpha = max(0, alpha)

        case .ended:
            // If moved far enough (100 points) or swiped fast -> Dismiss
            if abs(translation.y) > 100 || abs(velocity.y) > 800 {
                dismissFullScreen()
            } else {
                // Not enough swipe? Snap back to center
                UIView.animate(withDuration: 0.3) {
                    zoomImageView.center = window.center
                    self.backgroundView?.alpha = 1.0
                }
            }
        default:
            break
        }
    }

    @objc private func dismissFullScreen() {
        guard let _ = getWindow() else { return }

        // 7. Animate Close
        UIView.animate(withDuration: 0.4, animations: {
            // Transform back to original frame
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.backgroundView?.alpha = 0
        }) { _ in
            self.zoomImageView?.removeFromSuperview()
            self.scrollView?.removeFromSuperview() // Remove scrollview
            self.backgroundView?.removeFromSuperview()

            // Cleanup references to free memory
            self.zoomImageView = nil
            self.scrollView = nil
            self.backgroundView = nil
        }
    }

    // MARK: - UIScrollView Delegate (Required for Zooming) 🔍

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }

    // Optional: Keep image centered when zooming out
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = zoomImageView else { return }

        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)

        image.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                               y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    private func getWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first
    }
}
