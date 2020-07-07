//
//  CustomImageView.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ProfileImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(self.frame.height / 2)
        addBorder()
    }
}

class RestaurantImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(16)
    }
}
