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

    func show(message: String, vc: UIViewController) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 20
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        let maxSize = CGSize(width: vc.view.frame.width - 80, height: vc.view.frame.height)
        let expectedSize = toastLabel.sizeThatFits(maxSize)
        
        // Dynamic Width & Height based on text
        let width = min(expectedSize.width + 40, vc.view.frame.width - 40)
        let height = expectedSize.height + 20
        
        // 60 padding from bottom safe area
        let bottomPadding: CGFloat = vc.view.safeAreaInsets.bottom + 60
        toastLabel.frame = CGRect(x: (vc.view.frame.width - width) / 2,
                                 y: vc.view.frame.height - bottomPadding - height,
                                 width: width,
                                 height: height)
        
        vc.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.5, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
