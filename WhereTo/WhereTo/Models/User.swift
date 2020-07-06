//
//  User.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

// MARK: - String Constants

struct UserStrings {
    static let recordType = "user"
    static let emailKey = "email"
    static let nameKey = "name"
    static let profilePhotoURLKey = "profilePhotoURL"
    static let dietaryRestrictionsKey = "dietaryRestrictions"
    static let friendsKey = "friends"
    static let blockedUsersKey = "blockedUsers"
    static let favoriteRestaurantsKey = "favoriteRestaurants"
    static let blacklistedRestaurantsKey = "blacklistedRestaurants"
    static let previousRestaurantsKey = "previousRestaurants"
    static let activeVotingSessionsKey = "activeVotingSessions"
    static let uuidKey = "uuid"
}

class User {
    
    // MARK: - Properties
    
    let email: String
    var name: String
    var profilePhotoURL: String?
    var photo: UIImage?
    var dietaryRestrictions: [DietaryRestriction]
    var friends: [String]                       // uuid's of other users
    var blockedUsers: [String]                  // uuid's of other users
    var favoriteRestaurants: [String]           // restaurant id's
    var blacklistedRestaurants: [String]        // restaurant id's
    var previousRestaurants: [String]           // restaurant id's
    var activeVotingSessions: [String]          // uuid's of voting sessions
    var documentID: String?                     // document id in Firebase, for editing purposes
    let uuid: String
    
    enum DietaryRestriction: String, CaseIterable {
        case glutenFree = "gluten_free"
        case vegetarian
        case vegan
        
        var formatted: String {
            switch self {
            case .glutenFree:
                return "Gluten-Free"
            case .vegetarian:
                return "Vegetarian"
            case .vegan:
                return "Vegan"
            }
        }
    }
    
    // MARK: - Initializers
    
    init(email: String,
         name: String,
         profilePhotoURL: String? = nil,
         dietaryRestrictions: [DietaryRestriction]? = nil,
         friends: [String]? = nil,
         blockedUsers: [String]? = nil,
         favoriteRestaurants: [String]? = nil,
         blacklistedRestaurants: [String]? = nil,
         previousRestaurants: [String]? = nil,
         activeVotingSessions: [String]? = nil,
         documentID: String? = nil,
         uuid: String = UUID().uuidString) {
        
        self.email = email
        self.name = name
        self.profilePhotoURL = profilePhotoURL
        self.dietaryRestrictions = dietaryRestrictions ?? []
        self.friends = friends ?? []
        self.blockedUsers = blockedUsers ?? []
        self.favoriteRestaurants = favoriteRestaurants ?? []
        self.blacklistedRestaurants = blacklistedRestaurants ?? []
        self.previousRestaurants = previousRestaurants ?? []
        self.activeVotingSessions = activeVotingSessions ?? []
        self.documentID = documentID
        self.uuid = uuid
        
        UserController.shared.fetchUsersProfilePhoto(user: self) { [weak self] (photo) in
            self?.photo = photo
            
            // Update the UI
            NotificationCenter.default.post(Notification(name: .updateFriendsList))
            NotificationCenter.default.post(Notification(name: .updateProfileView))
        }
    }
    
    convenience init?(dictionary: [String: Any]) {
        guard let email = dictionary[UserStrings.emailKey] as? String,
            let name = dictionary[UserStrings.nameKey] as? String,
            let dietaryRestrictionsRawValues = dictionary[UserStrings.dietaryRestrictionsKey] as? [String],
            let friends = dictionary[UserStrings.friendsKey] as? [String],
            let blockedUsers = dictionary[UserStrings.blockedUsersKey] as? [String],
            let favoriteRestaurants = dictionary[UserStrings.favoriteRestaurantsKey] as? [String],
            let blacklistedRestaurants = dictionary[UserStrings.blacklistedRestaurantsKey] as? [String],
            let previousRestaurants = dictionary[UserStrings.previousRestaurantsKey] as? [String],
            let activeVotingSessions = dictionary[UserStrings.activeVotingSessionsKey] as? [String],
            let uuid = dictionary[UserStrings.uuidKey] as? String
            else { return nil }
        let profilePhotoURL = dictionary[UserStrings.profilePhotoURLKey] as? String
        let dietaryRestrictions = dietaryRestrictionsRawValues.compactMap { DietaryRestriction(rawValue: $0) }
        
        self.init(email: email,
                  name: name,
                  profilePhotoURL: profilePhotoURL,
                  dietaryRestrictions: dietaryRestrictions,
                  friends: friends,
                  blockedUsers: blockedUsers,
                  favoriteRestaurants: favoriteRestaurants,
                  blacklistedRestaurants: blacklistedRestaurants,
                  previousRestaurants: previousRestaurants,
                  activeVotingSessions: activeVotingSessions,
                  uuid: uuid)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String: Any] {
        [UserStrings.emailKey : email,
         UserStrings.nameKey : name,
         UserStrings.profilePhotoURLKey: profilePhotoURL as Any,
         UserStrings.dietaryRestrictionsKey : dietaryRestrictions.map({ $0.rawValue }),
         UserStrings.friendsKey : Array(Set(friends)),
         UserStrings.blockedUsersKey : blockedUsers,
         UserStrings.favoriteRestaurantsKey : Array(Set(favoriteRestaurants)),
         UserStrings.blacklistedRestaurantsKey : Array(Set(blacklistedRestaurants)),
         UserStrings.previousRestaurantsKey : Array(Set(previousRestaurants)),
         UserStrings.activeVotingSessionsKey : Array(Set(activeVotingSessions)),
         UserStrings.uuidKey : uuid]
    }
}
