//
//  addToSavedListTableViewController.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 6/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation

class AddToSavedListTableViewController: UITableViewController {

    // MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Helpers
    func reloadData() -> Void {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RestaurantSearchViewController.shared.restaurants.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }

        let restaurant = RestaurantSearchViewController.shared.restaurants[indexPath.row]
        cell.restaurant = restaurant

        return cell
    }
}

