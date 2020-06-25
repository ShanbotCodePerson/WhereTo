//
//  RestaurantTableViewCell.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class RestaurantTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    // MARK: - Properties
    
    var restaurant: Restaurant? { didSet { setUpViews() } }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let restaurant = restaurant else { return }
        
        nameLabel.text = restaurant.name
        ratingLabel.text = "Rating: \(restaurant.rating)"
    }
}
