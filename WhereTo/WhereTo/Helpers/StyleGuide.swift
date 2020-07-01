//
//  StyleGuide.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func addCornerRadius(_ radius: CGFloat = 8) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    func addBorder(width: CGFloat = 2, color: UIColor = .darkGray) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
}

extension UIColor {
    static let background = UIColor(named: "background")!
    static let navBar = UIColor(named: "navBar")!
    static let navBarText = UIColor(named: "navBarText")!
    static let navBarButtonTint = UIColor(named: "navBarButtonTint")!
}

struct FontNames {
    static let mainFont = ""
}
