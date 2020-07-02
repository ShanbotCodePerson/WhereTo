//
//  Restaurant.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

// MARK: - String Constants

struct RestaurantStrings {
    static let recordType = "restaurant"
    fileprivate static let restaurantIDKey = "restaurantID"
    fileprivate static let nameKey = "name"
    fileprivate static let coordinatesKey = "coordinates"
    fileprivate static let categoriesKey = "categories"
    fileprivate static let ratingKey = "rating"
    fileprivate static let urlKey = "url"
    fileprivate static let imageURLKey = "imageURL"
    fileprivate static let address1Key = "address1"
    fileprivate static let cityKey = "city"
    fileprivate static let zipKey = "zip"
    fileprivate static let countryKey = "country"
    fileprivate static let stateKey = "state"
    fileprivate static let displayAddressKey = "displayAddress"
}

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
        let address1: String?
        let city: String?
        let zip: String?
        let country: String?
        let state: String?
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

extension Restaurant {
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [RestaurantStrings.restaurantIDKey : restaurantID,
         RestaurantStrings.nameKey : name,
         RestaurantStrings.coordinatesKey : Helpers.dictionaryToJSON(coordinates) as Any,
         RestaurantStrings.categoriesKey : categories.map({ Helpers.dictionaryToJSON($0) }) as Any,
         RestaurantStrings.ratingKey : rating as Any,
         RestaurantStrings.urlKey : url,
         RestaurantStrings.imageURLKey : imageURL as Any,
         RestaurantStrings.address1Key : location.address1 as Any,
         RestaurantStrings.cityKey : location.city as Any,
         RestaurantStrings.zipKey : location.zip as Any,
         RestaurantStrings.countryKey : location.country as Any,
         RestaurantStrings.stateKey : location.state as Any,
         RestaurantStrings.displayAddressKey : location.displayAddress]
    }
    
    // MARK: - Convert from Dictionary
    
    init?(dictionary: [String : Any]) {
        guard let restaurantID = dictionary[RestaurantStrings.restaurantIDKey] as? String,
            let name = dictionary[RestaurantStrings.nameKey] as? String,
            let coordinatesJSON = dictionary[RestaurantStrings.coordinatesKey] as? String,
            let coordinates: [String : Float] = Helpers.JSONtoDictionary(coordinatesJSON),
            let categoriesJSON = dictionary[RestaurantStrings.categoriesKey] as? [String],
            let url = dictionary[RestaurantStrings.urlKey] as? String,
            let displayAddress = dictionary[RestaurantStrings.displayAddressKey] as? [String]
            else { return nil }
        let categories = categoriesJSON.compactMap { (json) -> [String : String]? in
           return Helpers.JSONtoDictionary(json)
        }
        let rating = dictionary[RestaurantStrings.ratingKey] as? Float
        let imageURL = dictionary[RestaurantStrings.imageURLKey] as? String
        let address1 = dictionary[RestaurantStrings.address1Key] as? String
        let city = dictionary[RestaurantStrings.cityKey] as? String
        let zip = dictionary[RestaurantStrings.zipKey] as? String
        let country = dictionary[RestaurantStrings.countryKey] as? String
        let state = dictionary[RestaurantStrings.stateKey] as? String
        
        let location = Location(address1: address1, city: city, zip: zip, country: country, state: state, displayAddress: displayAddress)
        
        self.init(restaurantID: restaurantID, name: name, coordinates: coordinates, categories: categories, rating: rating, location: location, url: url, imageURL: imageURL)
    }
}

struct Helpers {
    
    // MARK: - Helper Methods
    
    static func dictionaryToJSON(_ dictionary: [String : Any]) -> String? {
        guard let JSONData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return nil }
        return String(data: JSONData, encoding: .ascii)
    }
    
    static func JSONtoDictionary<T>(_ json: String) -> [String : T]? {
        guard let jsonData = json.data(using: .ascii),
            let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = decoded as? [String : T]
            else { return nil }
        return dictionary
    }
}
