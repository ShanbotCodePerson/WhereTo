//
//  RestaurantTableViewCell.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

protocol RestaurantTableViewCellSavedButtonDelegate: class {
    func favoriteRestaurantButton(for cell: RestaurantTableViewCell)
    func blacklistRestaurantButton(for cell: RestaurantTableViewCell)
}

class RestaurantTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var isFavoriteButton: UIButton!
    @IBOutlet weak var isBlacklistedButton: UIButton!
    @IBOutlet weak var voteStatusImage: UIImageView!
    @IBOutlet weak var imageContainerView: UIView!
    
    // MARK: - Properties
    
    var restaurant: Restaurant? { didSet { setUpViews() } }
    var vote: Int? { didSet { formatWithVote() } }
    
    weak var delegate: RestaurantTableViewCellSavedButtonDelegate?
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let restaurant = restaurant else { return }
        
        nameLabel.text = restaurant.name
        categoriesLabel.text = restaurant.categoryNames.joined(separator: ", ")
        if let rating = restaurant.rating { ratingLabel.text = "\(rating) Stars" }
        
        // Check if the restaurant is blacklisted or favorited, and format it accordingly
        if RestaurantController.shared.favoriteRestaurants?.contains(restaurant) ?? false {
            isFavoriteButton.isSelected = true
            isBlacklistedButton.isHidden = true
        } else if RestaurantController.shared.blacklistedRestaurants?.contains(restaurant) ?? false {
            isBlacklistedButton.isSelected = true
            isFavoriteButton.isHidden = true
        }
    }
    
    func formatWithVote() {
        guard let vote = vote else { return }
        
        imageContainerView.isHidden = false
        voteStatusImage.image = UIImage(systemName: "\(vote + 1).circle.fill")
        // TODO: - change color of image, or of entire cell, based on ranking?
    }
    
    // MARK: - Actions
    
    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        // Update the UI
        if isFavoriteButton.isSelected {
            isBlacklistedButton.isHidden = true
        } else {
            isBlacklistedButton.isHidden = false
        }
        
        // Handle the action in the delegate
        delegate?.favoriteRestaurantButton(for: self)
    }
    
    @IBAction func blacklistedButtonTapped(_ sender: UIButton) {
        // Update the UI
        if isBlacklistedButton.isSelected {
            isFavoriteButton.isHidden = true
        } else {
            isFavoriteButton.isHidden = false
        }
        
        // Handle the action in the delegate
        delegate?.blacklistRestaurantButton(for: self)
    }
}
