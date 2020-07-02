//
//  SavedRestaurantsViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation

class SavedRestaurantsViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var restaurantsTableView: UITableView!
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observer to listen for changes in the data
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: updateSavedList, object: nil)
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
        
        // Load the data if it hasn't been loaded already
        loadAllData()
    }
    
    // MARK: - Respond to Notifications
    
    @objc func refreshData() {
        DispatchQueue.main.async { self.restaurantsTableView.reloadData() }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        // Hide the extra section markers at the bottom of the tableview
        restaurantsTableView.tableFooterView = UIView()
        restaurantsTableView.backgroundColor = .background
        
        // Set up the location managers delegate
        locationManager.delegate = self
        
        // Set up the tableview
        restaurantsTableView.delegate = self
        restaurantsTableView.dataSource = self
        restaurantsTableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
        restaurantsTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
    }
    
    func loadAllData() {
        if RestaurantController.shared.favoriteRestaurants == nil {
            view.activityStartAnimating()
            RestaurantController.shared.fetchFavoriteRestaurants { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the tableview
                        self?.refreshData()
                        self?.view.activityStopAnimating()
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.view.activityStopAnimating()
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
        if RestaurantController.shared.blacklistedRestaurants == nil {
            RestaurantController.shared.fetchBlacklistedRestaurants { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the tableview
                        self?.refreshData()
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func segmentedControlTapped(_ sender: Any) {
        self.refreshData()
    }
}

// MARK: - TableView Methods

extension SavedRestaurantsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return RestaurantController.shared.favoriteRestaurants?.count ?? 0
        }
        return RestaurantController.shared.blacklistedRestaurants?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        var restaurant: Restaurant?
        if segmentedControl.selectedSegmentIndex == 0 {
            restaurant = RestaurantController.shared.favoriteRestaurants?[indexPath.row]
        } else {
            restaurant = RestaurantController.shared.blacklistedRestaurants?[indexPath.row]
        }
        
        cell.restaurant = restaurant
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presentChoiceAlert(title: "Remove", message: "Are you sure you would like to remove this restaurant from your saved list?") {
                guard let currentUser = UserController.shared.currentUser else { return }
                currentUser.favoriteRestaurants.remove(at: indexPath.row)
                RestaurantController.shared.favoriteRestaurants?.remove(at: indexPath.row)
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard segmentedControl.selectedSegmentIndex == 0,
            let restaurant = RestaurantController.shared.favoriteRestaurants?[indexPath.row]
            else { return }
        
        // Present an alert controller asking the user if they want to open the restaurant in maps
        presentChoiceAlert(title: "Open in Maps?", message: "", confirmText: "Open in Maps") {
            self.launchMapWith(restaurant: restaurant)
        }
    }
}

// MARK: - SavedButtonDelegate

extension SavedRestaurantsViewController: RestaurantTableViewCellSavedButtonDelegate {
    
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
                    
                    // Update the tableview
                    self?.refreshData()
                    
                    // Send the notification to update the previous restaurants list
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
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
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Favorited", message: "You have successfully saved \(restaurant.name) to your favorite restaurants")
                    
                    // Update the tableview
                    self?.refreshData()
                    
                    // Send the notification to update the previous restaurants list
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
                    
                    // Update the tableview
                    self?.refreshData()
                    
                    // Send the notification to update the previous restaurants list
                    NotificationCenter.default.post(Notification(name: updateHistoryList))
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
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Display the success
                    self?.presentAlert(title: "Successfully Blacklisted", message: "You have successfully blacklisted \(restaurant.name) and will not be directed there again")
                    
                    // Update the tableview
                    self?.refreshData()
                    
                    // Send the notification to update the previous restaurants list
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
