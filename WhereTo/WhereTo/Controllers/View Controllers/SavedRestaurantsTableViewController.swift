//
//  SavedRestaurantsTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class SavedRestaurantsTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the data if it hasn't been loaded already
        loadAllData()
        
        // TODO: - may need to register tableview cell and nib
        tableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
    }
    
    // MARK: - Helper Methods
    
    func loadAllData() {
        if RestaurantController.shared.favoriteRestaurants == nil {
            RestaurantController.shared.fetchFavoriteRestaurants { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the tableview
                        self?.tableView.reloadData()
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
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
                        self?.tableView.reloadData()
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
    
    @IBAction func addRestaurantButtonTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func segmentedControlTapped(_ sender: Any) {
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return RestaurantController.shared.favoriteRestaurants?.count ?? 0
        }
        return RestaurantController.shared.blacklistedRestaurants?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        var restaurant: Restaurant?
        if segmentedControl.selectedSegmentIndex == 0 {
            restaurant = RestaurantController.shared.favoriteRestaurants?[indexPath.row]
        } else {
            restaurant = RestaurantController.shared.blacklistedRestaurants?[indexPath.row]
        }
        
        cell.restaurant = restaurant
        cell.delegate = self
        cell.isSavedButton.isSelected = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // TODO: - enable swipe to delete
            // Delete the row from the data source
            //            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - Extension SavedRestaurantsTableViewController: RestaurantTableViewCellSavedButtonDelegate
extension SavedRestaurantsTableViewController: RestaurantTableViewCellSavedButtonDelegate {
    
    func saveRestaurantButton(for cell: RestaurantTableViewCell) {
        
        guard let restaurantID = cell.restaurant?.restaurantID else { return }
        guard let currentUser = UserController.shared.currentUser else { return }
        
        if (currentUser.favoriteRestaurants.contains(restaurantID)) {
            presentLocationSelectionAlert { (result) in
                switch result {
                case .success(_):
                    currentUser.favoriteRestaurants.removeAll(where: {$0 == restaurantID})
                    UserController.shared.saveChanges(to: currentUser) { (result) in
                        switch result {
                        case .success(_):
                            cell.isSavedButton.isSelected = false
                            self.tableView.reloadData()
                        case .failure(let error):
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return
                        }
                    }
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
        else {
            currentUser.favoriteRestaurants.append(restaurantID)
            UserController.shared.saveChanges(to: currentUser) { (result) in
                switch result {
                case .success(_):
                    cell.isSavedButton.isSelected = true
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
    }
}


// MARK: - Extension:SavedRestaurantsTableViewController: Confirm removal from Favs
extension SavedRestaurantsTableViewController {
    
    // Present an alert with a text field to get some input from the user
    func presentLocationSelectionAlert(completion: @escaping (Result<Bool, WhereToError>) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Are you sure you want to remove from favorites?", message: "", preferredStyle: .alert)
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the Current Location button
        let removeFromFavorites = UIAlertAction(title: "Yes", style: .default) { (_) in
            completion(.success(true))
            }
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(removeFromFavorites)
        present(alertController, animated: true)
    }
}
