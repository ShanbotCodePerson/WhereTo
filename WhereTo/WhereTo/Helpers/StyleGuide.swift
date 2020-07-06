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
    
    func addBorder(width: CGFloat = 2, color: UIColor = .border) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
}

// MARK: - Custom Color Names

extension UIColor {
    static let background = UIColor(named: "background")!
    static let navBar = UIColor(named: "navBar")!
    static let navBarFaded = UIColor(named: "navBarFaded")!
    static let navBarText = UIColor(named: "navBarText")!
    static let navBarButtonTint = UIColor(named: "navBarButtonTint")!
    static let tabBarUnselected = UIColor(named: "tabBarUnselected")!
    static let textViewBackground = UIColor(named: "textViewBackground")!
    static let cellBackground = UIColor(named: "cellBackground")!
    static let cellBackgroundSelected = UIColor(named: "cellBackgroundSelected")!
    static let separator = UIColor(named: "separator")!
    static let border = UIColor(named: "border")!
    static let mainText = UIColor(named: "mainText")!
    static let subtitleText = UIColor(named: "subtitleText")!
    static let greenAccent = UIColor(named: "greenAccent")!
    static let redAccent = UIColor(named: "redAccent")!
    static let neutralAccent = UIColor(named: "neutralAccent")!
    static let whiteAccent = UIColor(named: "whiteAccent")!
    static let loginScreen = UIColor(named: "loginScreen")!
    static let activityIndicatorBackground = UIColor(named: "activityIndicatorBackground")!
    static let activityIndicator = UIColor(named: "activityIndicator")!
}

// MARK: - Font Names

enum FontNames: String {
    case mainFont = "Arial"
    case boldFont = "Arial-BoldMT"
}
