//
//  TeaListTableList.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import UIKit

class TeaListCell: UITableViewCell {
    
    @IBOutlet weak var imgTeaPlace: UIImageView!{
        didSet{
            imgTeaPlace.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var lblLocationTeaPlace: UILabel!
    @IBOutlet weak var lblTypeTeaPlace: UILabel!
    @IBOutlet weak var lblNameTeaPlace: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(teaPlace : TeaPlace){
        imgTeaPlace.image = teaPlace.image
        lblLocationTeaPlace.text = teaPlace.location
        lblTypeTeaPlace.text = teaPlace.type
        lblNameTeaPlace.text = teaPlace.name
    }
    
}
