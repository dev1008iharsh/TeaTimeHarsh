//
//  HomeVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import UIKit

class HomeVC: UIViewController {

    @IBOutlet weak var tblTeaPlaces: UITableView!
    
    var arrTeaPlaces = [TeaPlace]()
    override func viewDidLoad() {
        super.viewDidLoad()
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        createDummyModel()
        tblTeaPlaces.reloadData()
    }
    
    func createDummyModel(){
        for i in 0...16{
            let teaPlace = TeaPlace(name: "TeaPlace Name \(i+534)", location: "\(i+233) TeaPlace Location", type: "\(i+555)Type", rating: Double(i) + 0.5, image: UIImage(named: "tea\(i)"), isFav: true)
            arrTeaPlaces.append(teaPlace)
        }
    }
    
 

}

extension HomeVC: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrTeaPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let teaCell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        teaCell.configure(teaPlace: arrTeaPlaces[indexPath.row])
        return teaCell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }
    
    
}
