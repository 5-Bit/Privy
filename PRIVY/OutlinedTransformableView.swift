//
//  OutlinedTransformableView.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

/// Draws a view whose visible area is defined by shape resulting from the specification of 4 corner points.
final class OutlinedTransformableView: UIView {
    var corners: [CGPoint]? {
        didSet {
            drawAroundCorners()
        }
    }
    
    var shapeLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    override required init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        shapeLayer.strokeColor = UIColor.greenColor().colorWithAlphaComponent(0.5).CGColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.5).CGColor
        shapeLayer.shouldRasterize = false
        shapeLayer.masksToBounds = true
        shapeLayer.opaque = false

        userInteractionEnabled = false
    }
    
    private func drawAroundCorners() {
        guard let corners = corners where corners.count == 4 else {
            return
        }

        // Draw a path around the 4 input corners.
        let path = UIBezierPath()
        path.moveToPoint(corners[0])
        
        for index in 1..<corners.count {
            path.addLineToPoint(corners[index])
        }

        path.addLineToPoint(corners[0])
        
        shapeLayer.removeAllAnimations()

        // Animate the current path of the backing shape layer to the new path.
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = (shapeLayer.presentationLayer() as? CAShapeLayer)?.path
        pathAnimation.duration = 0.05
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.removedOnCompletion = false

        shapeLayer.path = path.CGPath
        
        shapeLayer.addAnimation(pathAnimation, forKey: nil)
    }

    // This view needs to be backed by a CAChapeLayer instead of the default CALayer.
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
}
