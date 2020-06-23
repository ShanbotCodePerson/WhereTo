//
//  RestaurantController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class RestaurantController {
    
    // MARK: - Singleton
    
    static let shared = RestaurantController()
    
    // MARK: - Source of Truth
    
    var recentRestaurants: [Restaurant]?
    var favoriteRestaurants: [Restaurant]?
    var blacklistedRestaurants: [Restaurant]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Read (fetch) a list of restaurants from the API (ie, recent, favorites, blacklisted)
    
    // Read (fetch) a list of restaurants from the API based on location
}
