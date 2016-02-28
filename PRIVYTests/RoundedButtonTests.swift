//
//  RoundedButtonTests.swift
//  Privy
//
//  Created by Michael MacCallum on 2/25/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import XCTest
@testable import Privy

class RoundedButtonTests: XCTestCase {
    let button = RoundedGradientButton(type: UIButtonType.System)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCommonInit() {
        XCTAssert(button.layer.masksToBounds)
    }
    
    func testApplyRounding() {
        var size: CGFloat = 100.0
        button.bounds = CGRect(x: 0.0, y: 0.0, width: size, height: size)
        XCTAssert(button.layer.cornerRadius == size / 2.0)
        
        size = 120.0
        button.frame = CGRect(x: 0.0, y: 0.0, width: size, height: size)
        XCTAssert(button.layer.cornerRadius == size / 2.0)
    }

    func testApplyGradient() {
        let colors = [UIColor.privyGradLeftColor.CGColor, UIColor.privyGradRightColor.CGColor]
        
        guard let gradientLayer = button.layer as? CAGradientLayer else {
            XCTFail()
            return
        }
        
        guard let gradColors = gradientLayer.colors as? [CGColor] else {
            XCTFail()
            return
        }
        
        let equal = zip(colors, gradColors).reduce(true) { (current, color) -> Bool in
            return current && CGColorEqualToColor(color.0, color.1)
        }
        
        XCTAssert(equal)
    }
}
