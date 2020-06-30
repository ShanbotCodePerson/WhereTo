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
