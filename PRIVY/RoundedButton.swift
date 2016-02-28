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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        layer.masksToBounds = true
    }
    
    override var bounds: CGRect {
        didSet {
            applyRounding()
            applyGradient()
        }
    }

    override var frame: CGRect {
        didSet {
            applyRounding()
            applyGradient()
        }
    }

    private func applyRounding() {
        layer.cornerRadius = bounds.height / 2.0
    }
    
    private func applyGradient() {
        let colors = [UIColor.privyGradLeftColor.CGColor, UIColor.privyGradRightColor.CGColor]
        let stops = [0.0, 1.0]
        
        gradientLayer.colors = colors
        gradientLayer.locations = stops
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
}
