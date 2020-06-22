//
//  VotingSessionController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class VotingSessionController {
    
    // MARK: - Singleton
    
    static let shared = VotingSessionController()
    
    // MARK: - Source of Truth
    
    var votingSessions: [VotingSession]?
    // FIXME: - can you be in multiple sessions at once? how to handle conflicts?
    // FIXME: - can you opt out of a voting session?
    
    // MARK: - CRUD Methods
    
    // Create a new voting session
    
    // Read (fetch) the current voting session
    
    // Update a voting session with votes
    
    // Delete a voting session when it's no longer needed
}
