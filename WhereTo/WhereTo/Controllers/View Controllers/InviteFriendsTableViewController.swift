//
//  InviteFriendsTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var viewActiveVotingSessionsButton: NeutralButton!
    @IBOutlet weak var voteButton: GoButton!
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling this particular view to update
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: updateFriendsList, object: nil)
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
        
        // Load the data if it hasn't been loaded already
        loadAllData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Check for pending friend requests, then show alerts for each one if there are any
        FriendRequestController.shared.fetchPendingRequests { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let friendRequests):
                    for friendRequest in friendRequests {
                        self?.presentNewFriendRequestAlert(friendRequest)
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
        
        // Check for pending invitations to voting sessions, then show alerts for each one if there are any
        VotingSessionController.shared.fetchPendingInvitations { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let invitations):
                    for invitation in invitations {
                        self?.presentVotingSessionInvitationAlert(invitation, completion: { (newVotingSession) in
                            // If the user accepted the invitation, transition them to the voting session page
                            if let newVotingSession = newVotingSession {
                                self?.transitionToVotingSessionPage(with: newVotingSession)
                            }
                        })
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
        
        // Check to see if there are still active voting sessions, and if not, hide the active voting session button
        if VotingSessionController.shared.votingSessions?.count ?? 0 > 0 {
            viewActiveVotingSessionsButton.isHidden = false
        } else { viewActiveVotingSessionsButton.isHidden = true }
    }
    
    // MARK: - Receive Notifications
    
    @objc func refreshData() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        // The vote button should start off as disabled until the user selects at least one friend
        voteButton.deactivate()
        
        // Set up the CLLocationManager's delegate
        locationManager.delegate = self
    }
    
    func loadAllData() {
        guard UserController.shared.friends == nil else { return }
        
        // Load the user's friends
        UserController.shared.fetchUsersFriends { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Reload the tableview
                    self?.refreshData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
        
        // Load the user's current voting sessions
        VotingSessionController.shared.fetchCurrentVotingSessions { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let votingSessions):
                    if votingSessions.count == 0 {
                        // Don't allow the user to go to the page displaying all the voting sessions if there aren't any
                        self?.viewActiveVotingSessionsButton.isHidden = true
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func addFriendButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: - allow searching by email or username
        
        // Present the text field for the user to enter the desired email
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request", textFieldPlaceholder: "Enter email here...", saveButtonTitle: "Send Friend Request", keyboardType: .emailAddress, completion: sendRequest(to:))
    }
    
    func sendRequest(to email: String) {
        guard let currentUser = UserController.shared.currentUser,
            email != currentUser.email else {
                presentAlert(title: "Invalid Username", message: "You can't send a friend request to yourself!")
                return
        }
        
        // TODO: - search cloud for any outgoing or pending requests from that user
        
        // Make sure that the given username exists in the cloud
        UserController.shared.searchFor(email: email) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let friend):
                    // Make sure the user hasn't already blocked, sent, received, or accepted a request from that username
                    if currentUser.blockedUsers.contains(friend.uuid) {
                        self?.presentAlert(title: "Blocked", message: "You have blocked \(friend.name)")
                        return
                    }
                    
                    // Make sure the friend hasn't blocked the current user
                    guard !friend.blockedUsers.contains(currentUser.name) else {
                        self?.presentAlert(title: "Blocked", message: "You have been blocked by \(friend.name)")
                        return
                    }
                    
                    // Send a friend request to the user
                    FriendRequestController.shared.sendFriendRequest(to: friend) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                // Display the success
                                self?.presentAlert(title: "Friend Request Sent", message: "A friend request has been sent to \(friend.name)")
                            case .failure(let error):
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            }
                        }
                    }
                case .failure(let error):
                    // Display an error if the username doesn't exist
                    if case WhereToError.noSuchUser = error {
                        self?.presentAlert(title: "Invalid Email", message: "The email you have entered is not a user of WhereTo")
                    }
                    else {
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    @IBAction func pickRandomRestaurantButtonTapped(_ sender: UIButton) {
        // Get the current location or allow the user to choose a location
        fetchCurrentLocation(locationManager)
        guard let currentLocation = locationManager.location,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        presentLocationSelectionAlert(currentLocation: currentLocation) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    // If the user has any dietary restrictions, give them the opportunity to filter results by their restrictions
                    if currentUser.dietaryRestrictions.count > 0 {
                        // Allow the user to choose to filter by dietary restrictions or not
                        self?.presentChoiceAlert(title: "Filter By Diet?", message: "Filter the restaurants by your dietary restrictions?", cancelText: "No", confirmText: "Yes", cancelCompletion: {
                            self?.getRandomRestaurant(by: location, filterByDiet: false)
                        }, confirmCompletion: {
                            self?.getRandomRestaurant(by: location, filterByDiet: true)
                        })
                    }
                    else {
                        self?.getRandomRestaurant(by: location, filterByDiet: false)
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Location Not Found", message: "The location you entered was not found - please try again")
                }
            }
        }
    }
    
    // A helper method to actually fetch the random restaurant
    func getRandomRestaurant(by location: CLLocation, filterByDiet: Bool) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // FIXME: - what happens when there are no restaurants?
        RestaurantController.shared.fetchRandomRestaurant(near: location, usingDietaryRestrictions: filterByDiet) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let restaurant):
                    // Present the alert with the restaurant
                    self?.presentRandomRestaurantAlert(restaurant)
                    
                    // Add the restaurant to the user's list of previous restaurants (making sure to avoid duplicates)
                    currentUser.previousRestaurants.uniqueAppend(restaurant.restaurantID)
                    
                    // Add the restaurant to the source of truth (making sure to avoid duplicates)
                    RestaurantController.shared.previousRestaurants?.uniqueAppend(restaurant)
                    
                    // Save the changes to the user
                    UserController.shared.saveChanges(to: currentUser) { (result) in
                        switch result {
                        case .success(_):
                            // Send the notification telling the history page to update its data
                            NotificationCenter.default.post(Notification(name: updateHistoryList))
                        case .failure(let error):
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            DispatchQueue.main.async { self?.presentErrorAlert(error) }
                        }
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    @IBAction func voteButtonTapped(_ sender: UIButton) {
        // Get the selected friends
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        let friends = indexPaths.compactMap { UserController.shared.friends?[$0.row] }
        
        // Get the current location or allow the user to choose a location
        fetchCurrentLocation(locationManager)
        guard let currentLocation = locationManager.location else { return }
        
        // TODO: - disable vote button until at least one other person is selected
        
        presentLocationSelectionAlert(currentLocation: currentLocation) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    // Allow the user to choose to filter results by dietary restrictions
                    self?.presentChoiceAlert(title: "Filter By Diet?", message: "Filter the restaurants by the group's dietary restrictions?", cancelText: "No", confirmText: "Yes", cancelCompletion: {
                            self?.startVotingSession(with: friends, at: location, filterByDiet: false)
                        }, confirmCompletion: {
                            self?.startVotingSession(with: friends, at: location, filterByDiet: true )
                        })
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Location Not Found", message: "The location you entered was not found - please try again")
                }
            }
        }
    }
    
    // A helper method to actually start the voting session
    func startVotingSession(with friends: [User], at location: CLLocation, filterByDiet: Bool) {
        // Create the voting session
        VotingSessionController.shared.newVotingSession(with: friends, at: location, filterByDiet: filterByDiet) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let votingSession):
                    // Transition to the voting page
                    self?.transitionToVotingSessionPage(with: votingSession)
                case .failure(let error):
                    // If the error is that no restaurants match the search, allow the user to turn off the dietary restrictions filter, or just alert them that there are no restaurants
                    if case WhereToError.noRestaurantsMatch = error {
                        if filterByDiet {
                            self?.presentChoiceAlert(title: "No Restaurants Found", message: "There are no restaurants matching your search criteria. Would you like to try again without filtering by dietary restrictions?", cancelText: "No", confirmText: "Yes", confirmCompletion: {
                                self?.startVotingSession(with: friends, at: location, filterByDiet: false)
                            })
                        } else {
                            self?.presentAlert(title: "No Restaurants Found", message: "There are currently no open restaurants in the location you have selected")
                        }
                    }
                    
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If there are no friends, display one row with a notice to tell them to add friends
        return max(UserController.shared.friends?.count ?? 0, 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? FriendTableViewCell else { return UITableViewCell() }

        // If there are no friends, display one row with a notice to tell them to add friends
        guard let friends = UserController.shared.friends, friends.count > 0 else {
            cell.friend = nil
            return cell
        }
        cell.friend = friends[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser,
                let friend = UserController.shared.friends?[indexPath.row]
                else { return }
            
            // Present an alert confirming that the user wants to remove the friend
            presentChoiceAlert(title: "Are you sure?", message: "Are you sure you want to de-friend \(friend.name)?") {
                
                // If the user clicks "confirm," remove the friend and update the tableview
                FriendRequestController.shared.sendRequestToRemove(friend) { [weak self] (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // Give the user an opportunity to block the unwanted friend
                            self?.presentChoiceAlert(title: "Block?", message: "Would you like to block \(friend.name) from sending you friend requests in the future?", cancelText: "No", confirmText: "Yes, block", confirmCompletion: {
                                
                                // Add the friend's ID to the user's list of blocked people
                                currentUser.blockedUsers.append(friend.uuid)
                                
                                // Save the changes to the user
                                UserController.shared.saveChanges(to: currentUser) { (result) in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(_):
                                            // Display the success
                                            self?.presentAlert(title: "Successfully Blocked", message: "You have successfully blocked \(friend.name)")
                                            
                                            // Update the tableview
                                            self?.refreshData()
                                        case .failure(let error):
                                            // Print and display the error
                                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                            self?.presentErrorAlert(error)
                                        }
                                    }
                                }
                            })
                            
                            // Update the tableview
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
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Enable the vote button
        voteButton.activate()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // If there are now no friends selected, then disable the vote button
        if tableView.indexPathsForSelectedRows?.count == 0 { voteButton.deactivate() }
    }
}
