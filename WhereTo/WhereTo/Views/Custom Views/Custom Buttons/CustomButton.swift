//
//  CustomButton.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIButton {
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 2, borderColor: UIColor = .border, backgroundColor: UIColor = .white, backgroundOpacity: CGFloat = 1, textColor: UIColor = .white, tintColor: UIColor = .darkGray, fontSize: CGFloat = 22, fontName: FontNames = .mainFont) {
        
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor.withAlphaComponent(backgroundOpacity)
        setTitleColor(textColor, for: .normal)
        self.tintColor = tintColor
        titleLabel?.font = UIFont(name: fontName.rawValue, size: fontSize)
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

class ButtonWithBackground: UIButton {
    override var intrinsicContentSize: CGSize { return addInsets(to: super.intrinsicContentSize) }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + 12
        let height = size.height + 6
        return CGSize(width: width, height: height)
    }
}

class GoButton: ButtonWithBackground {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .greenAccent, fontName: .boldFont)
    }
}

class DeleteButton: ButtonWithBackground {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .redAccent, fontName: .boldFont)
    }
}

class NeutralButton: ButtonWithBackground {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .neutralAccent, fontName: .boldFont)
    }
}

class EditButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 16, borderWidth: 0, backgroundColor: .white, backgroundOpacity: 0.6, textColor: .darkGray)
    }
    
    override var intrinsicContentSize: CGSize { return addInsets(to: super.intrinsicContentSize) }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + 12
        let height = size.height + 2
        return CGSize(width: width, height: height)
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
