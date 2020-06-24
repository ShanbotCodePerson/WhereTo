//
//  RestaurantController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import MapKit

struct yelpStrings {
    static let baseURL = "https://api.yelp.com/v3/businesses/search"
    static let authHeader = "Authorization"
    static let apiKeyValue = "Bearer R_hx8BUmF2jCHNXqEU8T2_9JubC4CP5ZW2jNxXN0NqFKNd9De8vcX_YAlAKRa3At1OwwSnQYd8VoOg4WGKqli0eJDSF8mA4BdNLktpDMoxDUWJhrTF99eRuJ-yjyXnYx"
    static let methodValue = "GET"
    static let termKey = "term"
    static let termValue = "restaurants"
    static let categoriesKey = "categories"
    static let longitudeKey = "longitude"
    static let latitudeKey = "latitude"
    
}

class RestaurantController {
    
    // MARK: - Singleton
    
    static let shared = RestaurantController()
    
    // MARK: - Source of Truth
    
    var closeRestaurants: [Restaurant]?
    var recentRestaurants: [Restaurant]?
    var favoriteRestaurants: [Restaurant]?
    var blacklistedRestaurants: [Restaurant]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    
    func fetchCurrentLocation() -> [String: Float] {
        // TODO: fetch current location using MapKit
        // return Longitude & latitude
        return [yelpStrings.latitudeKey : 43.486608, yelpStrings.longitudeKey : -112.034846]
    }
    
    // Read (fetch) a list of restaurants from the API based on location
    func fetchRestraurantsByLocation(completion: @escaping(Result<[Restaurant]?, WhereToError>) -> Void) {
        
        let coordinates = fetchCurrentLocation()
        
        // 1 - URL setup
        guard let baseURL = URLComponents(string: yelpStrings.baseURL) else { return completion(.failure(.invalidURL))}
        
        var urlComps = baseURL
            
        urlComps.queryItems = [
            URLQueryItem(name: yelpStrings.latitudeKey, value: "\(coordinates[yelpStrings.latitudeKey] ?? 43.486608)"),
            URLQueryItem(name: yelpStrings.longitudeKey, value: "\(coordinates[yelpStrings.longitudeKey] ?? -112.034846)"),
            URLQueryItem(name: yelpStrings.termKey, value: yelpStrings.termValue)
        ]
            
        let finalURL = urlComps.url
        
        var request = URLRequest(url: finalURL! , timeoutInterval: Double.infinity)
        request.addValue(yelpStrings.apiKeyValue, forHTTPHeaderField: yelpStrings.authHeader)
        request.httpMethod = yelpStrings.methodValue
         
        // 2 - Data task
        URLSession.shared.dataTask(with: request) { data, _, error in
          
            // 3 - Error Handling
            if let error = error {
                return completion(.failure(.thrownError(error)))
            }
            
            // 4 - check for data
            guard let data = data else { return completion(.failure(.noData))}
            
            // 5 - Decode data
            do {
                let topLevelDictionary = try JSONDecoder().decode(RestaurantTopLevelDictionary.self, from: data)
                let businesses = topLevelDictionary.businesses
                
                var restaurants: [Restaurant] = []
                
                for business in businesses {
                    let restaurant = business
                    // if open append to available restaurants
                    if restaurant.hours.openNow {
                        restaurants.append(restaurant)
                    }
                }
                return completion(.success(restaurants))
                
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.thrownError(error)))
            }
        }.resume()
    }
    
    // Read (fetch) a list of restaurants from the API (ie, recent, favorites, blacklisted)
    func fetchRestaurantsWithIDs(restaurantIDs: [String]) {
        
    }
}
