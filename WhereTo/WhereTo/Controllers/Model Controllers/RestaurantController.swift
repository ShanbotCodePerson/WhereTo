//
//  RestaurantController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

struct yelpStrings {
    static let baseURLString = "https://api.yelp.com/v3/businesses"
    static let authHeader = "Authorization"
    static let apiKeyValue = "Bearer R_hx8BUmF2jCHNXqEU8T2_9JubC4CP5ZW2jNxXN0NqFKNd9De8vcX_YAlAKRa3At1OwwSnQYd8VoOg4WGKqli0eJDSF8mA4BdNLktpDMoxDUWJhrTF99eRuJ-yjyXnYx"
    static let methodValue = "GET"
    static let searchPath = "search"
    static let termKey = "term"
    static let termValue = "restaurants"
    static let locationKey = "location"
    static let categoriesKey = "categories"
    static let longitudeKey = "longitude"
    static let latitudeKey = "latitude"
    static let openNowKey = "open_now"
}

class RestaurantController {
    
    // MARK: - Singleton
    
    static let shared = RestaurantController()
    
    // MARK: - Source of Truth
    
    var restaurantIDs: [String]?
    var closeRestaurants: [Restaurant]?
    var previousRestaurants: [Restaurant]?
    var favoriteRestaurants: [Restaurant]?
    var blacklistedRestaurants: [Restaurant]?
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    let db = Firestore.firestore()
    typealias resultCompletion = (Result<Bool, WhereToError>) -> Void
    typealias resultCompletionWith<T> = (Result<T, WhereToError>) -> Void
    
    
    // MARK: - CRUD Methods
    
    // Read (fetch) a list of restaurants from the API based on location
    func fetchRestaurantsByLocation(location: CLLocation, searchByIsOpen: Bool = false, dietaryRestrictions: [String] = [], completion: @escaping resultCompletionWith<[Restaurant]?>) {
        
        let isOpenQuery = searchByIsOpen ? "&\(yelpStrings.openNowKey)=true" : ""
        
        var categoriesQuery = ""
        for restriction in dietaryRestrictions {
            categoriesQuery += "&\(yelpStrings.categoriesKey)=\(restriction)"
        }
        
        // 1 - URL setup
        var request = URLRequest(url: URL(string: "\(yelpStrings.baseURLString)/\(yelpStrings.searchPath)?\(yelpStrings.latitudeKey)=\(location.coordinate.latitude)&\(yelpStrings.longitudeKey)=\(location.coordinate.longitude)&\(yelpStrings.termKey)=\(yelpStrings.termValue)\(isOpenQuery)\(categoriesQuery)")!, timeoutInterval: Double.infinity)
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
                
                for restaurant in businesses {
                    restaurants.append(restaurant)
                }
                return completion(.success(restaurants))
                
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.thrownError(error)))
            }
        }.resume()
    }
    
    // Read (fetch) a random restaurant by location
    func fetchRandomRestaurant(near location: CLLocation, usingDietaryRestrictions: Bool, completion: @escaping resultCompletionWith<Restaurant>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Get the user's dietary restrictions
        var dietaryRestrictions: [String] = []
        if usingDietaryRestrictions {
            dietaryRestrictions = currentUser.dietaryRestrictions.map { $0.rawValue }
        }
        
        // Fetch the list of restaurants near that location that are currently open
        fetchRestaurantsByLocation(location: location, searchByIsOpen: true, dietaryRestrictions: dietaryRestrictions) { (result) in
            switch result {
            case .success(let restaurants):
                guard let restaurants = restaurants else { return completion(.failure(.noRestaurantsMatch)) }
                
                // Make sure the restaurants have ratings
                var sortedRestaurants = restaurants.filter { $0.rating != nil }
                guard sortedRestaurants.count > 0 else {
                    let randomRestaurant = restaurants[Int.random(in: 0..<restaurants.count)]
                    return completion(.success(randomRestaurant))
                }
                
                // Sort the restaurants in order of highest rankings
                sortedRestaurants = sortedRestaurants.sorted(by: { $0.rating! > $1.rating! })
                
                // Limit to the highest ranked restaurants
                sortedRestaurants = Array(sortedRestaurants.prefix(min(10, sortedRestaurants.count / 4)))
                
                // Return a random restaurant
                let randomRestaurant = sortedRestaurants[Int.random(in: 0..<sortedRestaurants.count)]
                return completion(.success(randomRestaurant))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) a list of restaurants from the API from a list of restaurant ID's
    func fetchRestaurantsWithIDs(restaurantIDs: [String], completion: @escaping resultCompletionWith<[Restaurant]>) {
        
        var restaurants: [Restaurant] = []
        
        let group = DispatchGroup()
        
        for id in restaurantIDs {
            group.enter()
          
            fetchRestaurantByID(id) { (result) in
                switch result {
                case .success(let restaurant):
                    restaurants.append(restaurant)
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            return completion(.success(restaurants))
        }
    }
    
    // Fetch a single restaurant by its ID
    func fetchRestaurantByID(_ restaurantID: String, completion: @escaping resultCompletionWith<Restaurant>) {
        // 1 - URL setup
        var request = URLRequest(url: URL(string: "\(yelpStrings.baseURLString)/\(restaurantID)")!, timeoutInterval: Double.infinity)
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
                // Check to see if the result is an error about too many requests per second
                if let error = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary)?["error"] {
                    if let errorCode = (error as? NSDictionary)?["code"] as? String, errorCode == "TOO_MANY_REQUESTS_PER_SECOND" {
                        // Wait a tiny bit then try the request again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.fetchRestaurantByID(restaurantID, completion: completion)
                        }
                    }
                }
                else {
                    let restaurant = try JSONDecoder().decode(Restaurant.self, from: data)
                    return completion(.success(restaurant))
                }
            } catch {
                // TODO: - if error is that too many queries per second, if so, retry fetching later?
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.thrownError(error)))
            }
        }.resume()
    }
    
    // fetch restaurants with user input name and optional address
    func fetchRestaurantsByName(name: String, address: String? = nil, currentLocation: CLLocation? = nil, completion: @escaping resultCompletionWith<[Restaurant]>) {
        
        var urlString = ""
        
        // 1 - URL setup
        if !(address?.isEmpty ?? true) {
            // request by address
            guard let address = address else { return }
            urlString = "\(yelpStrings.baseURLString)/\(yelpStrings.searchPath)?\(yelpStrings.termKey)=\(name)&\(yelpStrings.locationKey)=\(address)"
        } else {
            guard let currentLocation = currentLocation else { return }
            // Get current location
            
            // request by currentLocation
            urlString =  "\(yelpStrings.baseURLString)/\(yelpStrings.searchPath)?\(yelpStrings.latitudeKey)=\(currentLocation.coordinate.latitude)&\(yelpStrings.longitudeKey)=\(currentLocation.coordinate.longitude)&\(yelpStrings.termKey)=\(name)"
        }
    
        guard let finalURL = URL(string: urlString) else { return }
        var request = URLRequest(url: finalURL)
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
                
                for restaurant in businesses {
                    restaurants.append(restaurant)
                }
                return completion(.success(restaurants))
                
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.thrownError(error)))
            }
        }.resume()
    }
    
    
    // Read (fetch) all the user's previous restaurants
    func fetchPreviousRestaurants(completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        fetchRestaurantsWithIDs(restaurantIDs: currentUser.previousRestaurants) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                // Save to the source of truth and return the success
                self?.previousRestaurants = restaurants
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) all the user's favorite restaurants
    func fetchFavoriteRestaurants(completion: @escaping resultCompletion) {
         guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        fetchRestaurantsWithIDs(restaurantIDs: currentUser.favoriteRestaurants) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                // Save to the source of truth and return the success
                self?.favoriteRestaurants = restaurants
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) all the user's blacklisted restaurants
    func fetchBlacklistedRestaurants(completion: @escaping resultCompletion) {
         guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        fetchRestaurantsWithIDs(restaurantIDs: currentUser.blacklistedRestaurants) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                // Save to the source of truth and return the success
                self?.blacklistedRestaurants = restaurants
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
}
