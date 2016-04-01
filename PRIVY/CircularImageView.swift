//
//  CircularImageView.swift
//  Privy
//
//  Created by Michael MacCallum on 4/1/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class CircularImageView: UIImageView {
    override var frame: CGRect {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = frame.width / 2.0
        }
    }
}
