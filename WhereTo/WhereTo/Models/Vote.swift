//
//  Vote.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct VoteStrings {
    static let recordType = "vote"
    static let voteValueKey = "voteValue"
    static let userIDKey = "userID"
    static let restaurantIDKey = "restaurantID"
    static let votingSessionIDKey = "votingSessionID"
}

class Vote {
    
    // MARK: - Properties
    
    let voteValue: Int
    let userID: String              // The uuid of the user who cast the vote
    let restaurantID: String        // The restaurant ID voted for
    let votingSessionID: String     // The voting session in which the vote took place
    
    // MARK: - Initializers
    
    init(voteValue: Int, userID: String, restaurantID: String, votingSessionID: String) {
        self.voteValue = voteValue
        self.userID = userID
        self.restaurantID = restaurantID
        self.votingSessionID = votingSessionID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let voteValue = dictionary[VoteStrings.voteValueKey] as? Int,
            let userID = dictionary[VoteStrings.userIDKey] as? String,
            let restaurantID = dictionary[VoteStrings.restaurantIDKey] as? String,
            let votingSessionID = dictionary[VoteStrings.votingSessionIDKey] as? String
            else { return nil }
        
        self.init(voteValue: voteValue, userID: userID, restaurantID: restaurantID, votingSessionID: votingSessionID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [VoteStrings.voteValueKey : voteValue,
         VoteStrings.userIDKey : userID,
         VoteStrings.restaurantIDKey : restaurantID,
         VoteStrings.votingSessionIDKey : votingSessionID]
    }
}
