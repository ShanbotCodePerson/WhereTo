//
//  FriendRequest.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct FriendRequestStrings {
    static let recordType = "friendRequest"
    static let fromIDKey = "fromID"
    static let fromNameKey = "fromName"
    static let toIDKey = "toID"
    static let toNameKey = "toName"
    static let statusKey = "status"
}

class FriendRequest {
    
    // MARK: - Properties
    
    let fromID: String
    let fromName: String
    let toID: String
    let toName: String
    var status: Status
    
    enum Status: Int {
        case waiting
        case accepted
        case denied
        case removingFriend
    }
    
    // MARK: - Initializers
    
    init(fromID: String,
         fromName: String,
         toID: String,
         toName: String,
         status: Status = .waiting) {
        
        self.fromID = fromID
        self.fromName = fromName
        self.toID = toID
        self.toName = toName
        self.status = status
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let fromID = dictionary[FriendRequestStrings.fromIDKey] as? String,
            let fromName = dictionary[FriendRequestStrings.fromNameKey] as? String,
            let toID = dictionary[FriendRequestStrings.toIDKey] as? String,
            let toName = dictionary[FriendRequestStrings.toNameKey] as? String,
            let statusRawValue = dictionary[FriendRequestStrings.statusKey] as? Int,
            let status = Status(rawValue: statusRawValue)
            else { return nil }
        
        self.init(fromID: fromID, fromName: fromName, toID: toID, toName: toName, status: status)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [FriendRequestStrings.fromIDKey : fromID,
         FriendRequestStrings.fromNameKey : fromName,
         FriendRequestStrings.toIDKey : toID,
         FriendRequestStrings.toNameKey : toName,
         FriendRequestStrings.statusKey : status.rawValue]
    }
}
