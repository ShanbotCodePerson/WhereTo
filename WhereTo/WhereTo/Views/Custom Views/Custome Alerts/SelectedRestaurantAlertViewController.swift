//
//  selectedRestaurantAlertViewController.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 7/6/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class SelectedRestaurantAlertViewController: UIViewController {
    
    // MARK: - Properties
    var restaurant: Restaurant?
    
    // MARK: - Outlets
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var restaurantImage: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var openMapsButton: UIButton!
    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: Any) {
        // TODO: DisMiss View
    }
    @IBAction func openMapsButtonTapped(_ sender: Any) {
        guard let restaurant = restaurant else { return }
        // TODO: DisMiss View
        launchMapWith(restaurant: restaurant)
    }
    
    // MARK: - Helpers
    func setupViews() {
        
        alertView.addBorder(width: 2, color: .black)
        alertView.addCornerRadius(10)
        cancelButton.addBorder(width: 2, color: .black)
        openMapsButton.addBorder(width: 2, color: .black)
        
        
        guard let restaurant = restaurant else { return }
        // get Image
        var image: UIImage?
        RestaurantController.shared.fetchImage(for: restaurant) { (img) in
            image = img
        }
        
        messageLabel.text = "Random Picker Chose"
        nameLabel.text = restaurant.name
        addressLabel.text = restaurant.location.displayAddress.joined(separator: ", ")
        ratingLabel.text = "Rating: \(restaurant.rating ?? 3)"
        restaurantImage.image = image
    }
}
