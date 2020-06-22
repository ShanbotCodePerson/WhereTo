//
//  VotingSession.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct VotingSessionStrings {
    static let recordType = "votingSession"
}

class VotingSession {
    
    // MARK: - Properties
    
    // MARK: - Initializer
    
    init() {
        
    }
    
    convenience init?(dictionary: [String : Any]) {
        return nil
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        return [:]
    }
}
