//
//  CustomLabel.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UILabel {
    func setUpViews(cornerRadius: CGFloat = 8, textColor: UIColor = .black, fontSize: CGFloat = 20, fontName: String = FontNames.mainFont) {
        
        numberOfLines = 0
        self.textColor = textColor
        font = UIFont(name: fontName, size: fontSize)
    }
}

class CustomLabel: UILabel {

    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
}
