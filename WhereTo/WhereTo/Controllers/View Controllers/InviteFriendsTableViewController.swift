//
//  InviteFriendsTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the data if it hasn't been loaded already
        loadAllData()
        
        // Set up the observers to listen for friend request notifications
        NotificationCenter.default.addObserver(self, selector: #selector(showNewFriendRequest(_:)), name: newFriendRequest, object: FriendRequest.self)
        NotificationCenter.default.addObserver(self, selector: #selector(showFriendRequestResult(_:)), name: newFriendRequest, object: FriendRequest.self)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: updateFriendsList, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Check for pending friend requests, and show alerts for each one if there are any
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
    }
    
    // MARK: - Receive Notifications
    
    @objc func refreshData() {
        print("got here to \(#function)")
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    @objc func showNewFriendRequest(_ sender: NSNotification) {
        print("got here to \(#function) and \(sender) and \(sender.object)")
        guard let friendRequest = sender.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentNewFriendRequestAlert(friendRequest) }
    }
    
    @objc func showFriendRequestResult(_ sender: NSNotification) {
        print("got here to \(#function) and \(sender) and \(sender.object)")
        guard let friendRequest = sender.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentFriendRequestResponseAlert(friendRequest) }
    }
    
    // MARK: - Set Up UI
    
    func loadAllData() {
        guard UserController.shared.friends == nil else { return }
        
        UserController.shared.fetchUsersFriends { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Reload the tableview
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
    
    @IBAction func addFriendButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: - allow searching by email or username
        
        // Present the text field for the user to enter the desired email or to friend
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request", textFieldPlaceholder: "Enter email here...", saveButtonTitle: "Send Friend Request", completion: sendRequest(to:))
    }
    
    func sendRequest(to name: String) {
        guard let currentUser = UserController.shared.currentUser,
            name != currentUser.name else {
                presentAlert(title: "Invalid Username", message: "You can't send a friend request to yourself!")
                return
        }
        
        // Make sure the user hasn't already blocked, sent, received, or accepted a request from that username
        if currentUser.blockedUsers.contains(name) {
            presentAlert(title: "Blocked", message: "You have blocked \(name)")
            return
        }
        // TODO: - search cloud for any outgoing or pending requests from that user
        
        // Make sure that the given username exists in the cloud
        UserController.shared.searchFor(email: name) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let friend):
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
    }
    
    @IBAction func voteButtonTapped(_ sender: UIButton) {
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.friends?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)

        guard let friend = UserController.shared.friends?[indexPath.row] else { return cell }
        cell.textLabel?.text = friend.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the reference to the friend to remove
            guard let friend = UserController.shared.friends?[indexPath.row] else { return }
            
            // Present an alert confirming that the user wants to remove the friend
            presentChoiceAlert(title: "Are you sure?", message: "Are you sure you want to de-friend \(friend.name)") {
                
                // If the user clicks "confirm," remove the friend and update the tableview
                FriendRequestController.shared.sendRequestToRemove(friend) { [weak self] (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // FIXME: - fill this out later
                            print("fill this out later")
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
