//
//  HistoryViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var restaurantsTableView: UITableView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observer to listen for changes in the data
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: updateHistoryList, object: nil)
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
        
        // Load the data if it hasn't been loaded already
        loadData()
    }
    
    // MARK: - Respond to Notifications
    
    @objc func refreshData() {
        DispatchQueue.main.async { self.restaurantsTableView.reloadData() }
    }
    
    // MARK: - Set up the UI
    
    func setUpViews() {
        // Hide the extra section markers at the bottom of the tableview
        restaurantsTableView.tableFooterView = UIView()
        restaurantsTableView.backgroundColor = .background
        
        // Set up the tableview
        restaurantsTableView.delegate = self
        restaurantsTableView.dataSource = self
        restaurantsTableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
        restaurantsTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
    }
    
    func loadData() {
        if RestaurantController.shared.previousRestaurants == nil {
            view.activityStartAnimating()
            RestaurantController.shared.fetchPreviousRestaurants { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Reload the tableview
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
    }
}

// MARK: - TableView Methods

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RestaurantController.shared.previousRestaurants?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        guard let restaurant = RestaurantController.shared.previousRestaurants?[indexPath.row] else { return cell }
        cell.restaurant = restaurant
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presentChoiceAlert(title: "Remove", message: "Are you sure you would like to remove this restaurant from your history?") {
                guard let currentUser = UserController.shared.currentUser else { return }
                currentUser.previousRestaurants.remove(at: indexPath.row)
                RestaurantController.shared.previousRestaurants?.remove(at: indexPath.row)
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let restaurant = RestaurantController.shared.previousRestaurants?[indexPath.row] else { return }
        
        // Present an alert controller asking the user if they want to open the restaurant in maps
        presentChoiceAlert(title: "Open in Maps?", message: "", confirmText: "Open in Maps") {
            self.launchMapWith(restaurant: restaurant)
        }
    }
}

// MARK: - SavedButtonDelegate

extension HistoryViewController: RestaurantTableViewCellSavedButtonDelegate {
    
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
                    
                    // Send the notification to update the saved restaurants list
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    
                    // Send the notification to update the saved restaurants list
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    
                    // Send the notification to update the saved restaurants list
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    self?.presentAlert(title: "Successfully Blacklisted", message: "You have successfully blacklisted \(restaurant.name) and will not be directed there again")
                    
                    // Send the notification to update the saved restaurants list
                    NotificationCenter.default.post(Notification(name: updateSavedList))
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
            }
        }
    }
}
