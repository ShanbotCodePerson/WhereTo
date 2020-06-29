//
//  addToSavedListTableViewController.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 6/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation

class addToSavedListTableViewController: UITableViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    var restaurants: [Restaurant] = []
    
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
                    self.reloadData()
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
                    self.reloadData()
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
    }
    
    // MARK: - Helpers
    func reloadData() -> Void {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }

        let restaurant = restaurants[indexPath.row]
        cell.restaurant = restaurant

        return cell
    }
}

