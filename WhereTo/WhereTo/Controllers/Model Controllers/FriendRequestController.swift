//
//  FriendRequestController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class FriendRequestController {
    
    // MARK: - Singleton
    
    static let shared = FriendRequestController()
    
    // MARK: - Source of Truth
    
    var pendingFriendRequests: [FriendRequest]?
    var outstandingFriendRequests: [FriendRequest]?
    
    // MARK: - CRUD Methods
    
    // Create a new friend request
    
    // Read (fetch) all pending friend requests
    
    // Read (fetch) all outstanding friend requests
    
    // Update a friend request with a response
    
    // Delete a friend request when it's no longer needed
}
