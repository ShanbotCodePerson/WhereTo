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
import UIKit.UIImage

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
    
    // Save a restaurant to the cloud
    func save(_ restaurant: Restaurant, completion: @escaping resultCompletion) {
        // Save the restaurant to the cloud, using the restaurant id as the document id (to avoid duplicates)
        db.collection(RestaurantStrings.recordType)
            .document(restaurant.restaurantID)
            .setData(restaurant.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                return completion(.success(true))
        }
    }
    
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
                let restaurants = businesses.map { $0 }
                
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
    
    // Read (fetch) a list of restaurants from the cloud by their ID's
    func fetchRestaurantsWithIDs(restaurantIDs: [String], completion: @escaping resultCompletionWith<[Restaurant]>) {
        // Handle the edge case of no restaurants
        if restaurantIDs.count == 0 { return completion(.success([])) }
        
        // Handle the base case of 10 restaurants or fewer
        if restaurantIDs.count <= 10 { return fetchTenRestaurants(with: restaurantIDs, completion: completion) }
        
        // Initialize the result
        var restaurants: [Restaurant] = []
        let group = DispatchGroup()
        
        // Firebase only allows searches of 10 items at a time, so break up the data into groups of ten
        let rounds = Int(Double(restaurantIDs.count / 10).rounded(.up))
         for round in 0..<rounds {
            // Get the subsection of restaurants to search for
            let subsection = Array(restaurantIDs[(round * 10)..<min(((round + 1) * 10), restaurantIDs.count)])
            
            // Run the query for just those ten elements
            group.enter()
            fetchTenRestaurants(with: subsection) { (result) in
                switch result {
                case .success(let tenRestaurants):
                    restaurants.append(contentsOf: tenRestaurants)
                    group.leave()
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
        
        
        // Return the result
        group.notify(queue: .main) { return completion(.success(restaurants)) }
    }
    
    // A helper function that can pull only ten restaurants from the cloud at once
    private func fetchTenRestaurants(with restaurantIDs: [String], completion: @escaping resultCompletionWith<[Restaurant]>) {
        
        // Get the data from the cloud
        db.collection(RestaurantStrings.recordType)
            .whereField(RestaurantStrings.restaurantIDKey, in: restaurantIDs)
            .getDocuments { (results, error) in
                
                // Handle any errors
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let restaurants = documents.compactMap { Restaurant(dictionary: $0.data()) }
                
                // Return the result
                return completion(.success(restaurants))
        }
    }
    
//    // Read (fetch) a list of restaurants from the API from a list of restaurant ID's
//    func fetchRestaurantsWithIDs(restaurantIDs: [String], completion: @escaping resultCompletionWith<[Restaurant]>) {
//
//        var restaurants: [Restaurant] = []
//
//        let group = DispatchGroup()
//
//        for id in restaurantIDs {
//            group.enter()
//
//            fetchRestaurantByID(id) { (result) in
//                switch result {
//                case .success(let restaurant):
//                    restaurants.append(restaurant)
//                case .failure(let error):
//                    // Print and return the error
//                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                    return completion(.failure(error))
//                }
//                group.leave()
//            }
//        }
//
//        group.notify(queue: .main) {
//            return completion(.success(restaurants))
//        }
//    }
    
//    // Fetch a single restaurant by its ID
//    func fetchRestaurantByID(_ restaurantID: String, completion: @escaping resultCompletionWith<Restaurant>) {
//        // 1 - URL setup
//        var request = URLRequest(url: URL(string: "\(yelpStrings.baseURLString)/\(restaurantID)")!, timeoutInterval: Double.infinity)
//        request.addValue(yelpStrings.apiKeyValue, forHTTPHeaderField: yelpStrings.authHeader)
//
//        request.httpMethod = yelpStrings.methodValue
////        print("got here to \(#function) and \(request)")
//
//        // 2 - Data task
//        URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
//
//            // 3 - Error Handling
//            if let error = error {
//                return completion(.failure(.thrownError(error)))
//            }
////            print("got here2 and there's no error")
//
//            // 4 - check for data
//            guard let data = data else { return completion(.failure(.noData))}
////            print("got here 3 and the data exists")
//
//            // 5 - Decode data
//            do {
//                // Check to see if the result is an error about too many requests per second
//                if let error = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary)?["error"] {
//                    print("got here and apparently Json has an error")
//                    if let errorCode = (error as? NSDictionary)?["code"] as? String, errorCode == "TOO_MANY_REQUESTS_PER_SECOND" {
//                        print("got here and it was too many requests")
//                        // Wait a tiny bit then try the request again
//                        let waitTime = (Double.random(in: 0.2...0.8) * 10).rounded() / 10
//                        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
//                            self?.fetchRestaurantByID(restaurantID, completion: completion)
//                        }
//                    }
//                    else {
//                        print("got here and UHOH SOMETHING DIFFERENT the error was something different! \(error)")
//                        print("Error in \(#function) : \(error)")
//                        return completion(.failure(.noData))
//                    }
//                }
//                else {
//                    let restaurant = try JSONDecoder().decode(Restaurant.self, from: data)
//                    print("got to end and restaurant exists")
//                    return completion(.success(restaurant))
//                }
//            } catch {
//                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                return completion(.failure(.thrownError(error)))
//            }
//        }.resume()
//    }
    
    // fetch restaurants with user input name and optional address
    func fetchRestaurantsByName(name: String, address: String? = nil, currentLocation: CLLocation? = nil, completion: @escaping resultCompletionWith<[Restaurant]>) {
        
        guard var baseURL = URL(string: yelpStrings.baseURLString) else { return completion(.failure(.invalidURL)) }
        baseURL.appendPathComponent(yelpStrings.searchPath)
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
//        let typeQuery = URLQueryItem(name: yelpStrings)
        let nameQuery = URLQueryItem(name: yelpStrings.termKey, value: name)
        
        // 1 - URL setup
        if !(address?.isEmpty ?? true) {
            // request by address
            guard let address = address else { return completion(.failure(.noLocationForAddress)) }
            
            let locationQuery = URLQueryItem(name: yelpStrings.locationKey, value: address)
           
            components?.queryItems = [nameQuery, locationQuery]
        } else {
            guard let currentLocation = currentLocation else { return completion(.failure(.noLocationForAddress)) }
            // Get current location
            
            let latitudeQuery = URLQueryItem(name: yelpStrings.latitudeKey, value: String(currentLocation.coordinate.latitude))
            let longitudeQuery = URLQueryItem(name: yelpStrings.longitudeKey, value: String(currentLocation.coordinate.longitude))
            
            // request by currentLocation
            components?.queryItems = [nameQuery, latitudeQuery, longitudeQuery]
        }
    
        guard let finalURL = components?.url else { return completion(.failure(.invalidURL)) }
        
        
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
                let restaurants = businesses.map { $0 }
                
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
    
    // Read (fetch) a restaurant's image
    func fetchImage(for restaurant: Restaurant, completion: @escaping (UIImage) -> Void) {
        // If the restaurant doesn't have an image, use the default image instead
        guard let imageURL = restaurant.imageURL,
            let finalURL = URL(string: imageURL)
            else { return completion(#imageLiteral(resourceName: "default_restaurant_image")) }
        
        // Get the image from the cloud
        URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
            
            // If the cloud returned an error, use the default image instead
            if error != nil { return completion(#imageLiteral(resourceName: "default_restaurant_image")) }
            
            // Ensure that the data exists
            guard let data = data else { return completion(#imageLiteral(resourceName: "default_restaurant_image")) }
            
            // Convert the data to a UIImage
            guard let image = UIImage(data: data) else { return completion(#imageLiteral(resourceName: "default_restaurant_image")) }
            return completion(image)
            
        }.resume()
    }
}
