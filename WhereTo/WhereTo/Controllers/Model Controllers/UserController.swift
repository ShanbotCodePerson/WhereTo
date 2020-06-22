//
//  UserController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

class UserController {
    
    // MARK: - Singleton
    
    static let shared = UserController()
    
    // MARK: - Source of Truth
    
    var currentUser: User?
    var friends: [User]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    
    // MARK: - CRUD Methods
    
    // Create a new user
    func newUser(with email: String, completion: @escaping (Result<Bool, WhereToError>) -> Void) {
        // TODO: - Create the user for auth?
        
        // TODO: - create a separate user object with more user data?
        let user = User(email: email, name: "")
        
        // Save the user object to the cloud and save the documentID for editing purposes
        let reference: DocumentReference = db.collection(UserStrings.recordType).addDocument(data: user.asDictionary()) { error in
            // Print and return the error
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
        }
        user.documentID = reference.documentID
        
        // Save to the source of truth and return the success
        currentUser = user
        return completion(.success(true))
    }
    
    // Read (fetch) the current user
    func fetchCurrentUser(completion: @escaping (Result<Bool, WhereToError>) -> Void) {
//        db.collection(UserStrings.recordType).whereField(<#T##field: String##String#>, isEqualTo: <#T##Any#>)
    }
    
    // Read (search for) a specific user
    
    // Read (fetch) the user's friends
    func fetchUsersFriends(completion: @escaping (Result<Bool, WhereToError>) -> Void) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        db.collection(UserStrings.recordType).whereField(UserStrings.emailKey, in: currentUser.friends).getDocuments { [weak self] (results, error) in
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
    func update(_ user: User, name: String, completion: @escaping (Result<Bool, WhereToError>) -> Void) {
        guard let documentID = user.documentID else { return completion(.failure(.noUserFound)) }
        
        // Update the user's data
        user.name = name
        
        db.collection(UserStrings.recordType).document(documentID).updateData(user.asDictionary()) { error in
            // Print and return the error
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Delete a user
}
