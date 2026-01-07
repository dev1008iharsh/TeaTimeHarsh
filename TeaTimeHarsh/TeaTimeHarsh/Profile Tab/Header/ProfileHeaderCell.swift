//
//  ProfileHeaderCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import UIKit

class ProfileHeaderCell: UIView {

    @IBOutlet weak var imgProfile: UIImageView!
 
    var didTapProfileImage: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        setupView()
    }
    
    func setupView() {
        imgProfile.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imgProfile.addGestureRecognizer(tap)
        
 
        imgProfile.clipsToBounds = true
  
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
    }
    
    @objc func handleTap() {
        // 4. Ring the phone! (Trigger the action)
        didTapProfileImage?()
    }
    
    // 5. Helper to set the image
    func configure(image: UIImage?) {
        imgProfile.image = image
    }
}
