//
//  QRScanOperation.swift
//  Privy
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Privy. All rights reserved.
//

import UIKit
import AVFoundation

typealias QRScanCompletion = String -> Void

class QRScanOperation: ObservableOperation {
    private let session = AVCaptureSession()
    private let device: AVCaptureDevice
    private let completionHandler: QRScanCompletion
    private var delegateQueue: dispatch_queue_t!

    override var asynchronous: Bool {
        return true
    }
    
    required init(captureDevice: AVCaptureDevice, completionHandler: QRScanCompletion) {
        self.device = captureDevice
        self.completionHandler = completionHandler

        super.init()
    }

    
    override func start() {
        super.start()
        session.beginConfiguration()
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        
            let attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qualityOfService.toQosClass(), 0)
            delegateQueue = dispatch_queue_create("com.QRScanOpeartion.delegateQueue", attributes)

            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            output.setMetadataObjectsDelegate(self, queue: delegateQueue)

            session.commitConfiguration()
            session.startRunning()
        } else {
            session.commitConfiguration()
        }
    }
    
    override func cancel() {
        session.stopRunning()
        super.cancel()
    }
    
    override func waitUntilFinished() {
        fatalError("waitUntilFinished not implemented")
    }
}

extension QRScanOperation: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        let metadataObjects = metadataObjects as! [AVMetadataObject]
        
        for metaData in metadataObjects where metaData.type == AVMetadataObjectTypeQRCode {
            if let stringValue = (metaData as? AVMetadataMachineReadableCodeObject)?.stringValue {
                completionHandler(stringValue)
                finished = true
                break
            }
        }
    }
}


















