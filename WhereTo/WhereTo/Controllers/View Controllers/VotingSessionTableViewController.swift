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
    var votes: [Vote] = []
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load the vote data
        loadData()
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        tableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
        tableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
        
        
        //        guard let votingSession = votingSession else { return }
        
        // TODO: - fill out description at top of page?
        // TODO: - refresh tableview?
    }
    
    func loadData() {
        guard let votingSession = votingSession,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        // Fetch any votes previously made by this user in this voting session
        VotingSessionController.shared.fetchVotes(in: votingSession) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let votes):
                    // Save the data
                    print("got here to \(#function) and there are \(votes.count) votes")
                    self?.votes = votes.filter { $0.userID == currentUser.uuid }
                    
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
        // TODO: - leave the voting session early?
        
        // Return to the main view of the app
        transitionToStoryboard(named: .TabViewHome)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: - should we even have this? what should it do?
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("got here to \(#function) and there are \(votingSession?.restaurants?.count ?? 0) rows")
        return votingSession?.restaurants?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        guard let restaurant = votingSession?.restaurants?[indexPath.row] else { return cell }
//        print("got here to \(#function) and restaurant is \(restaurant)")
        cell.restaurant = restaurant
        if let voteIndex = votes.firstIndex(where: { $0.restaurantID == restaurant.restaurantID }) {
            cell.vote = voteIndex
        }
        
        return cell
    }
    
    // MARK: - Vote
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Make sure the cell isn't already selected and not all the votes have been cast already
        guard let cell = tableView.cellForRow(at: indexPath) as? RestaurantTableViewCell,
            let votingSession = votingSession,
            cell.vote == nil, votes.count < votingSession.votesEach,
            let restaurant = cell.restaurant
            else { return }
        
        // Calculate the value of the vote
        let voteValue = votingSession.votesEach - votes.count
        
        // Create a vote and save it to the cloud
        VotingSessionController.shared.vote(value: voteValue, for: restaurant, in: votingSession) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let vote):
                    // Add the vote to the array
                    self?.votes.append(vote)
                    
                    // Update the cell
                    cell.vote = (self?.votes.count ?? 1) - 1
                    self?.tableView.reloadData()
                print("got here in casting vote in vote session view")
                    // If the max number of votes have been cast, show an alert and return to the main menu
                    if self?.votes.count == votingSession.votesEach {
                        self?.presentAlert(title: "Voting Completed!", message: "Thank you for your votes! The winning restaurant will be announced once all votes are cast!", completion: { self?.transitionToStoryboard(named: .TabViewHome) })
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
}

// MARK: - Button Delegate
