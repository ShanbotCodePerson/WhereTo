//
//  CustomButton.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIButton {
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 2, borderColor: UIColor = .border, backgroundColor: UIColor = .white, textColor: UIColor = .white, tintColor: UIColor = .darkGray, fontSize: CGFloat = 22, fontName: String = FontNames.mainFont) {
        
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
        self.tintColor = tintColor
        titleLabel?.font = UIFont(name: fontName, size: fontSize)
    }
    
    func deactivate() {
        isUserInteractionEnabled = false
        isEnabled = false
        backgroundColor = backgroundColor?.withAlphaComponent(0.5)
    }
    
    func activate() {
        isUserInteractionEnabled = true
        isEnabled = true
        backgroundColor = backgroundColor?.withAlphaComponent(1)
    }
}

class GoButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .systemGreen)
    }
}

class DeleteButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .systemRed)
    }
}

class NeutralButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .gray)
    }
}

class EditButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class SearchButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class ToggleButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
