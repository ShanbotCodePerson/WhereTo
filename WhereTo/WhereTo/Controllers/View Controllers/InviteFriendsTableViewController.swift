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
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
        
    // MARK: - Outlets
    
    @IBOutlet weak var viewActiveVotingSessionsButton: UIButton!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set InviteFriendsTableViewController as delegate of CLLocationManager
        locationManager.delegate = self
        
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
    }
    
    // MARK: - Receive Notifications
    
    @objc func refreshData() {
        print("got here to \(#function) and there are \(String(describing: UserController.shared.friends?.count)) friends")
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    // MARK: - Set Up UI
    
    func loadAllData() {
        guard UserController.shared.friends == nil else { return }
        
        // Load the user's friends
        UserController.shared.fetchUsersFriends { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Reload the tableview
                    print("got here to \(#function) and there are \(UserController.shared.friends?.count) friends")
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
                        // TODO: - make sure to enable this button as appropriate later
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
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request", textFieldPlaceholder: "Enter email here...", saveButtonTitle: "Send Friend Request", completion: sendRequest(to:))
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
                    // Choose a random restaurant
                    RestaurantController.shared.fetchRandomRestaurant(near: location) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let restaurant):
                                // Present the alert with the restaurant
                                self?.presentRandomRestaurantAlert(restaurant)
                                
                                // Add the restaurant to the user's list of previous restaurants
                                currentUser.previousRestaurants.append(restaurant.restaurantID)
                                
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
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Location Not Found", message: "The location you entered was not found - please try again")
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
                    // Create the voting session
                    VotingSessionController.shared.newVotingSession(with: friends, at: location) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let votingSession):
                                // Transition to the voting page
                                self?.transitionToVotingSessionPage(with: votingSession)
                            case .failure(let error):
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            }
                        }
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Location Not Found", message: "The location you entered was not found - please try again")
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("got here to \(#function) and \(UserController.shared.friends?.count)")
        return UserController.shared.friends?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? FriendTableViewCell else { return UITableViewCell() }

        guard let friend = UserController.shared.friends?[indexPath.row] else { return cell }
        cell.friend = friend
        
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
                            self?.presentChoiceAlert(title: "Block?", message: "Would you like to block \(friend.name) from sending you friend requests in the future?", cancelText: "No", confirmText: "Yes, block", completion: {
                                
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
}
