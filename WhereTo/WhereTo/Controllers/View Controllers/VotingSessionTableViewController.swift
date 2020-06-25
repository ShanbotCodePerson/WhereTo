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
    var maxNumberOfVotes: Int?
    var votes: [Vote]?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load the vote data
        loadData()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
//        guard let votingSession = votingSession else { return }
        
        // TODO: - fill out description at top of page?
        // TODO: - refresh tableview?
    }
    
    func loadData() {
        guard let votingSession = votingSession else { return }
        
        // Fetch any votes previously made by this user in this voting session
        VotingSessionController.shared.fetchVotes(in: votingSession) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let votes):
                    // Save the data
                    self?.votes = votes
                    
                    // Update the tableview
                    self?.tableView.reloadData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
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
        cell.restaurant = restaurant
        if let voteIndex = votes?.firstIndex(where: { $0.restaurantID == restaurant.restaurantID }) {
            cell.vote = voteIndex
        }

        return cell
    }
    
    // MARK: - Vote
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Make sure the cell isn't already selected
        guard let cell = tableView.cellForRow(at: indexPath) as? RestaurantTableViewCell,
            cell.vote != nil
            else { return }
        
        // Calculate the value of the vote
        
        // Create a vote and save it to the cloud
        
        // Add the vote to the array
        
        // Update the cell
    }
}

// MARK: - Button Delegate
