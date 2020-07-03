//
//  VotingSession.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

// MARK: - String Constants

struct VotingSessionStrings {
    static let recordType = "votingSession"
    static let votesEachKey = "votesEach"
    static let dietaryRestrictionsKey = "dietaryRestrictions"
    static let latitudeKey = "latitude"
    static let longitudeKey = "longitude"
    static let restaurantsKey = "restaurants"
    static let outcomeKey = "outcome"
    static let uuidKey = "uuid"
}

class VotingSession {
    
    // MARK: - Properties
    
    var users: [User]?                  // Not saved to cloud - fetched dynamically
    let votesEach: Int
    var dietaryRestrictions: [String]
    let location: CLLocation
    var restaurantIDs: [String]         // Saved to cloud as string list of restaurant id's
    var restaurants: [Restaurant]?      // Not saved to cloud - fetched dynamically
    var outcomeID: String?              // Saved to cloud as restaurant id
    var documentID: String?             // document id in Firebase, for editing purposes
    let uuid: String
    
    // MARK: - Initializers
    
    init(votesEach: Int,
         dietaryRestrictions: [String] = [],
         location: CLLocation,
         restaurantIDs: [String],
         outcomeID: String? = nil,
         uuid: String = UUID().uuidString) {
        
        self.votesEach = votesEach
        self.dietaryRestrictions = dietaryRestrictions
        self.location = location
        self.restaurantIDs = restaurantIDs
        self.outcomeID = outcomeID
        self.uuid = uuid
    }
    
    convenience init?(dictionary: [String : Any], completion: @escaping (VotingSession?) -> Void = { _ in }) {
        guard let votesEach = dictionary[VotingSessionStrings.votesEachKey] as? Int,
            let dietaryRestrictions = dictionary[VotingSessionStrings.dietaryRestrictionsKey] as? [String],
            let latitude = dictionary[VotingSessionStrings.latitudeKey] as? Double,
            let longitude = dictionary[VotingSessionStrings.longitudeKey] as? Double,
            let restaurantIDs = dictionary[VotingSessionStrings.restaurantsKey] as? [String],
            let uuid = dictionary[VotingSessionStrings.uuidKey] as? String
            else { return nil }
        let outcomeID = dictionary[VotingSessionStrings.outcomeKey] as? String
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        self.init(votesEach: votesEach,
                  dietaryRestrictions: dietaryRestrictions,
                  location: location,
                  restaurantIDs: restaurantIDs,
                  outcomeID: outcomeID,
                  uuid: uuid)
        
        let group = DispatchGroup()
        
        // Fetch the user objects
        group.enter()
        VotingSessionController.shared.fetchUsersInVotingSession(with: uuid) { [weak self] (result) in
            switch result {
            case .success(let users):
                self?.users = users
                group.leave()
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(nil)
            }
        }
        
        // Fetch the restaurant objects
        group.enter()
        RestaurantController.shared.fetchRestaurantsWithIDs(restaurantIDs: restaurantIDs) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                // Sort the restaurants, first by highest to lowest rating, then alphabetically
                let sortedRestaurants = restaurants.sorted(by: { (restaurant0, restaurant1) -> Bool in
                    if let rating0 = restaurant0.rating, let rating1 = restaurant1.rating {
                        if rating0 == rating1 { return restaurant1.name > restaurant0.name }
                        return rating1 > rating0
                    }
                    
                    return restaurant1.name > restaurant0.name
                })
                
                self?.restaurants = sortedRestaurants
                group.leave()
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(nil)
            }
        }
        
        group.notify(queue: .main) { return completion(self) }
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [VotingSessionStrings.votesEachKey : votesEach,
         VotingSessionStrings.dietaryRestrictionsKey : dietaryRestrictions,
         VotingSessionStrings.latitudeKey : location.coordinate.latitude,
         VotingSessionStrings.longitudeKey : location.coordinate.longitude,
         VotingSessionStrings.restaurantsKey : restaurantIDs,
         VotingSessionStrings.outcomeKey : outcomeID as Any,
         VotingSessionStrings.uuidKey : uuid]
    }
    
    // MARK: - Helper Properties
    
    // A nicely formatted list of the other users participating in the vote
    var participantNames: String {
        guard var users = users else { return "nobody" }
        users.removeAll(where: { $0.uuid == UserController.shared.currentUser?.uuid })
        if users.count == 1 { return users.first?.name ?? "nobody" }
        var result = ""
        for index in 0..<users.count {
            if index == users.count - 1 { result += ", and \(users[index].name)" }
            else { result += ", \(users[index].name)" }
        }
        return result
    }
    
    // The winning restaurant
    var winningRestaurant: Restaurant? {
        guard let outcomeID = outcomeID else { return nil }
        return restaurants?.first(where: { $0.restaurantID == outcomeID })
    }
}

extension VotingSession: Equatable {
    static func == (lhs: VotingSession, rhs: VotingSession) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
