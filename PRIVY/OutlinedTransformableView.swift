//
//  OutlinedTransformableView.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class OutlinedTransformableView: UIView {
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
        shapeLayer.strokeColor = UIColor.greenColor().CGColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        
        clipsToBounds = true
        opaque = false
        userInteractionEnabled = false
    }
    
    private func drawAroundCorners() {
        guard let corners = corners where corners.count == 4 else {
            print("no corners or not 4 corners")
            return
        }
        
        let path = UIBezierPath()
        path.moveToPoint(corners[0])
        
        for index in 1..<corners.count {
            path.addLineToPoint(corners[index])
        }

        path.addLineToPoint(corners[0])
        
        shapeLayer.removeAllAnimations()
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
//        pathAnimation.toValue = path.CGPath
        pathAnimation.fromValue = (shapeLayer.presentationLayer() as? CAShapeLayer)?.path
        pathAnimation.duration = 0.05
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.removedOnCompletion = false
        
        shapeLayer.path = path.CGPath
        
        shapeLayer.addAnimation(pathAnimation, forKey: nil)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
}
