//
//  LoadingManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//

import UIKit

// 1. Protocol: This makes it "DI Ready" for the future 🛠️
protocol LoaderService {
    func startLoading()
    func stopLoading()
}

// 2. The Class
class LoaderManager: LoaderService {
    
    // ✅ Singleton Access
    static let shared = LoaderManager()
    
    // Private variables to hold the UI
    private var backgroundView: UIView?
    private var spinner: UIActivityIndicatorView?
    
    // 🔒 Private Init (So no one can make a fake Loader)
    private init() {}
    
    // MARK: - Methods
    
    func startLoading() {
        // Safety Check: If already loading, stop here.
        guard backgroundView == nil else { return }
        
        // Get the main window securely
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // 1. Create the Dim Background
        let view = UIView(frame: window.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0 // Start hidden for animation
        
        // 2. Create the Spinner
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = view.center
        
        // 3. Add to screen
        view.addSubview(activityIndicator)
        window.addSubview(view)
        
        // 4. Start
        activityIndicator.startAnimating()
        
        // Save references for later
        self.backgroundView = view
        self.spinner = activityIndicator
        
        // 5. Smooth Fade In Animation ✨
        UIView.animate(withDuration: 0.25) {
            view.alpha = 1.0
        }
    }
    
    func stopLoading() {
        // Safety Check: Do nothing if we aren't loading
        guard let view = backgroundView else { return }
        
        // Smooth Fade Out Animation
        UIView.animate(withDuration: 0.25, animations: {
            view.alpha = 0
        }) { _ in
            // Cleanup: Remove from screen and memory 🧹
            self.spinner?.stopAnimating()
            view.removeFromSuperview()
            
            // Reset variables
            self.backgroundView = nil
            self.spinner = nil
        }
    }
}
