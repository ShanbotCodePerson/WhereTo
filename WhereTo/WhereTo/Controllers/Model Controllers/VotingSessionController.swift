//
//  VotingSessionController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

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
    func newVotingSession(with friends: [User], at coordinates: [String : Float], radius: Float, completion: @escaping resultCompletionWith<VotingSession>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // TODO: - Fetch the restaurants within the radius of the coordinates, filter by users diets and blacklistings
        
        // Create the voting session
        // FIXME: - might not need to save coordinates and radius in voting session object if not refreshing search
        // FIXME: - use actual restaurants here not empty array
        let votingSession = VotingSession(coordinates: coordinates, radius: radius, restaurantIDs: [])
        
        // Save the voting session to the cloud
        let reference: DocumentReference = db.collection(VotingSessionStrings.recordType).addDocument(data: votingSession.asDictionary()) { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
        }
        votingSession.documentID = reference.documentID
        
        // Add the reference to the voting session to the user's list of active voting sessions
        currentUser.activeVotingSessions.append(votingSession.uuid)
        
        // Save the changes to the user
        UserController.shared.saveChanges(to: currentUser) { (result) in
            switch result {
            case .success(_):
                // TODO: - figure this out
                print("not sure what to do here")
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
        
        // FIXME: - issue with threading here, figure out how to handle the multiple completions
        
        // Create and save the invitations to the voting session
        
        // Return the success
        return completion(.success(votingSession))
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
                let users = documents.compactMap({ User(dictionary: $0.data()) })
                
                // Return the success
                return completion(.success(users))
        }
    }
    
    // Respond to an invitation to a voting session
    func respond(to votingSessionInvite: VotingSessionInvite, completion: @escaping resultCompletion) {
        // TODO: - remove from source of truth
        // TODO: - delete invitation from cloud
        // TODO: - if accepted, add voting session to source of truth and to user's list, and then save user
    }
    
    // Update a voting session with votes
    func vote(number: Int, for restaurant: Restaurant, in votingSession: VotingSession, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the vote
        let vote = Vote(voteValue: number, userID: currentUser.uuid, restaurantID: restaurant.restaurantID, votingSessionID: votingSession.uuid)
        
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
                     // FIXME: - need to figure out how this works when there are multiple friend requests
                }
        }
    }
    
    // A user has responded to a invitation to a session
    func subscribeToInvitationResponseNotifications() {
        // TODO: - when an invitation referencing a voting session that the current user is in is deleted, update the user's own reference of that voting session
    }
    
    // The voting session is over and has been deleted
    func subscribeToSessionOverNotifications() {
        // TODO: - make sure to delete from user's list of active sessions and from source of truth
        // TODO: - if a conclusion was reached, add that restaurant to the history, present thing allowing user to open address in a map app
        // TODO: - need a separate method for when a conclusion has been reached? figure out about cloud functions
    }
}
