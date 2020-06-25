//
//  VotingSessionInvite.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/24/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct VotingSessionInviteStrings {
    static let recordType = "votingSessionInvite"
    static let fromNameKey = "fromName"
    static let toIDKey = "toID"
    static let votingSessionIDKey = "votingSessionID"
}

class VotingSessionInvite {
    
    // MARK: - Properties
    
    let fromName: String            // The name of the friend who sent the invitation
    let toID: String                // The uuid of the friend who is being invited
//    let locationName: String
    let votingSessionID: String     // The uuid of the voting session
    
    // MARK: - Initializers
    
    init(fromName: String, toID: String, votingSessionID: String) {
        self.fromName = fromName
        self.toID = toID
        self.votingSessionID = votingSessionID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let fromName = dictionary[VotingSessionInviteStrings.fromNameKey] as? String,
            let toID = dictionary[VotingSessionInviteStrings.toIDKey] as? String,
            let votingSessionID = dictionary[VotingSessionInviteStrings.votingSessionIDKey] as? String
            else { return nil }
        
        self.init(fromName: fromName, toID: toID, votingSessionID: votingSessionID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [VotingSessionInviteStrings.fromNameKey : fromName,
         VotingSessionInviteStrings.toIDKey : toID,
         VotingSessionInviteStrings.votingSessionIDKey : votingSessionID]
    }
}
