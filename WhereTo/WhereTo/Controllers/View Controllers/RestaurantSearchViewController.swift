//
//  AddToSavedViewController.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 6/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation

class RestaurantSearchViewController: UIViewController {
    
    // MARK: - Singleton
    
    static let shared = RestaurantSearchViewController()

    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    var restaurants: [Restaurant] = []
    
    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var ratingButton: UIButton!
    @IBOutlet weak var dietaryButton: UIButton!
    @IBOutlet weak var openNowButton: UIButton!
    
    
    // MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
    }
    
    // MARK: - Actions
    @IBAction func searchButtonTapped(_ sender: Any) {
        // TODO: Fix error that happens in RestaurantTableViewCell
        guard let name = nameTextField.text, !name.isEmpty,
            let address = addressTextField.text
            else { return }
        
        fetchCurrentLocation(locationManager)
        let currentLocation = locationManager.location
        
        if  address.isEmpty {
            RestaurantController.shared.fetchRestaurantsByName(name: name, address: nil, currentLocation: currentLocation) { (result) in
                switch result {
                case .success(let results):
                    guard let restaurants = results else { return }
                    self.restaurants = restaurants
                    
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
            
        } else {
            RestaurantController.shared.fetchRestaurantsByName(name: name, address: address, currentLocation: nil) { (result) in
                switch result {
                case .success(let results):
                    guard let restaurants = results else { return }
                    self.restaurants = restaurants
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
    }
    @IBAction func ratingButtonTapped(_ sender: Any) {
    }
    
    @IBAction func dietaryButtonTapped(_ sender: Any) {
    }
    
    @IBAction func openNowButtonTapped(_ sender: Any) {
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}
