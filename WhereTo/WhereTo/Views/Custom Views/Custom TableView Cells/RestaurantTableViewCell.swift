//
//  RestaurantTableViewCell.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

protocol RestaurantTableViewCellSavedButtonDelegate: class {
    func saveRestaurantButton(for cell: RestaurantTableViewCell)
}

class RestaurantTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var isSavedButton: UIButton!
    @IBOutlet weak var voteStatusImage: UIImageView!
    
    // MARK: - Properties
    
    var restaurant: Restaurant? { didSet { setUpViews() } }
    var vote: Int? { didSet { formatWithVote() } }
    
    weak var delegate: RestaurantTableViewCellSavedButtonDelegate?
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let restaurant = restaurant else { return }
        
        nameLabel.text = restaurant.name
        if let rating = restaurant.rating { ratingLabel.text = "Rating: \(rating)" }
        voteStatusImage.isHidden = true
    }
    
    func formatWithVote() {
        guard let vote = vote else { return }
        
        voteStatusImage.isHidden = false
        voteStatusImage.image = UIImage(systemName: "\(vote + 1).circle.fill")
        // TODO: - change color of image, or of entire cell, based on ranking?
    }
    
    // MARK: - Actions
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        delegate?.saveRestaurantButton(for: self)
    }
}
