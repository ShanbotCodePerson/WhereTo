//
//  FriendRequestController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class FriendRequestController {
    
    // MARK: - Singleton
    
    static let shared = FriendRequestController()
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    typealias resultCompletionWithObjects = (Result<[FriendRequest], WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new friend request
    func sendFriendRequest(to user: User, addingFriend: Bool = true, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create a new friend request
        let friendRequest = FriendRequest(fromID: currentUser.uuid, fromName: currentUser.name, toID: user.uuid, toName: user.name, status: (addingFriend ? .waiting : .removingFriend))
        
        // Save it to the cloud
        db.collection(FriendRequestStrings.recordType)
            .addDocument(data: friendRequest.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Create a request to remove a friend
    func sendRequestToRemove(_ user: User, userBeingDeleted: Bool = false, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Remove the friend from the user's list of friends
        currentUser.friends.removeAll(where: { $0 == user.uuid })
        
        // Remove the friend from the source of truth
        UserController.shared.friends?.removeAll(where: { $0.uuid == user.uuid })
        
        // Don't try to save the changes to the user if this is part of deleting the user
        if userBeingDeleted { return completion(.success(true)) }
        
        // Save the changes to the user
        UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
            switch result {
            case .success(_):
                // Send the notification to the unfriended user
                self?.sendFriendRequest(to: user, addingFriend: false, completion: completion)
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) all pending friend requests
    func fetchPendingRequests(completion: @escaping resultCompletionWithObjects) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.uuid)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.waiting.rawValue)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let pendingFriendRequests = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                // Return the success
                return completion(.success(pendingFriendRequests))
        }
    }
    
    // Update a friend request with a response
    func respondToFriendRequest(_ friendRequest: FriendRequest, accept: Bool, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        guard let documentID = friendRequest.documentID else { return completion(.failure(.noData)) }
        
        // Update the friend request
        friendRequest.status = accept ? .accepted : .denied
        
        // If the user accepted the friend request, add and save the friend
        if accept {
            currentUser.friends.append(friendRequest.fromID)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { (result) in
                switch result {
                case .success(_):
                    // Update the source of truth
                    UserController.shared.fetchUsersFriends { (result) in
                        switch result {
                        case .success(_):
                            // Send a local notification to update the tableview as necessary
                            NotificationCenter.default.post(Notification(name: updateFriendsList))
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
        
        // Save the changes to the friend request
        db.collection(FriendRequestStrings.recordType)
            .document(documentID)
            .updateData([FriendRequestStrings.statusKey : friendRequest.status.rawValue]) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Otherwise return the success
                return completion(.success(true))
        }
    }
    
    // Delete a friend request when it's no longer needed
    func delete(_ friendRequest: FriendRequest, completion: @escaping resultCompletion) {
        guard let documentID = friendRequest.documentID else { return completion(.failure(.noData)) }
        
        // Delete the friend request from the cloud
        db.collection(FriendRequestStrings.recordType)
            .document(documentID)
            .delete() { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                    // Otherwise return the success
                else { return completion(.success(true)) }
        }
    }
    
    // Delete friend requests associated with the current user
    func deleteAll(completion: @escaping (WhereToError?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.noUserFound) }
        
        let group = DispatchGroup()
        
        // Fetch all outstanding friend requests sent by the user
        group.enter()
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.fromIDKey, isEqualTo: currentUser.uuid)
            .whereField(FriendRequestStrings.statusKey, isLessThan: FriendRequest.Status.removingFriend.rawValue)
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
                    self?.db.collection(FriendRequestStrings.recordType).document($0.documentID).delete()
                }
                
                group.leave()
            })
        
        // Fetch all outstanding friend requests sent to the user
        group.enter()
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.uuid)
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
                    self?.db.collection(FriendRequestStrings.recordType).document($0.documentID).delete()
                }
                
                group.leave()
            })
        
        group.notify(queue: .main) { return completion(nil) }
    }
    
    // MARK: - Set Up Notifications
    
    func subscribeToFriendRequestNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of any adding-type friend requests with the current user as the recipient
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.uuid)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.waiting.rawValue)
            .addSnapshotListener { (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let newFriendRequests = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                for friendRequest in newFriendRequests {
                    // Send a local notification to present an alert
                    NotificationCenter.default.post(name: newFriendRequest, object: friendRequest)
                    // FIXME: - need to figure out how this works when there are multiple friend requests
                }
        }
    }
    
    func subscribeToFriendRequestResponseNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of changes to friend requests with the current user as the sender
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.fromIDKey, isEqualTo: currentUser.uuid)
            .whereField(FriendRequestStrings.statusKey, in: [FriendRequest.Status.accepted.rawValue, FriendRequest.Status.denied.rawValue])
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let newResponses = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                // If the request was accepted, add the friends to the user's list of friends
                currentUser.friends.append(contentsOf: newResponses.filter({ $0.status == .accepted }).map({ $0.toID }))
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        for response in newResponses {
                            // Update the source of truth
                            UserController.shared.fetchUsersFriends { (result) in
                                switch result {
                                case .success(_):
                                    // Send local notifications to show an alert and update the tableview as necessary
                                    NotificationCenter.default.post(name: responseToFriendRequest, object: response)
                                    NotificationCenter.default.post(Notification(name: updateFriendsList))
                                case .failure(let error):
                                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                }
                            }
                            // Delete the requests from the cloud now that they're no longer necessary
                            self?.delete(response, completion: { (_) in })
                        }
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
        }
    }
    
    // When someone removes the current user as a friend
    func subscribeToRemovingFriendNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of any removing-type friend requests with the current user as the recipient
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.uuid)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.removingFriend.rawValue)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let friendsRemoving = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                let friendsIDs = friendsRemoving.compactMap { $0.fromID }
                
                // Remove the friends from the users list of friends
                currentUser.friends.removeAll(where: { friendsIDs.contains($0) })
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        // Update the source of truth
                        UserController.shared.friends?.removeAll(where: { friendsIDs.contains($0.uuid) })
                        
                        // Send a local notification to update the tableview
                        NotificationCenter.default.post(Notification(name: updateFriendsList))
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
                
                // Delete the requests from the cloud now that they're no longer necessary
                friendsRemoving.forEach({ self?.delete($0, completion: { (_) in }) })
        }
    }
}
