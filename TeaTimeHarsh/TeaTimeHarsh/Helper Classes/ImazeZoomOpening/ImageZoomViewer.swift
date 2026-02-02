//
//  ImageZoomViewer.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

//
//  ImageZoomViewer.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit
import Photos

// MARK: - ImageZoomViewer Class
// Allows viewing an image in full screen with Zoom, Pan, and Share features.
class ImageZoomViewer: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // Singleton instance to access this class from anywhere
    static let shared = ImageZoomViewer()
    
    // MARK: - Private Properties
    // Stores the original position/style of the image to animate back later
    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0
    
    // Core UI Elements
    private var zoomImageView: UIImageView?
    private var backgroundView: UIView? // Black background dimming layer
    private var scrollView: UIScrollView? // container for zooming
    
    // Floating Buttons
    private var closeButton: UIButton?
    private var shareButton: UIButton?
    private var saveButton: UIButton?
    
    // State Variables
    private var isControlHidden = false // Tracks if buttons are visible or hidden
    private var customPanGesture: UIPanGestureRecognizer? // Reference to the swipe-down gesture
    
    // MARK: - Public Methods
    
    /// Call this function to show the image viewer
    /// - Parameter sourceImageView: The UIImageView user tapped on
    func showFullScreen(from sourceImageView: UIImageView, backgroundColor: UIColor = .black) {
        
        // Safety check: Ensure we have a valid window and image
        guard let window = getWindow(), let image = sourceImageView.image else { return }
        
        // 1. Save Original Position
        // Converting frame to window coordinates so we know where to start animation
        originalFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil) ?? .zero
        originalCornerRadius = sourceImageView.layer.cornerRadius
        
        // 2. Setup Background View
        let bgView = UIView(frame: window.bounds)
        bgView.backgroundColor = backgroundColor
        bgView.alpha = 0 // Start transparent
        window.addSubview(bgView)
        self.backgroundView = bgView
        
        // 3. Setup ScrollView (For Zooming support)
        let scView = UIScrollView(frame: window.bounds)
        scView.delegate = self
        scView.minimumZoomScale = 1.0
        scView.maximumZoomScale = 4.0 // Max zoom level (4x)
        scView.showsVerticalScrollIndicator = false
        scView.showsHorizontalScrollIndicator = false
        scView.backgroundColor = .clear
        scView.contentInsetAdjustmentBehavior = .never // Fullscreen content
        window.addSubview(scView)
        self.scrollView = scView
        
        // 4. Setup Image View inside ScrollView
        let imgView = UIImageView(frame: originalFrame)
        imgView.image = image
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = originalCornerRadius
        imgView.isUserInteractionEnabled = true
        scView.addSubview(imgView)
        self.zoomImageView = imgView
        
        // 5. Create Buttons (Close, Save, Share)
        setupFloatingControls(in: window)
        
        // 6. Add Gestures (Tap, Double Tap, Swipe)
        setupGestures()
        
        // 7. Animate Opening 🚀
        // using [weak self] to avoid memory leaks
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            
            self.backgroundView?.alpha = 1
            self.toggleControlsVisibility(isHidden: false, animated: false)
            
            // Calculate final frame to center the image on screen
            let width = window.frame.width
            let height = image.size.height * (width / image.size.width)
            let yPosition = max(0, (window.frame.height - height) / 2)
            
            self.zoomImageView?.frame = CGRect(x: 0, y: yPosition, width: width, height: height)
            self.zoomImageView?.layer.cornerRadius = 0
            
        } completion: { [weak self] _ in
            guard let self = self else { return }
            // Set scrollable area size equal to image size
            self.scrollView?.contentSize = self.zoomImageView?.frame.size ?? .zero
            self.centerImage()
        }
    }
    
    // MARK: - UI Setup: Buttons 🎨
    
    private func setupFloatingControls(in window: UIWindow) {
        let safeArea = window.safeAreaLayoutGuide
        
        // A. Close Button (Top Right)
        let closeBtn = createButton(iconName: "xmark", action: #selector(dismissFullScreen))
        window.addSubview(closeBtn)
        self.closeButton = closeBtn
        
        // Layout Constraints for Close Button
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            closeBtn.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // B. Share Button (Bottom Left)
        let shareBtn = createButton(iconName: "square.and.arrow.up", action: #selector(handleShare))
        window.addSubview(shareBtn)
        self.shareButton = shareBtn
        
        // Layout Constraints for Share Button
        NSLayoutConstraint.activate([
            shareBtn.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            shareBtn.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            shareBtn.widthAnchor.constraint(equalToConstant: 44),
            shareBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // C. Save Button (Bottom Right)
        let saveBtn = createButton(iconName: "arrow.down.to.line", action: #selector(handleSave))
        window.addSubview(saveBtn)
        self.saveButton = saveBtn
        
        // Layout Constraints for Save Button
        NSLayoutConstraint.activate([
            saveBtn.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            saveBtn.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            saveBtn.widthAnchor.constraint(equalToConstant: 44),
            saveBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Start with buttons hidden (they animate in later)
        closeButton?.alpha = 0
        shareButton?.alpha = 0
        saveButton?.alpha = 0
    }
    
    // Helper function to create styled buttons
    private func createButton(iconName: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: iconName)
        
        // Style: White background with Black icon
        config.baseBackgroundColor = .white.withAlphaComponent(0.9)
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule // Rounded shape
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout
        
        // Add shadow for better visibility on white images
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }
    
    // MARK: - Gestures & Conflict Handling 🛡️
    
    private func setupGestures() {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView else { return }
        
        // 1. Single Tap: Toggle Controls (Show/Hide)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)
        
        // 2. Double Tap: Zoom In/Out
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomImageView.addGestureRecognizer(doubleTap)
        zoomImageView.tintColor = .systemIndigo
        // Important: Single tap waits to see if user is actually double tapping
        singleTap.require(toFail: doubleTap)
        
        // 3. Pan: Swipe Down to Dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self // Needed for conflict resolution
        scrollView.addGestureRecognizer(panGesture)
        self.customPanGesture = panGesture
    }
    
    // 🔥 Critical Fix: Resolves conflict between Zooming and Swipe-to-Dismiss
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == customPanGesture {
            // Only allow 'Swipe Down' if image is NOT zoomed in (scale is 1.0)
            // If zoomed in, this returns false, so ScrollView handles the touch (panning around the image)
            return scrollView?.zoomScale == 1.0
        }
        return true
    }
    
    // MARK: - Action Handlers
    
    // Show/Hide buttons on tap
    @objc private func handleSingleTap() {
        HapticHelper.light()
        isControlHidden.toggle()
        toggleControlsVisibility(isHidden: isControlHidden, animated: true)
    }
    
    // Handle Double Tap Zoom logic
    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        HapticHelper.medium()
        guard let scrollView = scrollView else { return }
        
        if scrollView.zoomScale > 1.0 {
            // If already zoomed, go back to normal
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            // If normal, zoom in to where user tapped
            let point = sender.location(in: zoomImageView)
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    // Handle Dragging (Pan)
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView, let window = getWindow() else { return }
        
        // Note: gestureRecognizerShouldBegin ensures this only runs when zoomScale is 1.0
        
        let translation = sender.translation(in: window)
        let velocity = sender.velocity(in: window)
        
        switch sender.state {
        case .began:
            // Hide buttons when dragging starts
            toggleControlsVisibility(isHidden: true, animated: true)
        case .changed:
            // Move image with finger
            zoomImageView.center = CGPoint(x: window.center.x + translation.x, y: window.center.y + translation.y)
            
            // Fade background based on drag distance
            let verticalDist = abs(translation.y)
            backgroundView?.alpha = max(0, 1.0 - (verticalDist / 400.0))
        case .ended:
            // If dragged far enough or fast enough, dismiss
            if abs(translation.y) > 100 || abs(velocity.y) > 800 {
                dismissFullScreen()
            } else {
                // Otherwise, snap back to center
                UIView.animate(withDuration: 0.3) {
                    zoomImageView.center = window.center
                    self.backgroundView?.alpha = 1.0
                    self.toggleControlsVisibility(isHidden: false, animated: true)
                }
            }
        default: break
        }
    }
    
    // Close the viewer with animation
    @objc private func dismissFullScreen() {
        HapticHelper.heavy()
        guard let _ = getWindow() else { return }
        
        // Hide controls and disable touch
        toggleControlsVisibility(isHidden: true, animated: true)
        scrollView?.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            guard let self = self else { return }
            // Animate back to original position
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.zoomImageView?.contentMode = .scaleAspectFill
            self.backgroundView?.alpha = 0
        }) { [weak self] _ in
            // Clean up memory after animation finishes
            self?.cleanup()
        }
    }
    
    // MARK: - Save & Share Features
    
    // Save button action
    @objc private func handleSave() {
        HapticHelper.success()
        guard let image = zoomImageView?.image else { return }
        // Save image to Photos Library
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // Completion Handler for Save Action (Shows Alert)
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        let title: String
        let message: String
        
        if let error = error {
            // Case: Error Saving
            title = "Error ❌"
            message = error.localizedDescription
        } else {
            // Case: Success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            title = "Saved! ✅"
            message = "Your image has been saved to Photos."
        }
        
        // Show Alert to User
        if let window = getWindow() {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    // Share button action
    @objc private func handleShare() {
        guard let image = zoomImageView?.image, let window = getWindow() else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // Fix for iPad crash (Anchor popover to the button)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
        }
        window.rootViewController?.present(activityVC, animated: true)
    }
    
    // MARK: - Utilities & Cleanup
    
    // Fade buttons in or out
    private func toggleControlsVisibility(isHidden: Bool, animated: Bool) {
        let alpha: CGFloat = isHidden ? 0 : 1
        let duration = animated ? 0.2 : 0.0
        
        UIView.animate(withDuration: duration) {
            self.closeButton?.alpha = alpha
            self.shareButton?.alpha = alpha
            self.saveButton?.alpha = alpha
        }
    }
    
    // Remove everything from memory (Prevent Leaks)
    private func cleanup() {
        zoomImageView?.removeFromSuperview()
        scrollView?.removeFromSuperview()
        backgroundView?.removeFromSuperview()
        closeButton?.removeFromSuperview()
        shareButton?.removeFromSuperview()
        saveButton?.removeFromSuperview()
        
        zoomImageView = nil
        scrollView = nil
        backgroundView = nil
        closeButton = nil
        shareButton = nil
        saveButton = nil
        customPanGesture = nil
    }
    
    // Calculate rect to zoom into specific point
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        guard let scrollView = scrollView else { return .zero }
        var zoomRect = CGRect.zero
        zoomRect.size.height = scrollView.frame.size.height / scale
        zoomRect.size.width  = scrollView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: zoomImageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    // Keeps image in center of screen
    private func centerImage() {
        guard let scrollView = scrollView, let image = zoomImageView else { return }
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        image.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                               y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    // UIScrollViewDelegate Methods
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    // Helper to get the current active Window
    private func getWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first
    }
}
