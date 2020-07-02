//
//  CustomTextField.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addCornerRadius()
        addBorder()
        backgroundColor = .textViewBackground
        
    }
}
