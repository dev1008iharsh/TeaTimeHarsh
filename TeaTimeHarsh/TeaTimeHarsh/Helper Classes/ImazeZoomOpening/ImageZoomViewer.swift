//
//  ImageZoomViewer.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//
 
import UIKit
import Photos

// MARK: - ImageZoomViewer Class
// Allows viewing an image in full screen with Zoom, Pan, Rotate, and Share features.
// Built for iOS 17+ with production-grade memory safety.
class ImageZoomViewer: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // Singleton instance for global access
    static let shared = ImageZoomViewer()
    
    // MARK: - Private Properties
    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0
    
    // Core UI Elements
    private var zoomImageView: UIImageView?
    private var backgroundView: UIView? // Dimming layer
    private var scrollView: UIScrollView? // Container for zooming
    
    // Floating Buttons
    private var closeButton: UIButton?
    private var shareButton: UIButton?
    private var saveButton: UIButton?
    
    // State Variables
    private var isControlHidden = false
    private var customPanGesture: UIPanGestureRecognizer?
    private var customRotationGesture: UIRotationGestureRecognizer? // Added for rotation
    private var initialRotation: CGFloat = 0.0 // Tracks rotation state
    
    // MARK: - Public Methods
    
    /// Call this function to show the image viewer from any view
    /// - Parameter sourceImageView: The UIImageView user tapped on
    /// - Parameter backgroundColor: Background color (default is black)
    func showFullScreen(from sourceImageView: UIImageView, backgroundColor: UIColor = .black) {
        
        // Safety check: Ensure valid window and image. Prevents crash if image is nil.
        guard let window = getWindow(), let image = sourceImageView.image else { return }
        
        // 1. Save Original Position for dismiss animation
        originalFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil) ?? .zero
        originalCornerRadius = sourceImageView.layer.cornerRadius
        
        // 2. Setup Background View
        let bgView = UIView(frame: window.bounds)
        bgView.backgroundColor = backgroundColor
        bgView.alpha = 0 // Start transparent
        window.addSubview(bgView)
        self.backgroundView = bgView
        
        // 3. Setup ScrollView
        let scView = UIScrollView(frame: window.bounds)
        scView.delegate = self
        scView.minimumZoomScale = 1.0
        scView.maximumZoomScale = 4.0 // Max zoom 4x
        scView.showsVerticalScrollIndicator = false
        scView.showsHorizontalScrollIndicator = false
        scView.backgroundColor = .clear
        scView.contentInsetAdjustmentBehavior = .never
        window.addSubview(scView)
        self.scrollView = scView
        
        // 4. Setup Image View
        let imgView = UIImageView(frame: originalFrame)
        imgView.image = image
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = originalCornerRadius
        imgView.isUserInteractionEnabled = true
        scView.addSubview(imgView)
        self.zoomImageView = imgView
        
        // 5. Setup Controls & Gestures
        setupFloatingControls(in: window)
        setupGestures()
        
        // Haptic Feedback on Open
        HapticHelper.medium()
        
        // 6. Animate Opening 🚀
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            
            self.backgroundView?.alpha = 1
            self.toggleControlsVisibility(isHidden: false, animated: false)
            
            // Calculate final frame maintaining aspect ratio
            let width = window.frame.width
            let height = image.size.height * (width / image.size.width)
            let yPosition = max(0, (window.frame.height - height) / 2)
            
            self.zoomImageView?.frame = CGRect(x: 0, y: yPosition, width: width, height: height)
            self.zoomImageView?.layer.cornerRadius = 0 // Sharp corners in full screen
            
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.scrollView?.contentSize = self.zoomImageView?.frame.size ?? .zero
            self.centerImage()
        }
    }
    
    // MARK: - UI Setup: Buttons 🎨
    
    private func setupFloatingControls(in window: UIWindow) {
        let safeArea = window.safeAreaLayoutGuide
        
        // Close Button
        let closeBtn = createButton(iconName: "xmark", action: #selector(dismissFullScreen))
        window.addSubview(closeBtn)
        self.closeButton = closeBtn
        
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            closeBtn.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Share Button
        let shareBtn = createButton(iconName: "square.and.arrow.up", action: #selector(handleShare))
        window.addSubview(shareBtn)
        self.shareButton = shareBtn
        
        NSLayoutConstraint.activate([
            shareBtn.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            shareBtn.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            shareBtn.widthAnchor.constraint(equalToConstant: 44),
            shareBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Save Button
        let saveBtn = createButton(iconName: "arrow.down.to.line", action: #selector(handleSave))
        window.addSubview(saveBtn)
        self.saveButton = saveBtn
        
        NSLayoutConstraint.activate([
            saveBtn.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            saveBtn.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            saveBtn.widthAnchor.constraint(equalToConstant: 44),
            saveBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        closeButton?.alpha = 0
        shareButton?.alpha = 0
        saveButton?.alpha = 0
    }
    
    private func createButton(iconName: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: iconName)
        config.baseBackgroundColor = .white.withAlphaComponent(0.9)
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Shadow for premium look
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }
    
    // MARK: - Gestures & Conflict Handling 🛡️
    
    private func setupGestures() {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView else { return }
        
        // 1. Single Tap
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)
        
        // 2. Double Tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomImageView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
        
        // 3. Pan Gesture (Swipe down to dismiss)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        self.customPanGesture = panGesture
        
        // 4. Rotation Gesture (Pinch to rotate) 🔄
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        scrollView.addGestureRecognizer(rotationGesture)
        self.customRotationGesture = rotationGesture
    }
    
    // Allows Pan and Rotation to work together
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == customPanGesture || gestureRecognizer == customRotationGesture {
            // Only allow Pan & Rotation if NOT zoomed in
            return scrollView?.zoomScale == 1.0
        }
        return true
    }
    
    // MARK: - Action Handlers
    
    @objc private func handleSingleTap() {
        HapticHelper.light()
        isControlHidden.toggle()
        toggleControlsVisibility(isHidden: isControlHidden, animated: true)
    }
    
    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        guard let scrollView = scrollView else { return }
        
        if scrollView.zoomScale > 1.0 {
            HapticHelper.light()
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            HapticHelper.medium()
            let point = sender.location(in: zoomImageView)
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    // MARK: - Premium: Pan & Rotate Logic 🔄
    
    @objc private func handleRotation(_ sender: UIRotationGestureRecognizer) {
        guard let zoomImageView = zoomImageView, let window = getWindow() else { return }
        
        switch sender.state {
        case .began:
            toggleControlsVisibility(isHidden: true, animated: true)
            initialRotation = atan2(zoomImageView.transform.b, zoomImageView.transform.a)
        case .changed:
            zoomImageView.transform = CGAffineTransform(rotationAngle: initialRotation + sender.rotation)
        case .ended, .cancelled:
            // Snap back to normal with Spring animation
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                zoomImageView.transform = .identity
                self.toggleControlsVisibility(isHidden: false, animated: true)
            }
        default: break
        }
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let zoomImageView = zoomImageView, let window = getWindow() else { return }
        
        let translation = sender.translation(in: window)
        let velocity = sender.velocity(in: window)
        
        switch sender.state {
        case .began:
            toggleControlsVisibility(isHidden: true, animated: true)
        case .changed:
            let verticalDist = abs(translation.y)
            
            // 1. Scale Down (Rubber-band effect)
            let scale = max(0.8, 1.0 - (verticalDist / 1000.0))
            
            // 2. Dynamic Corner Radius (Smooth rounding as you drag)
            let newCornerRadius = min(originalCornerRadius, (verticalDist / 100) * originalCornerRadius)
            zoomImageView.layer.cornerRadius = newCornerRadius
            
            // Combine scale and position
            zoomImageView.center = CGPoint(x: window.center.x + translation.x, y: window.center.y + translation.y)
            zoomImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 3. Fade background
            backgroundView?.alpha = max(0, 1.0 - (verticalDist / 400.0))
            
        case .ended:
            // "Flick to dismiss" logic: Distance > 120 OR Velocity > 1000
            if abs(translation.y) > 120 || abs(velocity.y) > 1000 {
                dismissFullScreen()
            } else {
                // Snap back to center
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                    zoomImageView.center = window.center
                    zoomImageView.transform = .identity
                    zoomImageView.layer.cornerRadius = 0
                    self.backgroundView?.alpha = 1.0
                    self.toggleControlsVisibility(isHidden: false, animated: true)
                }
            }
        default: break
        }
    }
    
    @objc private func dismissFullScreen() {
        HapticHelper.medium()
        guard let _ = getWindow() else { return }
        
        toggleControlsVisibility(isHidden: true, animated: true)
        scrollView?.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            self.zoomImageView?.transform = .identity
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.zoomImageView?.contentMode = .scaleAspectFill
            self.backgroundView?.alpha = 0
        } completion: { [weak self] _ in
            self?.cleanup()
        }
    }
    
    // MARK: - Save & Share Features
    
    @objc private func handleSave() {
        ToastManager.shared.show(message: "Saving image....")
        guard let image = zoomImageView?.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            HapticHelper.error() // Needs to be implemented in your HapticHelper
            showAlert(title: "Error ❌", message: error.localizedDescription)
        } else {
            HapticHelper.success()
            showAlert(title: "Saved! ✅", message: "Your image has been saved to Photos.")
        }
    }
    
    // 🚀 Share : Always finds the top-most view controller
    @objc private func handleShare() {
        ToastManager.shared.show(message: "Sharing image....")
        HapticHelper.light()
        guard let image = zoomImageView?.image, let topVC = getTopViewController() else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // iPad Fix: Anchors to the share button
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton?.bounds ?? .zero
        }
        
        topVC.present(activityVC, animated: true)
    }
    
    // MARK: - Utilities & Cleanup
    
    private func toggleControlsVisibility(isHidden: Bool, animated: Bool) {
        let alpha: CGFloat = isHidden ? 0 : 1
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.closeButton?.alpha = alpha
            self.shareButton?.alpha = alpha
            self.saveButton?.alpha = alpha
        }
    }
    
    // 🛡️ 100% Memory Safe Cleanup
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
        customRotationGesture = nil
    }
    
    // Calculates rect to zoom into specific tapped point
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
    
    // Improved Pro Centering Logic
    private func centerImage() {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView else { return }
        let boundsSize = scrollView.bounds.size
        var frameToCenter = zoomImageView.frame
        
        frameToCenter.origin.x = frameToCenter.size.width < boundsSize.width ? (boundsSize.width - frameToCenter.size.width) / 2 : 0
        frameToCenter.origin.y = frameToCenter.size.height < boundsSize.height ? (boundsSize.height - frameToCenter.size.height) / 2 : 0
        
        zoomImageView.frame = frameToCenter
    }
    
    // MARK: - UIScrollView Delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    // MARK: - Helpers
    
    private func getWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first
    }
    
    // 🚀 Critical Helper: Finds the currently active ViewController recursively
    private func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? getWindow()?.rootViewController
        
        if let nav = baseVC as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            }
        }
        if let presented = baseVC?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return baseVC
    }
    
    private func showAlert(title: String, message: String) {
        guard let topVC = getTopViewController() else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        topVC.present(alert, animated: true)
    }
}
