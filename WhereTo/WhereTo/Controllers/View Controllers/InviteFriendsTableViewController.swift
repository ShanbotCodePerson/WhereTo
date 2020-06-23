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
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request", textFieldPlaceholder: "Enter username here...", saveButtonTitle: "Send Friend Request", completion: sendRequest(to:))
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
        UserController.shared.searchFor(name: name) { [weak self] (result) in
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
                    // TODO: -implement this
                    
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
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
            // Delete the row from the data source
            // TODO: - enable swipe to defriend
//            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
