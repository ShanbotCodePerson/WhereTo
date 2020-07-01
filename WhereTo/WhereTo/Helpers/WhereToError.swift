//
//  WhereToError.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

enum WhereToError: LocalizedError {
    
    case noUserFound
    case couldNotUnwrap
    case noSuchUser
    case fsError(Error)
    case thrownError(Error)
    case noData
    case invalidURL
    case documentNotFound
    case noRestaurantsMatch
    case noLocationForAddress
    case badPhotoFile
    
    var errorDescription: String? {
        switch self {
        case .noUserFound:
            return "Unable to find user information"
        case .couldNotUnwrap:
            return "The cloud returned bad data"
        case .noSuchUser:
            return "There is no user with the given information registered with MemeThing"
        case .fsError(let error):
            return "Error fetching data from the cloud: \(error.localizedDescription)"
        case .thrownError(let error):
            return "Error fetching data from the cloud: \(error.localizedDescription)"
        case .noData:
            return "The necessary data is missing"
        case .invalidURL:
            return "There was a problem fetching the data from Yelp"
        case .documentNotFound:
            return "The necessary data is missing"
        case .noRestaurantsMatch:
            return "No restaurants match the given search"
        case .noLocationForAddress:
            return "The location was not found"
        case .badPhotoFile:
            return "Unable to save image to cloud"
        }
    }
}
