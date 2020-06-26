//
//  Restaurant.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation


struct Restaurant: Codable {
    
    // MARK: - Properties
    let restaurantID: String
    let name: String
    let coordinates: [String : Float]
    let categories: [[String : String]]
    let rating: Float?
   
    enum CodingKeys: String, CodingKey {
        case name, coordinates, categories, rating, restaurantID = "id"
    }
}

struct RestaurantTopLevelDictionary: Codable {
    let businesses: [Restaurant]
}
