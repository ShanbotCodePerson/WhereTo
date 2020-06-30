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
    @IBOutlet weak var restaurantTableView: UITableView!
    
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
        restaurantTableView.delegate = self
        restaurantTableView.dataSource = self
        restaurantTableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
         restaurantTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
    }
    
    func reloadView() -> Void {
        DispatchQueue.main.async {
            self.restaurantTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func searchButtonTapped(_ sender: Any) {
        // TODO: Fix error that happens in RestaurantTableViewCell
        guard let name = nameTextField.text, !name.isEmpty,
        let address = addressTextField.text else { return }
        
        
        if address != "" {
            
            RestaurantController.shared.fetchRestaurantsByName(name: name, address: address) { (result) in
                switch result {
                case .success(let restaurants):
                    self.restaurants = restaurants
                    self.reloadView()
                    
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
                    self.restaurants = restaurants
                    self.reloadView()
                    
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
    }

}

// MARK: - Extensions
extension RestaurantSearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}

extension RestaurantSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        cell.restaurant = restaurants[indexPath.row]
        
        return cell
    }
}

// MARK: - SavedButtonDelegate

extension RestaurantTableViewCellSavedButtonDelegate: RestaurantTableViewCellSavedButtonDelegate {
    
    func favoriteRestaurantButton(for cell: RestaurantTableViewCell) {
        guard let currentUser = UserController.shared.currentUser,
            let restaurant = cell.restaurant
            else { return }
        
        if currentUser.favoriteRestaurants.contains(restaurant.restaurantID) {
            // Remove the restaurant from the user's list of favorite restaurants
            currentUser.favoriteRestaurants.removeAll(where: {$0 == restaurant.restaurantID})
            
            // Remove the restaurant from the source of truth
            RestaurantController.shared.favoriteRestaurants?.removeAll(where: { $0 == restaurant })
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Removed Favorite", message: "You have successfully removed \(restaurant.name) from your favorites")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
        else {
            // Add the restaurant from the user's list of favorite restaurants
            currentUser.favoriteRestaurants.append(restaurant.restaurantID)
            
            // Add the restaurant to the source of truth
            RestaurantController.shared.favoriteRestaurants?.append(restaurant)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Favorited", message: "You have successfully saved \(restaurant.name) to your favorite restaurants")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
    }
    
    func blacklistRestaurantButton(for cell: RestaurantTableViewCell) {
        guard let currentUser = UserController.shared.currentUser,
            let restaurant = cell.restaurant
            else { return }
        
        if currentUser.blacklistedRestaurants.contains(restaurant.restaurantID) {
            // Remove the restaurant from the user's list of blacklisted restaurants
            currentUser.blacklistedRestaurants.removeAll(where: {$0 == restaurant.restaurantID})
            
            // Remove the restaurant from the source of truth
            RestaurantController.shared.blacklistedRestaurants?.removeAll(where: { $0 == restaurant })
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Removed Blacklist", message: "You have successfully removed \(restaurant.name) from your blacklisted restaurants")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
        else {
            // Add the restaurant from the user's list of blacklisted restaurants
            currentUser.blacklistedRestaurants.append(restaurant.restaurantID)
            
            // Add the restaurant to the source of truth
            RestaurantController.shared.blacklistedRestaurants?.append(restaurant)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Blacklisted", message: "You have successfully blacklisted \(restaurant.name) and will not be directed there again after this voting session")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
    }
}
