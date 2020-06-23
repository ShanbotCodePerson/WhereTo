//
//  RestaurantController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

struct networkingStrings {
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
    
    var recentRestaurants: [Restaurant]?
    var favoriteRestaurants: [Restaurant]?
    var blacklistedRestaurants: [Restaurant]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    
    // MARK: - CRUD Methods
    
    func fetchRestraurants(completion: @escaping(Result<[Restaurant]?, WhereToError>) -> Void) {
        // 1 - URL setup
        
        var request = URLRequest(url: URL(string: networkingStrings.baseURL)! , timeoutInterval: Double.infinity)
        request.addValue(networkingStrings.apiKeyValue, forHTTPHeaderField: networkingStrings.authHeader)
        request.httpMethod = networkingStrings.methodValue
         
        // 2 - Data task
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
          
            // 3 - Error Handling
            if let error = error {
                return completion(.failure(.thrownError(error)))
            }
            
            // 4 - check for data
            guard let data = data else { return completion(.failure(.noData))}
            
            // 5 - Decode data
            do {
                
            } catch {
                return completion(.failure(.thrownError(error)))
            }
        }.resume()
    }
    // Read (fetch) a list of restaurants from the API (ie, recent, favorites, blacklisted)
    
    // Read (fetch) a list of restaurants from the API based on location
}
