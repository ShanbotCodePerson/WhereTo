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
    static let blockedUsersKey = "blockedUsers"
    static let favoriteRestaurantsKey = "favoriteRestaurants"
    static let blacklistedRestaurantsKey = "blacklistedRestaurants"
    static let previousRestaurantsKey = "previousRestaurants"
    static let uuidKey = "uuid"
}

class User {
    
    // MARK: - Properties
    
    let email: String
    var name: String
//    var profilePhoto:
//    var dietaryRestrictions: []
    var friends: [String]
    var blockedUsers: [String]
    var favoriteRestaurants: [String]
    var blacklistedRestaurants: [String]
    var previousRestaurants: [String]
    var documentID: String?
    let uuid: String
    
    // MARK: - Initializers
    
    init(email: String,
         name: String,
         friends: [String]? = nil,
         blockedUsers: [String]? = nil,
         favoriteRestaurants: [String]? = nil,
         blacklistedRestaurants: [String]? = nil,
         previousRestaurants: [String]? = nil,
         documentID: String? = nil,
         uuid: String = UUID().uuidString) {
        
        self.email = email
        self.name = name
        self.friends = friends ?? []
        self.blockedUsers = blockedUsers ?? []
        self.favoriteRestaurants = favoriteRestaurants ?? []
        self.blacklistedRestaurants = blacklistedRestaurants ?? []
        self.previousRestaurants = previousRestaurants ?? []
        self.documentID = documentID
        self.uuid = uuid
    }
    
    convenience init?(dictionary: [String: Any]) {
        guard let email = dictionary[UserStrings.emailKey] as? String,
            let name = dictionary[UserStrings.nameKey] as? String,
            let friends = dictionary[UserStrings.friendsKey] as? [String],
            let blockedUsers = dictionary[UserStrings.blockedUsersKey] as? [String],
            let favoriteRestaurants = dictionary[UserStrings.favoriteRestaurantsKey] as? [String],
            let blacklistedRestaurants = dictionary[UserStrings.blacklistedRestaurantsKey] as? [String],
            let previousRestaurants = dictionary[UserStrings.previousRestaurantsKey] as? [String],
            let uuid = dictionary[UserStrings.uuidKey] as? String
            else { return nil }
        
        self.init(email: email,
                  name: name,
                  friends: friends,
                  blockedUsers: blockedUsers,
                  favoriteRestaurants: favoriteRestaurants,
                  blacklistedRestaurants: blacklistedRestaurants,
                  previousRestaurants: previousRestaurants,
                  uuid: uuid)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String: Any] {
        [UserStrings.emailKey : email,
         UserStrings.nameKey : name,
         UserStrings.friendsKey : friends,
         UserStrings.blockedUsersKey : blockedUsers,
         UserStrings.favoriteRestaurantsKey : favoriteRestaurants,
         UserStrings.blacklistedRestaurantsKey : blacklistedRestaurants,
         UserStrings.previousRestaurantsKey : previousRestaurants,
         UserStrings.uuidKey : uuid]
    }
}
