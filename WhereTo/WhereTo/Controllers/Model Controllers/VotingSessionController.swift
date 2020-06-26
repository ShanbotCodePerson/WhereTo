//
//  VotingSessionController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

class VotingSessionController {
    
    // MARK: - Singleton
    
    static let shared = VotingSessionController()
    
    // MARK: - Source of Truth
    
    var votingSessions: [VotingSession]?
    var votingSessionInvitations: [VotingSessionInvite]? // TODO: - handle this similar to friend requests
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    typealias resultCompletionWith<T> = (Result<T, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new voting session and send invites to all participants
    func newVotingSession(with friends: [User], at location: CLLocation, usingDietaryRestrictions: Bool = true, completion: @escaping resultCompletionWith<VotingSession>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the restaurants within the radius of the coordinates
        // TODO: - need to be able to end a location
       RestaurantController.shared.fetchRestaurantsByLocation(location: location) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                guard var restaurants = restaurants else { return completion(.failure(.noData)) }
                
                // Filter out restaurants that have been blacklisted by the selected users
                var allBlacklisted = currentUser.blacklistedRestaurants
                allBlacklisted.append(contentsOf: friends.map({ $0.blacklistedRestaurants }).joined())
                let blacklisted = Set(allBlacklisted)
                restaurants = restaurants.filter { !blacklisted.contains($0.restaurantID!) }
                
                // Filter the restaurants by the dietary restrictions
                if usingDietaryRestrictions {
                    
                }
                
                // Filter the restaurants by which ones are currently open
              
//                restaurants = restaurants.filter { $0.hours.openNow }

                
                // Check to see if there are any restaurants remaining
                guard restaurants.count > 0  else { return completion(.failure(.noRestaurantsMatch)) }
                
                // Calculate how many votes each user should get
                let votesEach = min(restaurants.count, max(friends.count + 1, 5))
                
                // Create the voting session
                let votingSession = VotingSession(votesEach: votesEach, restaurantIDs: restaurants.map({ $0.restaurantID! }))
                var users = friends
                users.append(currentUser)
                votingSession.users = users
                votingSession.restaurants = restaurants
                
                // Save the voting session to the cloud
                let reference: DocumentReference? = self?.db.collection(VotingSessionStrings.recordType).addDocument(data: votingSession.asDictionary()) { (error) in
                    
                    if let error = error {
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(.fsError(error)))
                    }
                }
                votingSession.documentID = reference?.documentID
                
                // Add the reference to the voting session to the user's list of active voting sessions
                currentUser.activeVotingSessions.append(votingSession.uuid)
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        // Make sure the user is subscribed to notifications related to sessions
                        self?.subscribeToInvitationResponseNotifications()
                        self?.subscribeToSessionOverNotifications()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
                
                // FIXME: - issue with threading here, figure out how to handle the multiple completions
                
                // Create the invitations to the voting session and save them to the cloud
                for friend in friends {
                    let votingSessionInvite = VotingSessionInvite(fromName: currentUser.name, toID: friend.uuid, votingSessionID: votingSession.uuid)
                    self?.db.collection(VotingSessionInviteStrings.recordType)
                        .document("\(votingSessionInvite.toID)-\(votingSessionInvite.votingSessionID)")
                        .setData(votingSessionInvite.asDictionary()) { (error) in
                            
                            if let error = error {
                                // Print and return the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                return completion(.failure(.fsError(error)))
                            }
                    }
//                    self?.db.collection(VotingSessionInviteStrings.recordType)
//                        .addDocument(data: votingSessionInvite.asDictionary()) { (error) in
//
//                            // TODO: - do I need to keep track of errors / completions here?
//                            if let error = error {
//                                // Print and return the error
//                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                                return completion(.failure(.fsError(error)))
//                            }
//                    }
                }
                
                // Return the success
                return completion(.success(votingSession))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    // TODO: - make sure to get and save docID
    
    // Read (fetch) all pending invitations to voting sessions
    func fetchPendingInvitations(completion: @escaping resultCompletionWith<[VotingSessionInvite]>) {
        // TODO: - fill this out, similar to friend requests
    }
    
    // Read (fetch) all current voting sessions
    func fetchCurrentVotingSessions(completion: @escaping resultCompletionWith<[VotingSession]>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Handle the edge case where the user is not in any active voting sessions
        if currentUser.activeVotingSessions.count == 0 {
            votingSessions = []
            return completion(.success([]))
        }
        
        // Fetch the data from the cloud
        db.collection(VotingSessionStrings.recordType)
            .whereField(VotingSessionStrings.uuidKey, in: currentUser.activeVotingSessions)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                var votingSessions: [VotingSession] = []
                for document in documents {
                    guard let votingSession = VotingSession(dictionary: document.data()) else { return completion(.failure(.couldNotUnwrap)) }
                    votingSession.documentID = document.documentID
                    votingSessions.append(votingSession)
                }
                
                // Save to the source of truth and return the success
                self?.votingSessions = votingSessions
                return completion(.success(votingSessions))
        }
    }
    
    // Read (fetch) a specific voting session
    func fetchVotingSession(with id: String, completion: @escaping resultCompletionWith<VotingSession>) {
        // Fetch the data from the cloud
        db.collection(VotingSessionStrings.recordType)
            .whereField(VotingSessionStrings.uuidKey, isEqualTo: id)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first,
                let votingSession = VotingSession(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                votingSession.documentID = document.documentID
                
                // Return the success
                return completion(.success(votingSession))
        }
    }
    
    // Read (fetch) the list of all users involved in a voting session
    func fetchUsersInVotingSession(with id: String, completion: @escaping resultCompletionWith<[User]>) {
        // Fetch the data from the cloud based on what users have the voting session's id in their list of active voting sessions
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.activeVotingSessionsKey, arrayContains: id)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let users = documents.compactMap { User(dictionary: $0.data()) }
                
                // Return the success
                return completion(.success(users))
        }
    }
    
    // Read (fetch) all the votes made by the user in a given voting session
    func fetchVotes(in votingSession: VotingSession, completion: @escaping resultCompletionWith<[Vote]>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(VoteStrings.recordType)
            .whereField(VoteStrings.votingSessionIDKey, isEqualTo: votingSession.uuid)
            .whereField(VoteStrings.userIDKey, isEqualTo: currentUser.uuid)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let votes = documents.compactMap { Vote(dictionary: $0.data()) }
                
                // Return the success
                return completion(.success(votes))
        }
    }
    
    // Respond to an invitation to a voting session
    func respond(to votingSessionInvite: VotingSessionInvite, accept: Bool, completion: @escaping resultCompletionWith<VotingSession>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        // FIXME: - nested completions, need to figure out threading, when to return, when to post notification
        if accept {
            // Make sure the user is subscribed to notifications related to sessions
            subscribeToInvitationResponseNotifications()
            subscribeToSessionOverNotifications()
            
            // Add the voting session to the user's list of active voting sessions
            currentUser.activeVotingSessions.append(votingSessionInvite.votingSessionID)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Fetch the voting session object
                    self?.fetchVotingSession(with: votingSessionInvite.votingSessionID) { (result) in
                        switch result {
                        case .success(let votingSession):
                            // Save the voting session to the source of truth
                            if var votingSessions = self?.votingSessions {
                                votingSessions.append(votingSession)
                                self?.votingSessions = votingSessions
                            } else {
                                self?.votingSessions = [votingSession]
                            }
                            // Return the success
                            return completion(.success(votingSession))
                        case .failure(let error):
                            // Print and return the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
        
        // FIXME: - need to make sure this is getting called somewhere
        
        // Delete the invitation from the cloud now that it's no longer necessary
        db.collection(VotingSessionInviteStrings.recordType)
            .document("\(votingSessionInvite.toID)-\(votingSessionInvite.votingSessionID)")
            .delete() { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
        }
    }
    
    // Update a voting session with votes
    func vote(number: Int, for restaurant: Restaurant, in votingSession: VotingSession, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the vote
        let vote = Vote(voteValue: number, userID: currentUser.uuid, restaurantID: restaurant.restaurantID!, votingSessionID: votingSession.uuid)
        
        // Save the vote to the cloud
        db.collection(VoteStrings.recordType)
            .addDocument(data: vote.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Leave a voting session early
    func leave(_ votingSession: VotingSession, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Remove the voting session from the user's list of voting sessions
        currentUser.activeVotingSessions.removeAll(where: { $0 == votingSession.uuid })
        
        // Save the changes to the user
        UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
            switch result {
            case .success(_):
                // Check to see if the user had been the last participant in the voting session, and if so, delete the voting session
                if votingSession.users?.count == 1 {
                    self?.delete(votingSession, completion: { (result) in
                        // TODO: - fill this out
                    })
                }
                
                // Remove the voting session from the source of truth
                self?.votingSessions?.removeAll(where: { $0.uuid == votingSession.uuid })
                
                // Alert the others participating in the voting session of the change?
                // TODO: - implement this
                
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Delete a voting session when it's no longer needed
    func delete(_ votingSession: VotingSession, completion: @escaping resultCompletion) {
        guard let documentID = votingSession.documentID else { return completion(.failure(.documentNotFound))}
        
        // Delete the data from the cloud
        db.collection(VotingSessionStrings.recordType)
            .document(documentID)
            .delete() { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Get all the votes related to the voting session
                self?.db.collection(VoteStrings.recordType)
                    .whereField(VoteStrings.votingSessionIDKey, isEqualTo: votingSession.uuid)
                    .getDocuments { (results, error) in
                        
                        if let error = error {
                            // Print and return the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return completion(.failure(.fsError(error)))
                        }
                        
                        // Unwrap the data
                        guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                        
                        // Delete each of the votes
                        // TODO: - handle threading here, handle errors?
                        documents.forEach {
                            self?.db.collection(VoteStrings.recordType).document($0.documentID).delete()
                        }
                        
                        // Return the success
                        return completion(.success(true))
                }
        }
    }
    // TODO: - make sure to also remove from users list of active sessions
    
    // MARK: - Set Up Notifications
    
    // The current user has been invited to a voting session
    func subscribeToInvitationNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of any invitations to voting sessions with the current user as the recipient
        db.collection(VotingSessionInviteStrings.recordType)
            .whereField(VotingSessionInviteStrings.toIDKey, isEqualTo: currentUser.uuid)
            .addSnapshotListener { (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let newInvitations = documents.compactMap { VotingSessionInvite(dictionary: $0.data()) }
                
                // TODO: - add to source of truth?
                
                // Send a local notification to present an alert for each invitation
                for invitation in newInvitations {
                    NotificationCenter.default.post(name: newVotingSessionInvitation, object: invitation)
                    // FIXME: - need to figure out how this works when there are multiple invitations
                }
        }
    }
    
    // A user has responded to a invitation to a session
    func subscribeToInvitationResponseNotifications() {
        guard let currentUser = UserController.shared.currentUser,
            currentUser.activeVotingSessions.count > 0
            else { return }
        
        // Set up a listener to be alerted whenever someone responds to an invitation for a voting session the user is in
        db.collection(VotingSessionInviteStrings.recordType)
            .whereField(VotingSessionInviteStrings.votingSessionIDKey, in: currentUser.activeVotingSessions)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let snapshot = snapshot else { return }
                
                // Only pay attention to when the invitation is deleted
                snapshot.documentChanges.forEach({ (change) in
                    if change.type == .removed {
                        // Update the list of users referenced in the relevant voting session
                        let votingSessionInvite = VotingSessionInvite(dictionary: change.document.data())
                        guard let votingSession = self?.votingSessions?.first(where: { $0.uuid == votingSessionInvite?.votingSessionID }) else { return }
                        self?.fetchUsersInVotingSession(with: votingSession.uuid, completion: { (result) in
                            switch result {
                            case .success(let users):
                                votingSession.users = users
                            case .failure(let error):
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            }
                        })
                    }
                })
        }
    }
    
    // The voting session is over and has been deleted
    func subscribeToSessionOverNotifications() {
        guard let currentUser = UserController.shared.currentUser,
            currentUser.activeVotingSessions.count > 0
            else { return }
        
        // Set up a listener on all voting sessions the user is currently involved in
        db.collection(VotingSessionStrings.recordType)
            .whereField(VotingSessionStrings.uuidKey, in: currentUser.activeVotingSessions)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Only pay attention to when the invitation is deleted
                snapshot?.documentChanges.forEach({ (change) in
                    if change.type == .removed {
                        // If there was an outcome, add that restaurant the user's list of previous restaurants
                        let votingSession = VotingSession(dictionary: change.document.data())
                        if let outcome = votingSession?.outcomeID {
                            currentUser.previousRestaurants.append(outcome)
                            
                            // TODO: - send a notification to update the previous restaurants table view, present alert with results and allowing user to open in map app
                        }
                        
                        // Remove the voting session from the source of truth
                        self?.votingSessions?.removeAll(where: { $0.uuid == votingSession?.uuid })
                        
                        // Remove the voting session from the user's list of active sessions
                        currentUser.activeVotingSessions.removeAll(where: { $0 == votingSession?.uuid })
                        
                        // Save the changes to the user
                        UserController.shared.saveChanges(to: currentUser) { (result) in
                            switch result {
                            case .success(_):
                                // TODO: - fill this out better
                                print("Saved")
                            case .failure(let error):
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            }
                        }
                    }
                })
                
                
        }
    }
}
