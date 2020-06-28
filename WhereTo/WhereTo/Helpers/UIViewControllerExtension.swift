//
//  UIViewControllerExtension.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Navigation

extension UIViewController {
    
    enum StoryboardNames: String {
        case Main
        case TabViewHome
        case VotingSession
    }
    
    func transitionToStoryboard(named storyboard: StoryboardNames, direction: CATransitionSubtype = .fromLeft) {
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = direction
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        self.present(initialVC, animated: false)
    }
    
    func transitionToVotingSessionPage(with votingSession: VotingSession) {
        let storyboard = UIStoryboard(name: StoryboardNames.VotingSession.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? VotingSessionTableViewController else { return }
        initialVC.votingSession = votingSession
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        self.present(initialVC, animated: false)
    }
}
    
// MARK: - Alerts

extension UIViewController {
    
    // Generic Alerts
    
    // Present an alert with a simple dismiss button to display a message to the user
    func presentAlert(title: String, message: String, completion: @escaping () -> Void = { () in }) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
            completion()
        }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert that the internet connection isn't working
    func presentInternetAlert() {
        presentAlert(title: "No Internet Connection", message: "You must be connected to the internet in order to use WhereTo. Please check your internet connection and try again")
    }
    
    // Present an alert with simple confirm or cancel buttons
    func presentChoiceAlert(title: String, message: String, cancelText: String = "Cancel", confirmText: String = "Confirm", completion: @escaping () -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the cancel button to the alert
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel))
        
        // Add the confirm button to the alert
        alertController.addAction(UIAlertAction(title: confirmText, style: .default, handler: { (_) in completion() }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert with a text field to get some input from the user
    func presentTextFieldAlert(title: String, message: String, textFieldPlaceholder: String?, textFieldText: String? = nil, saveButtonTitle: String = "Save", completion: @escaping (String) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field
        alertController.addTextField { (textField) in
            textField.placeholder = textFieldPlaceholder
            if let textFieldText = textFieldText {
                textField.text = textFieldText
            }
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the save button
        let saveAction = UIAlertAction(title: saveButtonTitle, style: .default) { (_) in
            // Get the text from the text field
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            
            // Pass it to the helper function to handle sending the friend request
            completion(text)
        }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    // Present an alert at the bottom of the screen to display an error to the user
    func presentErrorAlert(_ localizedError: LocalizedError) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: localizedError.errorDescription, preferredStyle: .actionSheet)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        present(alertController, animated: true)
    }
    func presentErrorAlert(_ error: Error) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Friend Request Alerts
    
    func presentNewFriendRequestAlert(_ friendRequest: FriendRequest) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Create the alert controller
        let alertController = UIAlertController(title: "New Friend Request", message: "\(friendRequest.fromName) has sent you a friend request!", preferredStyle: .alert)
        
        // Add the cancel button to the alert
        let denyAction = UIAlertAction(title: "Deny", style: .cancel, handler: { (_) in
            FriendRequestController.shared.respondToFriendRequest(friendRequest, accept: false) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Offer the user a chance to block that person
                        self?.presentChoiceAlert(title: "Block?", message: "Would you like to block \(friendRequest.fromName) from sending you friend requests in the future?", cancelText: "No", confirmText: "Yes, block", completion: {
                            
                            // Add the friend's ID to the user's list of blocked people
                            currentUser.blockedUsers.append(friendRequest.fromID)
                            
                            // Save the changes to the user
                            UserController.shared.saveChanges(to: currentUser) { (result) in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(_):
                                        // Display the success
                                        self?.presentAlert(title: "Successfully Blocked", message: "You have successfully blocked \(friendRequest.fromName)")
                                    case .failure(let error):
                                        // Print and display the error
                                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                        self?.presentErrorAlert(error)
                                    }
                                }
                            }
                        })
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        })
        
        // Add the confirm button to the alert
        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { (_) in
            FriendRequestController.shared.respondToFriendRequest(friendRequest, accept: true) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Display the success
                        self?.presentAlert(title: "Added Friend", message: "You have successfully added \(friendRequest.fromName) as a friend!")
                        
                        // Send a notification for the list of friends to be updated
                        NotificationCenter.default.post(Notification(name: updateFriendsList))
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        })
        
        // And the buttons and present the alert
        alertController.addAction(denyAction)
        alertController.addAction(acceptAction)
        present(alertController, animated: true)
    }
    
    func presentFriendRequestResponseAlert(_ friendRequest: FriendRequest) {
        presentAlert(title: "Friend Request \(friendRequest.status == .accepted ? "Accepted" : "Denied")",
            message: "\(friendRequest.toName) has \(friendRequest.status == .accepted ? "accepted" : "denied") your friend request")
    }
    
    // Voting Session Invitation Alert
    
    func presentVotingSessionInvitationAlert(_ votingSessionInvite: VotingSessionInvite, completion: @escaping (VotingSession?) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Vote!", message: "\(votingSessionInvite.fromName) has invited you to vote on a place to eat!", preferredStyle: .alert)
        
        // Create the deny button
        let denyAction = UIAlertAction(title: "No Thanks", style: .cancel) { (_) in
            VotingSessionController.shared.respond(to: votingSessionInvite, accept: false) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully refused invitation")
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                    return completion(nil)
                }
            }
        }
        
        // Create the accept button
        let acceptAction = UIAlertAction(title: "Vote!", style: .default) { (_) in
            VotingSessionController.shared.respond(to: votingSessionInvite, accept: true) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let votingSession):
                        print("Successfully accepted invitation")
                        return completion(votingSession) // FIXME: - get respond function to return voting session
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        return completion(nil)
                    }
                }
            }
        }
        
        // Add the buttons and present the alert
        alertController.addAction(denyAction)
        alertController.addAction(acceptAction)
        present(alertController, animated: true)
    }
    
    // Voting Session Results Alert
    
    // TODO: - what if no restaurant won because the voting session was cancelled somehow?
    func presentVotingSessionResultAlert(_ votingSession: VotingSession) {
        guard let winningRestaurant = votingSession.winningRestaurant else { return }
        
        // Create the alert controller
        let alertController = UIAlertController(title: "Vote Decided!", message: "The crowd has spoken! You have decided to eat at \(winningRestaurant.name)!", preferredStyle: .alert)
        
        // Create the dismiss button
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
        
        // Create the open in maps button
        let openInMapsAction = UIAlertAction(title: "Open in Maps", style: .default) { (_) in
            // TODO: - how to open in maps?
        }
        
        // Add the buttons and present the alert
        alertController.addAction(dismissAction)
        alertController.addAction(openInMapsAction)
        present(alertController, animated: true)
    }
}

// MARK: - Respond to and Display Notifications

// Names of local notifications
let newFriendRequest = Notification.Name("newFriendRequest")
let responseToFriendRequest = Notification.Name("responseToFriendRequest")
let updateFriendsList = Notification.Name("updateFriendsList")
let newVotingSessionInvitation = Notification.Name("newVotingSessionInvitation")
let votingSessionResult = Notification.Name("votingSessionResult")

extension UIViewController {
    
    func setUpNotificationObservers() {
        // Set up the observers to listen for friend request notifications
        NotificationCenter.default.addObserver(self, selector: #selector(showNewFriendRequest(_:)), name: newFriendRequest, object: FriendRequest.self)
        NotificationCenter.default.addObserver(self, selector: #selector(showFriendRequestResult(_:)), name: newFriendRequest, object: FriendRequest.self)
        
        // Set up the observer to listen for voting session invitation notifications
        NotificationCenter.default.addObserver(self, selector: #selector(showVotingSessionInvitation(_:)), name: newVotingSessionInvitation, object: VotingSessionInvite.self)
        
        // Set up the observer to listen for voting session result notifications
        NotificationCenter.default.addObserver(self, selector: #selector(showVotingSessionResult(_:)), name: votingSessionResult, object: VotingSessionInvite.self)
    }
    
    @objc func showNewFriendRequest(_ sender: NSNotification) {
        guard let friendRequest = sender.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentNewFriendRequestAlert(friendRequest) }
    }
    
    @objc func showFriendRequestResult(_ sender: NSNotification) {
        guard let friendRequest = sender.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentFriendRequestResponseAlert(friendRequest) }
    }
    
    @objc func showVotingSessionInvitation(_ sender: NSNotification) {
        guard let votingSessionInvite = sender.object as? VotingSessionInvite else { return }
        DispatchQueue.main.async {
            self.presentVotingSessionInvitationAlert(votingSessionInvite) { [weak self] (newVotingSession) in
                // If the user accepted the invitation, transition them to the voting session page
                if let newVotingSession = newVotingSession {
                    self?.transitionToVotingSessionPage(with: newVotingSession)
                }
            }
        }
    }
    
    @objc func showVotingSessionResult(_ sender: NSNotification) {
        guard let votingSession = sender.object as? VotingSession else { return }
        DispatchQueue.main.async { self.presentVotingSessionResultAlert(votingSession) }
    }
}
