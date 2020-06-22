//
//  Restaurant.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct RestaurantStrings {
    static let recordType = "restaurant"
}

class Restaurant {
    
    // MARK: - Properties
    
    // MARK: - Initializers
    
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
