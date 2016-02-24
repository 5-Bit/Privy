//
//  RoundedTextField.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {
    override var bounds: CGRect {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = bounds.height / 2.0
        }
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
