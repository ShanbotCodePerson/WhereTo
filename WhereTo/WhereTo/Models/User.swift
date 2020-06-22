//
//  User.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct UserStrings {
    static let recordType = "user"
    static let emailKey = "email"
    static let nameKey = "name"
    static let friendsKey = "friends"
    static let uuidKey = "uuid"
}

class User {
    
    // MARK: - Properties
    
    let email: String
    var name: String
    var documentID: String?
//    var profilePhoto:
//    var dietaryRestrictions: []
    var friends: [String]
//    var blockedUsers:
//    var favoriteRestaurants:
//    var blacklistedRestaurants:
//    var previousRestaurants:
    let uuid: String
    
    // MARK: - Initializers
    
    init(email: String, name: String, friends: [String]? = nil, documentID: String? = nil, uuid: String = UUID().uuidString) {
        self.email = email
        self.name = name
        self.friends = friends ?? []
        self.documentID = documentID
        self.uuid = uuid
    }
    
    // MARK: - Init from Dictionary
    
    convenience init?(dictionary: [String: Any]) {
        guard let email = dictionary[UserStrings.emailKey] as? String,
            let name = dictionary[UserStrings.nameKey] as? String,
            let friends = dictionary[UserStrings.friendsKey] as? [String],
            let uuid = dictionary[UserStrings.uuidKey] as? String
            else { return nil }
        
        self.init(email: email, name: name, friends: friends, uuid: uuid)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String: Any] {
        [UserStrings.emailKey : email,
         UserStrings.nameKey : name,
         UserStrings.friendsKey : friends,
         UserStrings.uuidKey : uuid]
    }
}
