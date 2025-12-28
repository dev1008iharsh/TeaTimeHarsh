//
//  DetailStaticCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 28/12/25.
//
 

import UIKit

class DetailStaticCell: UITableViewCell {
    // MARK: - IBOutlet
 
    @IBOutlet weak var btnPhone: UIButton!
  
    @IBOutlet weak var lblDesc: UILabel!
    
    var teaPlace: TeaPlace?{
        didSet{
            configure()
        }
    }
    
    // MARK: - Properties
 
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Configure Data

    func configure() {
        btnPhone.setTitle("Connect via \(teaPlace?.phone, default: "")", for: .normal)
        lblDesc.text = teaPlace?.desc ?? ""
    }
    @IBAction func btnCallTapped(_ sender: UIButton) {
        guard let phone = teaPlace?.phone,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    
}
