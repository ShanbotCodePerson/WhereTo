//
//  VotingSessionViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class VotingSessionViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var votingSessionDescriptionLabel: UILabel!
    @IBOutlet weak var restaurantsTableView: UITableView!
    
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
        // Hide the extra section markers at the bottom of the tableview
        restaurantsTableView.tableFooterView = UIView()
        restaurantsTableView.backgroundColor = .background
        
        // Set up the tableview
        restaurantsTableView.delegate = self
        restaurantsTableView.dataSource = self
        restaurantsTableView.register(RestaurantTableViewCell.self, forCellReuseIdentifier: "restaurantCell")
        restaurantsTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
        
        // Fill out the description of the voting session
        guard let votingSession = votingSession, let users = votingSession.users else { return }
        votingSessionDescriptionLabel.text = "Vote on your top \(votingSession.votesEach) places to eat with \(users.map({ $0.name }).joined(separator: ", ")) near \("LOCATION")"
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
                    self?.votes = votes.filter { $0.userID == currentUser.uuid }
                    
                    // Update the tableview
                    self?.restaurantsTableView.reloadData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        // Return to the main view of the app
        transitionToStoryboard(named: .TabViewHome)
    }
}

// MARK: - TableView Methods

extension VotingSessionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return votingSession?.restaurants?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as? RestaurantTableViewCell else { return UITableViewCell() }
        
        guard let restaurant = votingSession?.restaurants?[indexPath.row] else { return cell }
        cell.restaurant = restaurant
        cell.delegate = self
        if let voteIndex = votes.firstIndex(where: { $0.restaurantID == restaurant.restaurantID }) {
            cell.vote = voteIndex
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                    self?.restaurantsTableView.reloadData()
                    
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

// MARK: - SavedButtonDelegate

extension VotingSessionViewController: RestaurantTableViewCellSavedButtonDelegate {
    
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
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
                    self?.presentAlert(title: "Successfully Blacklisted", message: "You have successfully blacklisted \(restaurant.name) and will not be directed there again after this voting session")
                    
                    // Send the notifications to update the saved and previous restaurants lists
                    NotificationCenter.default.post(Notification(name: updateSavedList))
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
