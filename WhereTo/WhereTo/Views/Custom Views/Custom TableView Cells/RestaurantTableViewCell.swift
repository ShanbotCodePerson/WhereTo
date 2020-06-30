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
        
        // Fill in the basic information about the restaurant
        nameLabel.text = restaurant.name
        categoriesLabel.text = restaurant.categoryNames.joined(separator: ", ")
        if let rating = restaurant.rating { ratingLabel.text = "\(rating) Stars" }
        
        // Establish the defaults for the buttons
        isFavoriteButton.isHidden = false
        isFavoriteButton.isSelected = false
        isBlacklistedButton.isHidden = false
        isBlacklistedButton.isSelected = false
        isFavoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
        isFavoriteButton.setImage(UIImage(systemName: "star.fill"), for: .selected)
        isBlacklistedButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        isBlacklistedButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .selected)
        
        // Check if the restaurant is blacklisted or favorited, and format it accordingly
        guard let currentUser = UserController.shared.currentUser else { return }
        if currentUser.favoriteRestaurants.contains(restaurant.restaurantID) {
            isFavoriteButton.isSelected = true
            isBlacklistedButton.isHidden = true
            isBlacklistedButton.isSelected = false
        } else if currentUser.blacklistedRestaurants.contains(restaurant.restaurantID) {
            isBlacklistedButton.isSelected = true
            isFavoriteButton.isHidden = true
            isFavoriteButton.isSelected = false
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
        guard let restaurant = restaurant, let currentUser = UserController.shared.currentUser else { return }
        
        // Update the UI
        if currentUser.favoriteRestaurants.contains(restaurant.restaurantID) {
            // Deselect the favorites button and show the blacklist button
            isFavoriteButton.isSelected = false
            isBlacklistedButton.isHidden = false
        } else {
            // Select the favorites button and deselect and hide the blacklist button
            isFavoriteButton.isSelected = true
            isBlacklistedButton.isSelected = false
            isBlacklistedButton.isHidden = true
        }
        
        // Handle the action in the delegate
        delegate?.favoriteRestaurantButton(for: self)
    }
    
    @IBAction func blacklistedButtonTapped(_ sender: UIButton) {
        guard let restaurant = restaurant, let currentUser = UserController.shared.currentUser else { return }
        
        // Update the UI
        if currentUser.blacklistedRestaurants.contains(restaurant.restaurantID) {
            // Deselect the blacklist button and show the favorite button
            isBlacklistedButton.isSelected = false
            isFavoriteButton.isHidden = false
        } else {
            // Select the blacklist button and hide the favorite button
            isBlacklistedButton.isSelected = true
            isFavoriteButton.isHidden = true
        }
        
        // Handle the action in the delegate
        delegate?.blacklistRestaurantButton(for: self)
    }
}
