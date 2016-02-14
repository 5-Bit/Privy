//
//  MockupQRReaderViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/11/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import AVFoundation

class MockupQRReaderViewController: UIViewController {
    private let session = AVCaptureSession()
    private var device: AVCaptureDevice!

    @IBOutlet private weak var outputTextView: UITextView!
    @IBOutlet private weak var captureView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
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
            
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            session.commitConfiguration()
            session.startRunning()
        

        } else {
            session.commitConfiguration()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        captureView.layer.addSublayer(previewLayer)
        previewLayer.frame = captureView.layer.bounds

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MockupQRReaderViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        let metadataObjects = metadataObjects as! [AVMetadataObject]
        
        for metaData in metadataObjects where metaData.type == AVMetadataObjectTypeQRCode {
            if let stringValue = (metaData as? AVMetadataMachineReadableCodeObject)?.stringValue {
                outputTextView.text = stringValue
            }
        }
    }
}

