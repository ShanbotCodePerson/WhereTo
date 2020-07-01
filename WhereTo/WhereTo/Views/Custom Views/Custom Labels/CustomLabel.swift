//
//  CustomLabel.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UILabel {
    func setUpViews(textColor: UIColor = .mainText, fontSize: CGFloat = 20, fontName: String = FontNames.mainFont) {
        
        numberOfLines = 0
        self.textColor = textColor
        font = UIFont(name: fontName, size: fontSize)
    }
}

class DefaultLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
}

class HeaderLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
