//
//  Restaurant.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

struct Restaurant: Codable, Hashable {
    
    // MARK: - Properties
    let restaurantID: String
    let name: String
    let coordinates: [String : Float]
    let categories: [[String : String]]
    var categoryNames: [String] { Array(categories.compactMap({ $0["title"] })) }
    let rating: Float?
    let location: Location
    let url: String
    let imageURL: String?
    
    struct Location: Codable, Hashable, Equatable {
        let address1: String
        let city: String
        let zip: String
        let country: String
        let state: String
        let displayAddress: [String]
        
        enum CodingKeys: String, CodingKey {
            case address1, city, country, state, zip = "zip_code", displayAddress = "display_address"
        }
        
        static func == (lhs: Location, rhs: Location) -> Bool {
            return (lhs.address1 == rhs.address1)
        }
    }
   
    enum CodingKeys: String, CodingKey {
        case name, coordinates, categories, rating, location, url, restaurantID = "id", imageURL = "image_url"
    }
    
    func getImage(completion: @escaping (UIImage) -> Void) {
        RestaurantController.shared.fetchImage(for: self, completion: completion)
    }
}

struct RestaurantTopLevelDictionary: Codable {
    let businesses: [Restaurant]
}

extension Restaurant: Equatable {
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        return lhs.restaurantID == rhs.restaurantID
    }
}
