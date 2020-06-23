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
    static let idKey = "id"
    static let nameKey = "name"
    static let coordinatesKey = "coordinates"
    static let categoriesKey = "categories"
    static let ratingKey = "rating"
    static let hoursKey = "hours"
}

class Restaurant {
    
    // MARK: - Properties
    let id: String
    let name: String
    let coordinates: [String: Float]
    let categories: [[String: String]]
    let rating: Float
    let hours: [[String: Any]]
    
    
    // MARK: - Initializers
    
    init(id: String, name: String, coordinates: [String: Float], categories: [[String: String]], rating: Float, hours: [[String: Any]]) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.categories = categories
        self.rating = rating
        self.hours = hours
        
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let id = dictionary[RestaurantStrings.idKey] as? String,
            let name = dictionary[RestaurantStrings.nameKey] as? String,
            let coordinates = dictionary[RestaurantStrings.coordinatesKey] as? [String: Float],
            let categories = dictionary[RestaurantStrings.categoriesKey] as? [[String: String]],
            let rating = dictionary[RestaurantStrings.ratingKey] as? Float,
            let hours = dictionary[RestaurantStrings.hoursKey] as? [[String: Any]]
        else { return nil }
        
        self.init(id: id, name: name, coordinates: coordinates, categories: categories, rating: rating, hours: hours)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        
        return [RestaurantStrings.idKey : id,
                RestaurantStrings.nameKey : name,
                RestaurantStrings.coordinatesKey : coordinates,
                RestaurantStrings.categoriesKey : categories,
                RestaurantStrings.ratingKey : rating,
                RestaurantStrings.hoursKey : hours]
    }
}
