//
//  selectedRestaurantAlertViewController.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 7/6/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class SelectedRestaurantAlertViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var starRating: [UIImageView]!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var restaurantImage: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var openMapsButton: UIButton!
    
    // MARK: - Properties
    
    var restaurant: Restaurant?
    var message: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openMapsButtonTapped(_ sender: Any) {
        guard let restaurant = restaurant else { return }
        launchMapWith(restaurant: restaurant)
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Set Up UI
    
    func setupViews() {
        
        alertView.addBorder(width: 2, color: .black)
        alertView.addCornerRadius(10)
        cancelButton.addBorder(width: 2, color: .black)
        openMapsButton.addBorder(width: 2, color: .black)
        
        guard let restaurant = restaurant else { return }
        
        messageLabel.text = message
        nameLabel.text = restaurant.name
        if let address = restaurant.location.address1 {
            if let city = restaurant.location.city {
                addressLabel.text = "\(address), \(city)"
            } else { addressLabel.text = address }
        } else { addressLabel.text = restaurant.location.city ?? "" }
        categoriesLabel.text = restaurant.categoryNames.joined(separator: ", ")
        starRating.forEach { $0.image = UIImage(systemName: "star") }
        if let rating = restaurant.rating {
            let intRating = Int(rating)
            for index in 0..<intRating {
                starRating.first(where: { $0.tag == index })?.image = UIImage(systemName: "star.fill")
            }
            if rating > Float(intRating) {
                starRating.first(where: { $0.tag == intRating })?.image = UIImage(systemName: "star.lefthalf.fill")
            }
        }
        
        // Set up the image
        restaurant.getImage { [weak self] (image) in
            DispatchQueue.main.async { self?.restaurantImage.image = image }
        }
    }
}
