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
    
    // MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDelegates()
    }
    
    // MARK: - Helpers
    
    func setUpDelegates() -> Void {
        locationManager.delegate = self
        nameTextField.delegate = self
        addressTextField.delegate = self
    }
    // MARK: - Actions
    @IBAction func searchButtonTapped(_ sender: Any) {
        // TODO: Fix error that happens in RestaurantTableViewCell
        guard let name = nameTextField.text, !name.isEmpty,
        let address = addressTextField.text else { return }
        
        
        if address != "" {
            
            RestaurantController.shared.fetchRestaurantsByName(name: name, address: address) { (result) in
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
            fetchCurrentLocation(locationManager)
            let currentLocation = locationManager.location
            
            RestaurantController.shared.fetchRestaurantsByName(name: name, currentLocation: currentLocation) { (result) in
                switch result {
                case .success(let restaurants):
                    guard let restaurants = restaurants else { return }
                    self.restaurants = restaurants
                    
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
    }
        
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}

// MARK: - Extensions
extension RestaurantSearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}
