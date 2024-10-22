//
//  UserController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class UserController {
    
    // MARK: - Singleton
    
    static let shared = UserController()
    
    // MARK: - Source of Truth
    
    var currentUser: User?
    var friends: [User]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    typealias resultCompletionWith<T> = (Result<T, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new user
    func newUser(with email: String, name: String?, completion: @escaping resultCompletion) {
        let user = User(email: email, name: (name ?? email.components(separatedBy: "@").first) ?? email)
        
        // Save the user object to the cloud and save the documentID for editing purposes
        let reference: DocumentReference = db.collection(UserStrings.recordType).addDocument(data: user.asDictionary()) { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
        }
        // FIXME: - threading issue here, but need reference outside
        user.documentID = reference.documentID
        
        // Save to the source of truth and return the success
        currentUser = user
        setUpUser()
        return completion(.success(true))
    }
    
    // Read (fetch) the current user
    func fetchCurrentUser(completion: @escaping resultCompletion) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return completion(.failure(.noUserFound)) }
        
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.emailKey, isEqualTo: email)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents,
                    documents.count > 0
                    else { return completion(.failure(.noUserFound)) }
                guard let document = documents.first else { return completion(.failure(.couldNotUnwrap)) }
                let currentUser = User(dictionary: document.data())
                currentUser?.documentID = document.documentID
                
                // Save to the source of truth and return the success
                self?.currentUser = currentUser
                self?.setUpUser()
                return completion(.success(true))
        }
    }
    
    // Read (fetch) a user's profile photo
    func fetchUsersProfilePhoto(user: User, completion: @escaping (UIImage) -> Void) {
        // If the user doesn't have a photo, use the default one
        guard let profilePhotoURL = user.profilePhotoURL else { return completion(#imageLiteral(resourceName: "default_profile_picture")) }
        
        // Get the reference to the profile photo
        let photoRef = storage.reference().child(profilePhotoURL)
        
        // Download the photo from the cloud
        photoRef.getData(maxSize: Int64(1.2 * 1024 * 1024)) { (data, error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(#imageLiteral(resourceName: "default_profile_picture"))
            }
            
            // Convert the data to an image and return it
            guard let data = data,
                let photo = UIImage(data: data)
                else { return completion(#imageLiteral(resourceName: "default_profile_picture")) }
            return completion(photo)
        }
    }
    
    // Read (search for) a specific user
    func searchFor(email: String, completion: @escaping resultCompletionWith<User>) {
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.emailKey, isEqualTo: email)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first
                    else { return completion(.failure(.noSuchUser))}
                guard let friend = User(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                
                // Return the success
                return completion(.success(friend))
        }
    }
    
    // Read (fetch) the user's friends
    func fetchUsersFriends(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Handle the edge case where the user has no friends
        if currentUser.friends.count == 0 {
            self.friends = []
            return completion(.success(true))
        }
        
        // If the user has more than 10 friends, the fetch needs to be broken up otherwise it will overwhelm Firebase
        if currentUser.friends.count > 10 {
            // Initialize the result
            var allFriends: [User] = []
            let group = DispatchGroup()
            
            // Break the data up into groups of ten or fewer
            let rounds = Int(Double(currentUser.friends.count / 10).rounded(.up))
            for round in 0..<rounds {
                // Get the subsection of friends to search for
                let subsection = Array(currentUser.friends[(round * 10)..<min(((round + 1) * 10), currentUser.friends.count)])
                
                group.enter()
                fetchFriendsByIDs(subsection) { (result) in
                    switch result {
                    case .success(let friends):
                        // Add the friends to the total result
                        allFriends.append(contentsOf: friends)
                        group.leave()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
            }
            // Save to the source of truth and return the success
            group.notify(queue: .main) {
                self.friends = allFriends
                return completion(.success(true))
            }
        } else {
            fetchFriendsByIDs(currentUser.friends) { [weak self] (result) in
                switch result {
                case .success(let friends):
                    // Save to the source of truth and return the success
                    self?.friends = friends
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // A helper function to search for friends by their IDs
    private func fetchFriendsByIDs(_ friendsIDS: [String], completion: @escaping resultCompletionWith<[User]>) {
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.uuidKey, in: friendsIDS)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let friends = documents.compactMap({ User(dictionary: $0.data()) })
                
                // Return the success
                return completion(.success(friends))
        }
    }
    
    // Update a user
    func saveChanges(to user: User, completion: @escaping resultCompletion) {
        guard let documentID = user.documentID else { return completion(.failure(.noUserFound)) }
        
        // Update the data in the cloud
        db.collection(UserStrings.recordType)
            .document(documentID)
            .updateData(user.asDictionary()) { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Update the source of truth
                self?.currentUser = user
                
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Update a user with a new profile photo
    func savePhotoToCloud(_ photo: UIImage, completion: @escaping resultCompletion) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Convert the image to data
        guard let data = photo.compressTo(1) else { return completion(.failure(.badPhotoFile)) }
        
        // Create a name for the file in the cloud using the user's id
        let photoRef = storage.reference().child("images/\(currentUser.uuid).jpg")
            
        // Save the data to the cloud
        photoRef.putData(data, metadata: nil) { [weak self] (metadata, error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
            
            // Save the link to the profile picture
            currentUser.profilePhotoURL = "images/\(currentUser.uuid).jpg"
            currentUser.photo = photo
            self?.saveChanges(to: currentUser, completion: { (result) in
                switch result {
                case .success(_):
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            })
        }
    }
    
    // Delete a user
    func deleteCurrentUser(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser, let documentID = currentUser.documentID
            else { return completion(.failure(.noUserFound)) }
        
        let group = DispatchGroup()
        
        // If the user had a profile photo, delete that
        if let profilePhotoURL = currentUser.profilePhotoURL {
            group.enter()
            UserController.shared.deleteProfilePhoto(with: profilePhotoURL) { (error) in
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                group.leave()
            }
        }
        
        // Remove all friends
        for friend in friends ?? [] {
            group.enter()
            FriendRequestController.shared.sendRequestToRemove(friend, userBeingDeleted: true) { (result) in
                switch result {
                case .success(_):
                    print("successfully removed friend")
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
                group.leave()
            }
        }
        
        // Delete all outstanding friend requests sent to or from the current user
        group.enter()
        FriendRequestController.shared.deleteAll { (error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
            group.leave()
        }
        
        // Delete all the user's votes
        group.enter()
        VotingSessionController.shared.deleteAllVotes { (error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
            group.leave()
        }
        
        // Delete all voting invitations sent to or from the current user
        group.enter()
        VotingSessionController.shared.deleteAllVotingInvites { (error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
            group.leave()
        }
        
        // Delete the data from the cloud
        group.notify(queue: .main) {
            self.db.collection(UserStrings.recordType)
                .document(documentID)
                .delete() { (error) in
                    
                    if let error = error {
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(.fsError(error)))
                    }
                    
                    // Return the success
                    return completion(.success(true))
            }
        }
    }
    
    // Delete a user's profile photo
    func deleteProfilePhoto(with url: String, completion: @escaping (Error?) -> Void) {
        // Get the reference to the photo
        let photoRef = storage.reference().child(url)
        
        // Delete the photo from the cloud
        photoRef.delete { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(error)
            }
            
            return completion(nil)
        }
    }
    
    // MARK: - Helper Methods
    
    func setUpUser() {
        FriendRequestController.shared.subscribeToFriendRequestNotifications()
        FriendRequestController.shared.subscribeToFriendRequestResponseNotifications()
        FriendRequestController.shared.subscribeToRemovingFriendNotifications()
        
        VotingSessionController.shared.subscribeToInvitationNotifications()
        VotingSessionController.shared.subscribeToInvitationResponseNotifications()
        VotingSessionController.shared.subscribeToVoteNotifications()
    }
}
