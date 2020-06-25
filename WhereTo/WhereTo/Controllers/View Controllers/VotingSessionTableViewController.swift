//
//  VotingSessionTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class VotingSessionTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var votingSession: VotingSession?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let votingSession = votingSession else { return }
        
        // TODO: - fill out description at top of page?
        // TODO: - refresh tableview?
    }

    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: - leave the voting session early
        
        // Return to the main view of the app
        transitionToStoryboard(named: .TabViewHome)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: - should we even have this? what should it do?
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return votingSession?.restaurants?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }

        guard let restaurant = votingSession?.restaurants?[indexPath.row] else { return cell }

        return cell
    }
}
