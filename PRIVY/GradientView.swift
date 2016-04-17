//
//  GradientView.swift
//  Privy
//
//  Created by Michael MacCallum on 3/30/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

final class GradientView: UIView {
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // dark 25, 154, 215    light 30, 179, 225
        let start = UIColor(
            red: 25.0 / 255.0,
            green: 104.0 / 255.0,
            blue: 165.0 / 255.0,
            alpha: 1.0
        )

        let end = UIColor(
            red: 3.0 / 255.0,
            green: 33.0 / 255.0,
            blue: 85.0 / 255.0,
            alpha: 1.0
        )

        let colors = [start.CGColor, end.CGColor]
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
