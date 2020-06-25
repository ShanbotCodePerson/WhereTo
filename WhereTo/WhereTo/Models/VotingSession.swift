//
//  VotingSession.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct VotingSessionStrings {
    static let recordType = "votingSession"
//    static let useDietaryRestrictionsKey = "useDietaryRestrictions"
    static let votesEachKey = "votesEach"
//    static let coordinatesKey = "coordinates"
//    static let radiusKey = "radius"
    static let restaurantsKey = "restaurants"
    static let outcomeKey = "outcome"
    static let uuidKey = "uuid"
}

class VotingSession {
    
    // MARK: - Properties
    
    var users: [User]?                   // Not saved to cloud - fetched dynamically
//    var useDietaryRestrictions: Bool // FIXME: - probably don't need this
    let votesEach: Int
//    let coordinates: [String : Float] // FIXME: - probably don't need this
//    let radius: Float // FIXME: - probably don't need this
    var restaurantIDs: [String]         // Saved to cloud as string list of restaurant id's
    var restaurants: [Restaurant]?      // Not saved to cloud - fetched dynamically
    var outcomeID: String?              // Saved to cloud as restaurant id
    var documentID: String?             // document id in Firebase, for editing purposes
    let uuid: String
    
    // MARK: - Initializers
    
    init(votesEach: Int,
//         coordinates: [String : Float],
//         radius: Float = 10.0,
         restaurantIDs: [String],
         outcomeID: String? = nil,
         uuid: String = UUID().uuidString) {
        
//        self.useDietaryRestrictions = useDietaryRestrictions
        self.votesEach = votesEach
//        self.coordinates = coordinates
//        self.radius = radius
        self.restaurantIDs = restaurantIDs
        self.outcomeID = outcomeID
        self.uuid = uuid
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let votesEach = dictionary[VotingSessionStrings.votesEachKey] as? Int,
//            let useDietaryRestrictions = dictionary[VotingSessionStrings.useDietaryRestrictionsKey] as? Bool,
//            let coordinates = dictionary[VotingSessionStrings.coordinatesKey] as? [String : Float],
//            let radius = dictionary[VotingSessionStrings.radiusKey] as? Float,
            let restaurantIDs = dictionary[VotingSessionStrings.restaurantsKey] as? [String],
            let uuid = dictionary[VotingSessionStrings.uuidKey] as? String
            else { return nil }
        let outcomeID = dictionary[VotingSessionStrings.outcomeKey] as? String
        
        self.init(votesEach: votesEach,
//                  coordinates: coordinates,
//                  radius: radius,
                  restaurantIDs: restaurantIDs,
                  outcomeID: outcomeID,
                  uuid: uuid)
        
        // Fetch the user objects
        VotingSessionController.shared.fetchUsersInVotingSession(with: uuid) { [weak self] (result) in
            switch result {
            case .success(let users):
                self?.users = users
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // Fetch the restaurant objects
        RestaurantController.shared.fetchRestaurantsWithIDs(restaurantIDs: restaurantIDs) { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                self?.restaurants = restaurants ?? []
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [VotingSessionStrings.votesEachKey : votesEach,
//         VotingSessionStrings.useDietaryRestrictionsKey : useDietaryRestrictions,
//         VotingSessionStrings.coordinatesKey : coordinates,
//         VotingSessionStrings.radiusKey : radius,
         VotingSessionStrings.restaurantsKey : restaurantIDs,
         VotingSessionStrings.outcomeKey : outcomeID as Any,
         VotingSessionStrings.uuidKey : uuid]
    }
}
