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
    
}
