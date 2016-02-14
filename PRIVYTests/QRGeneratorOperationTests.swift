//
//  QRGeneratorOperationTests.swift
//  Privy
//
//  Created by Michael MacCallum on 1/25/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

@testable import Privy
import XCTest

class QRGeneratorOperationTests: XCTestCase {
    let queue = NSOperationQueue()
    
    override func setUp() {
        super.setUp()

        queue.maxConcurrentOperationCount = 1
    }
    
    func opFactory(expectation: XCTestExpectation? = nil) -> QRGeneratorOperation {
        return QRGeneratorOperation(
            qrString: "Hello, I'm a string!!",
            size: CGSize(width: 300.0, height: 300.0),
            scale: UIScreen.mainScreen().scale,
            correctionLevel: .High) { image in
                if let image = image {
                    let data = UIImagePNGRepresentation(image)!
                    print(NSByteCountFormatter.stringFromByteCount(Int64(data.length), countStyle: .File))
                    expectation?.fulfill()
                }
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testQRGen() {
        let expectation = expectationWithDescription("qr")
        queue.addOperation(opFactory(expectation))
        waitForExpectationsWithTimeout(5.0) { (error) -> Void in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
//    func testWaitUntilFinished() {
//        let expectation = expectationWithDescription("wait")
//        
//        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
//            self.queue.addOperation(self.operation)
//            XCTAssertFalse(self.operation.finished)
//            XCTAssertFalse(self.operation.cancelled)
//            self.operation.waitUntilFinished()
//            XCTAssertTrue(self.operation.finished)
//            expectation.fulfill()
//        }
//
//        waitForExpectationsWithTimeout(10.0) { error in
//            if let error = error {
//                XCTFail("testWaitUntilFinished failed: \(error)")
//            }
//        }
//    }
}
