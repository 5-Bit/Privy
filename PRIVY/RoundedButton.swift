//
//  RoundedButton.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class RoundedGradientButton: UIButton {
    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override var bounds: CGRect {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = bounds.height / 2.0

            let leftColor = UIColor(
                red: 117.0 / 255.0,
                green: 219.0 / 255.0,
                blue: 156.0 / 255.0,
                alpha: 1.0
            )

            let rightColor = UIColor(
                red: 92.0 / 255.0,
                green: 199.0 / 255.0,
                blue: 238.0 / 255.0,
                alpha: 1.0
            )
            
            let colors = [leftColor.CGColor, rightColor.CGColor]
            let stops = [0.0, 1.0]
            
            gradientLayer.colors = colors
            gradientLayer.locations = stops
            
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        }
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
}
