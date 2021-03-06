//
//  FavoritesViewController.swift
//  Cheers
//
//  Created by Will Carhart on 5/11/18.
//  Copyright © 2018 University of San Diego. All rights reserved.
//

import UIKit
import ChameleonFramework

class FavoritesViewController: UIViewController {

    @IBOutlet weak var favoritesTableView: UITableView!
    
    var emptyView: EmptyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let xib = UINib(nibName: "PlaceTableViewCell", bundle: nil)
        self.favoritesTableView.register(xib, forCellReuseIdentifier: "PlaceCell")
        
        favoritesTableView.dataSource = self
        favoritesTableView.delegate = self
        favoritesTableView.separatorStyle = UITableViewCellSeparatorStyle.none
        favoritesTableView.backgroundColor = FlatWhiteDark()
        
        emptyView = EmptyView()
        self.view.addSubview(emptyView)
        emptyView.backgroundColor = FlatWhiteDark()
        emptyView.textLabel.text = "No Favorites Yet"
        emptyView.image.image = #imageLiteral(resourceName: "favorites")
        
        DispatchQueue.main.async {
            self.emptyView.frame = self.favoritesTableView.frame
            self.emptyView.needsUpdateConstraints()
            self.emptyView.setNeedsLayout()
            self.emptyView.setNeedsDisplay()
        }
        
        emptyView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.favoritesTableView.reloadData()
        
        DispatchQueue.main.async {
            self.emptyView.frame = self.favoritesTableView.frame
            self.emptyView.translatesAutoresizingMaskIntoConstraints = false
            self.emptyView.topAnchor.constraint(equalTo: self.favoritesTableView.topAnchor, constant: 0).isActive = true
            self.emptyView.bottomAnchor.constraint(equalTo: self.favoritesTableView.bottomAnchor, constant: 0).isActive = true
            self.emptyView.leftAnchor.constraint(equalTo: self.favoritesTableView.leftAnchor, constant: 0).isActive = true
            self.emptyView.rightAnchor.constraint(equalTo: self.favoritesTableView.rightAnchor, constant: 0).isActive = true
            self.emptyView.needsUpdateConstraints()
            self.emptyView.setNeedsLayout()
            self.emptyView.setNeedsDisplay()
        }
        
        if FavoritesSingleton.shared.favorites.count == 0 {
            DispatchQueue.main.async {
                self.emptyView.isHidden = false
                self.favoritesTableView.isHidden = true
                self.view.bringSubview(toFront: self.emptyView)
            }
        } else {
            DispatchQueue.main.async {
                self.emptyView.isHidden = true
                self.favoritesTableView.isHidden = false
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSelectedFromFavorites" {
            let destination = segue.destination as! SelectedPlaceViewController
            let indexPath = favoritesTableView.indexPathForSelectedRow!
            let selectedPlace = FavoritesSingleton.shared.favorites[indexPath.row]
            destination.place = selectedPlace
            destination.sender = "Favorites"
        }
    }
    
    @IBAction func unwindToFavorites(segue: UIStoryboardSegue) {
        
    }

}

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FavoritesSingleton.shared.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath) as! PlaceTableViewCell
        
        var bar = FavoritesSingleton.shared.favorites[indexPath.row]
        
        let imageUrl =  URL(string: bar.record.images[0])
        
        ImageLoader.shared.getImageFromURL(for: imageUrl!) { image in
            cell.cellImageView.image = image
        }
        
        var detailString = ""
        
        let today = Date()
        let todaysDate = today.weekdayName
        let todaysHappyHours = bar.record.happyHours[todaysDate] ?? ""
        detailString += todaysHappyHours == "" ? "" : "\(todaysHappyHours)   |   "
        
        cell.cellNameLabel.text = bar.record.name
        let dist = calculateDistance(myLat: (UserLocations.shared.currentLocation?.coordinate.latitude)!, myLong: (UserLocations.shared.currentLocation?.coordinate.longitude)!, placeLat: bar.record.latitude, placeLong: bar.record.longitude)
        if SettingsSingleton.shared.useMiles {
            detailString += "\(dist) mi"
        } else {
            detailString += "\(dist) km"
        }
        
        cell.cellDetailLabel.text = detailString
        
        cell.cellStar0.isHidden = true
        cell.cellStar1.isHidden = true
        cell.cellStar2.isHidden = true
        cell.cellStar3.isHidden = true
        cell.cellStar4.isHidden = true
        
        switch Int(bar.record.rating) {
        case 0:
            break
        case 1:
            cell.cellStar0.isHidden = false
        case 2:
            cell.cellStar0.isHidden = false
            cell.cellStar1.isHidden = false
        case 3:
            cell.cellStar0.isHidden = false
            cell.cellStar1.isHidden = false
            cell.cellStar2.isHidden = false
        case 4:
            cell.cellStar0.isHidden = false
            cell.cellStar1.isHidden = false
            cell.cellStar2.isHidden = false
            cell.cellStar3.isHidden = false
        default:
            cell.cellStar0.isHidden = false
            cell.cellStar1.isHidden = false
            cell.cellStar2.isHidden = false
            cell.cellStar3.isHidden = false
            cell.cellStar4.isHidden = false
        }
        
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 215.0
    }
    
    func calculateDistance(myLat: Double, myLong: Double, placeLat: Double, placeLong: Double) -> String {
        let radius: Double = 6371.0
        let deltaLat: Double = toRadians(placeLat - myLat)
        let deltaLong: Double = toRadians(placeLong - myLong)
        
        let a: Double =
            sin(deltaLat / 2.0) * sin(deltaLat / 2.0) +
                cos(toRadians(myLat)) * cos(toRadians(placeLat)) *
                sin(deltaLong / 2.0) * sin(deltaLong / 2.0)
        
        let c: Double = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        var d: Double = radius * c
        
        if SettingsSingleton.shared.useMiles {
            d *= 0.621371
        }
        return String(format: "%.2f", d)
    }
    
    func toRadians(_ degrees: Double) -> Double {
        return degrees * (Double.pi / 180.0)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showSelectedFromFavorites", sender: self)
    }
}
