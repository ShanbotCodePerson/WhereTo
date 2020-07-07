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
        restaurantTableView.tableFooterView = UIView()
        restaurantTableView.backgroundColor = .background
        setUpDelegates()
        setUpNotificationObservers()
    }
    
    // MARK: - Helper Methods
    
    func setUpDelegates() {
        locationManager.delegate = self
        nameTextField.delegate = self
        addressTextField.delegate = self
        restaurantTableView.delegate = self
        restaurantTableView.dataSource = self
        restaurantTableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
        restaurantTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
    }
    
    func reloadView() {
        DispatchQueue.main.async { self.restaurantTableView.reloadData() }
    }
    
    // MARK: - Actions
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        // Close the keyboard
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        search()
    }
    
    // A helper method to actually execute the search
    func search() {
        guard let name = nameTextField.text, !name.isEmpty,
            let address = addressTextField.text else {
                presentAlert(title: "No Name Entered", message: "You must enter a name of a restaurant to search for")
                return
        }
        
        if address != "" {
            view.activityStartAnimating()
            RestaurantController.shared.fetchRestaurantsByName(name: name, address: address) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let restaurants):
                        self?.restaurants = restaurants
                        self?.reloadView()
                        self?.view.activityStopAnimating()
                        
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        self?.view.activityStopAnimating()
                        return
                    }
                }
            }
        } else {
            fetchCurrentLocation(locationManager)
            let currentLocation = locationManager.location
            view.activityStartAnimating()
            RestaurantController.shared.fetchRestaurantsByName(name: name, currentLocation: currentLocation) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let restaurants):
                        self?.restaurants = restaurants
                        self?.reloadView()
                        self?.view.activityStopAnimating()
                        
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        self?.view.activityStopAnimating()
                        return
                    }
                }
            }
        }
    }
}

// MARK: - TableView Methods

extension RestaurantSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        cell.restaurant = restaurants[indexPath.row]
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Close the keyboard
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
        
        let restaurant = restaurants[indexPath.row]
        
        // Present an alert controller asking the user if they want to open the restaurant in maps
        presentChoiceAlert(title: "Open in Maps?", message: "", confirmText: "Open in Maps") {
            self.launchMapWith(restaurant: restaurant)
        }
    }
}

// MARK: - TextField Delegate

extension RestaurantSearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Try to move to the next field
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Otherwise, close the keyboard and try to search
            textField.resignFirstResponder()
            search()
        }
        
        return true
    }
}

// MARK: - SavedButtonDelegate

extension RestaurantSearchViewController: RestaurantTableViewCellSavedButtonDelegate {
    
    func favoriteRestaurantButton(for cell: RestaurantTableViewCell) {
        guard let currentUser = UserController.shared.currentUser,
            let restaurant = cell.restaurant
            else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
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
                    NotificationCenter.default.post(Notification(name: .updateSavedList))
                    NotificationCenter.default.post(Notification(name: .updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
        else {
            // Add the restaurant from the user's list of favorite restaurants (making sure to avoid duplicates)
            currentUser.favoriteRestaurants.uniqueAppend(restaurant.restaurantID)
            
            // Add the restaurant to the source of truth (making sure to avoid duplicates)
            RestaurantController.shared.favoriteRestaurants?.uniqueAppend(restaurant)
            
            // Save the restaurant to the cloud
            RestaurantController.shared.save(restaurant) { (_) in }
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Favorited", message: "You have successfully saved \(restaurant.name) to your favorite restaurants")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: .updateSavedList))
                    NotificationCenter.default.post(Notification(name: .updateHistoryList))
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
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
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
                    NotificationCenter.default.post(Notification(name: .updateSavedList))
                    NotificationCenter.default.post(Notification(name: .updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
        else {
            // Add the restaurant from the user's list of blacklisted restaurants (making sure to avoid duplicates)
            currentUser.blacklistedRestaurants.uniqueAppend(restaurant.restaurantID)
            
            // Add the restaurant to the source of truth (making sure to avoid duplicates)
            RestaurantController.shared.blacklistedRestaurants?.uniqueAppend(restaurant)
            
            // Save the restaurant to the cloud
            RestaurantController.shared.save(restaurant) { (_) in }
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Blacklisted", message: "You have successfully blacklisted \(restaurant.name) and will not be directed there again after this voting session")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: .updateSavedList))
                    NotificationCenter.default.post(Notification(name: .updateHistoryList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
    }
}
