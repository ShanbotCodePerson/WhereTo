//
//  UserController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class UserController {
    
    // MARK: - Singleton
    
    static let shared = UserController()
    
    // MARK: - Source of Truth
    
    var currentUser: User?
    var friends: [User]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new user
    func newUser(with email: String, completion: @escaping resultCompletion) {
        let user = User(email: email, name: "")
        
        // Save the user object to the cloud and save the documentID for editing purposes
        let reference: DocumentReference = db.collection(UserStrings.recordType).addDocument(data: user.asDictionary()) { error in
            
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
        return completion(.success(true))
    }
    
    // Read (fetch) the current user
    func fetchCurrentUser(completion: @escaping resultCompletion) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.emailKey, isEqualTo: email)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first else { return completion(.failure(.couldNotUnwrap)) }
                let currentUser = User(dictionary: document.data())
                
                // Save to the source of truth and return the success
                self?.currentUser = currentUser
                return completion(.success(true))
        }
    }
    
    // Read (search for) a specific user
    
    // Read (fetch) the user's friends
    func fetchUsersFriends(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.uuidKey, in: currentUser.friends)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let friends = documents.compactMap({ User(dictionary: $0.data()) })
                
                // Save to the source of truth and return the success
                self?.friends = friends
                return completion(.success(true))
        }
    }
    
    // Update a user
    func saveChanges(to user: User, completion: @escaping resultCompletion) {
        guard let documentID = user.documentID else { return completion(.failure(.noUserFound)) }
        
        // Update the data in the cloud
        db.collection(UserStrings.recordType)
            .document(documentID)
            .updateData(user.asDictionary()) { [weak self] error in
                
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
    
    // Delete a user
    func deleteCurrentUser(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser, let documentID = currentUser.documentID
            else { return completion(.failure(.noUserFound)) }
        
        // Delete the data from the cloud
        db.collection(UserStrings.recordType)
            .document(documentID)
            .delete() { error in
                
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
