//
//  StyleGuide.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Common Formatting Functions

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

// MARK: - Custom Color Names

extension UIColor {
    static let background = UIColor(named: "background")!
    static let navBar = UIColor(named: "navBar")!
    static let navBarText = UIColor(named: "navBarText")!
    static let navBarButtonTint = UIColor(named: "navBarButtonTint")!
    static let textViewBackground = UIColor(named: "textViewBackground")!
    static let border = UIColor(named: "border")!
    static let mainText = UIColor(named: "mainText")!
    static let greenAccent = UIColor(named: "greenAccent")!
    static let redAccent = UIColor(named: "redAccent")!
    static let neutralAccent = UIColor(named: "neutralAccent")!
}

// MARK: - Font Names

struct FontNames {
    static let mainFont = ""
}
