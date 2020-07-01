//
//  HelperFunctions.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    mutating func uniqueAppend(_ element: Element) {
        var currentList = self
        currentList.append(element)
        self = Array(Set(currentList))
    }
}
