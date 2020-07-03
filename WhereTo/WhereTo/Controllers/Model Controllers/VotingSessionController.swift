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
    func newVotingSession(with friends: [User], at location: CLLocation, filterByDiet: Bool, completion: @escaping resultCompletionWith<VotingSession>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Filter the restaurants by the dietary restrictions
        var dietaryRestrictions: [String] = []
        if filterByDiet {
            var allDietaryRestrictions = currentUser.dietaryRestrictions
            allDietaryRestrictions.append(contentsOf: friends.map({ $0.dietaryRestrictions }).joined())
            dietaryRestrictions = Array(Set(allDietaryRestrictions.map({ $0.rawValue })))
        }
        
        // Fetch the restaurants within the radius of the coordinates
        // TODO: - need to be able to end a location
        RestaurantController.shared.fetchRestaurantsByLocation(location: location, searchByIsOpen: true, dietaryRestrictions: dietaryRestrictions) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                guard var restaurants = restaurants else { return completion(.failure(.noData)) }
                
                // Filter out restaurants that have been blacklisted by the selected users
                var allBlacklisted = currentUser.blacklistedRestaurants
                allBlacklisted.append(contentsOf: friends.map({ $0.blacklistedRestaurants }).joined())
                let blacklisted = Set(allBlacklisted)
                restaurants = restaurants.filter { !blacklisted.contains($0.restaurantID) }
                
                // Check to see if there are any restaurants remaining
                guard restaurants.count > 0  else { return completion(.failure(.noRestaurantsMatch)) }
                
                // Sort the restaurants, first by highest to lowest rating, then alphabetically
                restaurants = restaurants.sorted(by: { (restaurant0, restaurant1) -> Bool in
                    if let rating0 = restaurant0.rating, let rating1 = restaurant1.rating {
                        if rating0 == rating1 { return restaurant1.name > restaurant0.name }
                        return rating1 > rating0
                    }
                    return restaurant1.name > restaurant0.name
                })
                
                // Calculate how many votes each user should get
                var users = friends
                users.append(currentUser)
                let votesEach = min(restaurants.count, users.count + 1, 5)
                
                // Create the voting session
                let votingSession = VotingSession(votesEach: votesEach, dietaryRestrictions: dietaryRestrictions, location: location, restaurantIDs: restaurants.map({ $0.restaurantID }))
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
                
                // Save the restaurants to the cloud
                restaurants.forEach { RestaurantController.shared.save($0, completion: { (_) in })  }
                
                // Add the reference to the voting session to the user's list of active voting sessions
                currentUser.activeVotingSessions.uniqueAppend(votingSession.uuid)
                
                // Add the voting session to the source of truth
                if var votingSessions = self?.votingSessions {
                    if !votingSessions.contains(votingSession) {
                        votingSessions.append(votingSession)
                        self?.votingSessions = votingSessions
                    }
                } else {
                    self?.votingSessions = [votingSession]
                }
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        // Make sure the user is subscribed to notifications related to sessions
                        self?.subscribeToInvitationResponseNotifications()
//                        self?.subscribeToSessionOverNotifications()
                        self?.subscribeToVoteNotifications()
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
    
    // Read (fetch) all pending invitations to voting sessions
    func fetchPendingInvitations(completion: @escaping resultCompletionWith<[VotingSessionInvite]>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(VotingSessionInviteStrings.recordType)
            .whereField(VotingSessionInviteStrings.toIDKey, isEqualTo: currentUser.uuid)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let pendingInvitations = documents.compactMap { (document) -> VotingSessionInvite? in
                    guard let votingSessionInvite = VotingSessionInvite(dictionary: document.data()) else { return nil }
                    votingSessionInvite.documentID = document.documentID
                    return votingSessionInvite
                }
                
                // Return the success
                return completion(.success(pendingInvitations))
        }
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
                    
                    // FIXME: - check to see if all votes have been cast?
                    
                    // If the voting session is over, handle that
                    if votingSession.outcomeID != nil {
                        self?.handleFinishedSession(votingSession)
                    } else {
                        // Otherwise, add it to the source of truth
                        votingSessions.append(votingSession)
                    }
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
                guard let document = results?.documents.first else { return completion(.failure(.couldNotUnwrap)) }
                
                _ = VotingSession.init(dictionary: document.data()) { (votingSession) in
                    guard let votingSession = votingSession else { return completion(.failure(.couldNotUnwrap)) }
                    
                    votingSession.documentID = document.documentID
                    
                    // Return the success
                    return completion(.success(votingSession))
                }
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
        // Fetch the data from the cloud
        db.collection(VoteStrings.recordType)
            .whereField(VoteStrings.votingSessionIDKey, isEqualTo: votingSession.uuid)
//            .whereField(VoteStrings.userIDKey, isEqualTo: currentUser.uuid)
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
            // Add the voting session to the user's list of active voting sessions
            currentUser.activeVotingSessions.append(votingSessionInvite.votingSessionID)
            
            // Make sure the user is subscribed to notifications related to sessions
            subscribeToInvitationResponseNotifications()
//            subscribeToSessionOverNotifications()
            subscribeToVoteNotifications()
            
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
        guard let documentID = votingSessionInvite.documentID else { return completion(.failure(.noData)) }
        db.collection(VotingSessionInviteStrings.recordType)
            .document(documentID)
            .delete() { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
        }
    }
    
    // Update a voting session with an outcome
    func saveOutcome(of votingSession: VotingSession, outcomeID: String) {
        guard let documentID = votingSession.documentID else { return }
        
        // Add the outcome to the voting session
        votingSession.outcomeID = outcomeID
        
        // Save the change to the cloud
        db.collection(VotingSessionStrings.recordType)
            .document(documentID)
            .setData(votingSession.asDictionary()) { (error) in
                
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                }
        }
    }
    
    // Update a voting session with votes
    func vote(value: Int, for restaurant: Restaurant, in votingSession: VotingSession, completion: @escaping resultCompletionWith<Vote>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // FIXME: - check to see if it's the last vote?
        
        // Create the vote
        let vote = Vote(voteValue: value, userID: currentUser.uuid, restaurantID: restaurant.restaurantID, votingSessionID: votingSession.uuid)
        
        // Save the vote to the cloud
        db.collection(VoteStrings.recordType)
            .addDocument(data: vote.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Return the success
                return completion(.success(vote))
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
    
    // Delete all votes associated with the current user
    func deleteAllVotes(completion: @escaping (WhereToError?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.noUserFound) }
        
        // Fetch all the user's active votes from the cloud
        db.collection(VoteStrings.recordType)
            .whereField(VoteStrings.userIDKey, isEqualTo: currentUser.uuid)
            .getDocuments(completion: { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.fsError(error))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.couldNotUnwrap) }
                
                // Delete all the votes
                documents.forEach { self?.db.collection(VoteStrings.recordType).document($0.documentID).delete() }
                
                return completion(nil)
            })
    }
    
    // Delete all voting session invitations associated with the current user
    func deleteAllVotingInvites(completion: @escaping (WhereToError?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.noUserFound) }
        
        // Fetch all the user's outstanding voting session invitations from the cloud
        db.collection(VotingSessionInviteStrings.recordType)
            .whereField(VotingSessionInviteStrings.toIDKey, isEqualTo: currentUser.uuid)
            .getDocuments(completion: { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.fsError(error))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.couldNotUnwrap) }
                
                // Delete all the voting invitations
                documents.forEach {
                    self?.db.collection(VotingSessionInviteStrings.recordType).document($0.documentID).delete()
                }
                
                return completion(nil)
            })
    }
    
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
                let newInvitations = documents.compactMap { (document) -> VotingSessionInvite? in
                    guard let votingSessionInvite = VotingSessionInvite(dictionary: document.data()) else { return nil }
                    votingSessionInvite.documentID = document.documentID
                    return votingSessionInvite
                }
                
                // Send a local notification to present an alert for each invitation
                for invitation in newInvitations {
                    NotificationCenter.default.post(Notification(name: newVotingSessionInvitation, object: invitation))
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
    
    // A vote has been submitted
    func subscribeToVoteNotifications() {
        // Set up a listener on all votes referencing voting sessions the user is currently involved in
        guard let currentUser = UserController.shared.currentUser,
            currentUser.activeVotingSessions.count > 0
            else { return }
        
        db.collection(VoteStrings.recordType)
            .whereField(VoteStrings.votingSessionIDKey, in: currentUser.activeVotingSessions)
            .addSnapshotListener { [weak self] (snapshots, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let snapshots = snapshots else { return }
                let votes = snapshots.documents.compactMap { Vote(dictionary: $0.data()) }
                let votingSessionIDs = Set(votes.map({ $0.votingSessionID }))
                
                votingSessionIDs.forEach { (votingSessionID) in
                    // Do not try to calculate an outcome if there are still outstanding invitations to the voting session
                    self?.db.collection(VotingSessionInviteStrings.recordType)
                        .whereField(VotingSessionInviteStrings.votingSessionIDKey, isEqualTo: votingSessionID)
                        .getDocuments { (results, error) in
                            
                            if let error = error {
                                // Print and return the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                return
                            }
                            
                            // Only move forward if there are not any outstanding invitations
                            guard results?.documents.count == 0 else { return }
                            
                            // Get the voting session
                            self?.fetchVotingSession(with: votingSessionID, completion: { (result) in
                                switch result {
                                case .success(let votingSession):
                                    self?.calculateOutcome(of: votingSession)
                                case .failure(let error):
                                    // Print and return the error
                                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                    return
                                }
                            })
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    // A helper function to calculate the outcome of a voting session
    func calculateOutcome(of votingSession: VotingSession) {
        
        // Check to see if the voting session already has an outcome
        if votingSession.outcomeID != nil {
            handleFinishedSession(votingSession)
        }
        
        // Fetch all the votes associated with the voting session
        fetchVotes(in: votingSession) { [weak self] (result) in
            switch result {
            case .success(let votes):
                // Calculate the number of votes needed to reach an outcome
                guard let numberOfUsers = votingSession.users?.count else { return }
                let necessaryNumberOfVotes = votingSession.votesEach * numberOfUsers
                
                // Compare the number of votes submitted to the number of votes needed
                guard votes.count == necessaryNumberOfVotes else { return }
                
                // Create a data structure linking restaurants with their votes
                var results: [String : (numberOfVotes: Int, valueOfVotes: Int)] = [:]
                for vote in votes {
                    if var existingEntry = results[vote.restaurantID] {
                        existingEntry.numberOfVotes += 1
                        existingEntry.valueOfVotes += vote.voteValue
                        results[vote.restaurantID] = existingEntry
                    } else {
                        results[vote.restaurantID] = (numberOfVotes: 1, valueOfVotes: vote.voteValue)
                    }
                }
                
                // First try to get the restaurant with the most number of votes
                let mostVotes = results.values.map({ $0.numberOfVotes }).max(by: { $1 > $0 })
                var winningRestaurant = results.filter { (element) -> Bool in
                    element.value.numberOfVotes == mostVotes
                }
                if winningRestaurant.count == 1 {
                    guard let outcomeID = winningRestaurant.keys.first else { return }
                    
                    // Save the changes to the voting session
                    self?.saveOutcome(of: votingSession, outcomeID: outcomeID)
                    
                    // Handle the finish
                    self?.handleFinishedSession(votingSession)
                } else {
                    // In case of a tie, use the restaurant with the higher value of votes
                    let highestVoteValue = winningRestaurant.values.map({ $0.valueOfVotes }).max(by: { $1 > $0 })
                    winningRestaurant = winningRestaurant.filter({ (element) -> Bool in
                        element.value.valueOfVotes == highestVoteValue
                    })
                    
                    if winningRestaurant.count == 1 {
                        guard let outcomeID = winningRestaurant.keys.first else { return }
                        
                        // Save the changes to the voting session
                        self?.saveOutcome(of: votingSession, outcomeID: outcomeID)
                        
                        // Handle the finish
                        self?.handleFinishedSession(votingSession)
                    } else {
                        // If that is still a tie, choose based on alphabetical order
                        guard let outcomeID = winningRestaurant.keys.sorted().first else { return }
                        
                        // Save the changes to the voting session
                        self?.saveOutcome(of: votingSession, outcomeID: outcomeID)
                        
                        // Handle the finish
                        self?.handleFinishedSession(votingSession)
                    }
                }
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    // A helper function to handle a finished voting session
    func handleFinishedSession(_ votingSession: VotingSession) {
        guard let currentUser = UserController.shared.currentUser,
            let outcomeID = votingSession.outcomeID
            else { return }
        
        // Add the outcome to the user's list of previous restaurants (making sure to avoid duplicates)
        currentUser.previousRestaurants.uniqueAppend(outcomeID)
        
        
        // Add the restaurant to the source of truth (making sure to avoid duplicates)
        guard let restaurant = votingSession.restaurants?.first(where: { $0.restaurantID == outcomeID }) else { return }
        RestaurantController.shared.previousRestaurants?.uniqueAppend(restaurant)
        
        // Save the restaurant to the cloud
        RestaurantController.shared.save(restaurant) { (_) in }
        
        // Remove the voting session from the source of truth
        votingSessions?.removeAll(where: { $0 == votingSession })
        
        // Send notifications to update the views and present an alert with the result
        NotificationCenter.default.post(Notification(name: updateHistoryList))
        NotificationCenter.default.post(Notification(name: updateActiveSessionsButton))
        NotificationCenter.default.post(name: votingSessionResult, object: votingSession)
        
        // Remove the voting session from the user's list of active voting sessions
        currentUser.activeVotingSessions.removeAll(where: { $0 == votingSession.uuid })
        
        // Save the changes to the user
        UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
            switch result {
            case .success(_):
                // Display an alert with the outcome of the voting session
                NotificationCenter.default.post(name: votingSessionResult, object: votingSession)
                
                // If there are no more users referencing this voting session, then delete it from the cloud
                self?.db.collection(UserStrings.recordType)
                    .whereField(UserStrings.activeVotingSessionsKey, arrayContains: votingSession.uuid)
                    .getDocuments(completion: { (results, error) in
                        
                        if let error = error {
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return
                        }
                        
                        if results?.documents.count == 0 {
                            self?.delete(votingSession, completion: { (result) in
                                switch result {
                                case .success(_):
                                    return
                                case .failure(let error):
                                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                    return
                                }
                            })
                        }
                    })
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return
            }
        }
    }
}
