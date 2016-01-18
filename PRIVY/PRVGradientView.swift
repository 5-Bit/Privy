//
//  PRVGradientView.swift
//  PRIVY
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class PRVGradientView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        applyDefaultGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        applyDefaultGradient()
    }
    
    private func applyDefaultGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else {
            return
        }
        
        gradientLayer.colors = [UIColor.appDarkBlueColor().CGColor, UIColor.appLightBlueColor().CGColor]
        gradientLayer.locations = [0.0, 1.0]
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
}
