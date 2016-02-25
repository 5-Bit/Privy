//
//  PRVExchangeViewController.swift
//  PRIVY
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import DynamicButton
import NVActivityIndicatorView
import AVFoundation
import ObjectMapper

class ExchangeViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private let captureOutput = AVCaptureMetadataOutput()
    private let captureCallbackQueue = dispatch_queue_create("com.Privy.qrScan", DISPATCH_QUEUE_SERIAL)

    private var trackingMetadataObject: AVMetadataMachineReadableCodeObject?
    
    private let infoSwappingQueue = NSOperationQueue()
    private var qrGenOperation: QRGeneratorOperation {
        return QRGeneratorOperation(
            qrString: PrivyUser.currentUser.qrString,
            size: self.qrCodeImageView?.bounds.size ?? CGSize(width: 151, height: 151),
            scale: UIScreen.mainScreen().scale,
            correctionLevel: .Medium) { (image) in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.qrCodeImage = image
                    print(PrivyUser.currentUser.qrString)
                }
        }
    }
    
    private var qrCodeImage: UIImage? {
        didSet {
            qrCodeImageView?.image = qrCodeImage
        }
    }
    
    @IBOutlet private weak var qrCodeImageView: UIImageView! {
        didSet {
            qrCodeImageView?.image = qrCodeImage
        }
    }
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailAddressLabel: UILabel!
    @IBOutlet private weak var phoneNumberLabel: UILabel!
    
    @IBOutlet private weak var captureOutputView: CaptureLayerView!
    @IBOutlet private weak var captureOutlineView: OutlinedTransformableView!
    @IBOutlet private weak var toggleCameraButton: UIButton!
    
    private var shouldContinueScanning = true
    
    private weak var capturePreviewLayer: AVCaptureVideoPreviewLayer! {
        return captureOutputView.layer as! AVCaptureVideoPreviewLayer
    }
    
    private var qrTimer: NSTimer?
//    @IBOutlet private weak var closeButton: DynamicButton! {
//        didSet {
//            closeButton.setStyle(DynamicButton.Style.Close, animated: false)
//
//            closeButton.lineWidth           = 2
//            closeButton.strokeColor         = UIColor.privyLightBlueColor
//            closeButton.highlightStokeColor = UIColor.whiteColor()
//            closeButton.backgroundColor     = UIColor.whiteColor()
//            closeButton.layer.cornerRadius  = closeButton.bounds.width / 2.0
//            closeButton.layer.masksToBounds = true
//        }
//    }
    
//    @IBOutlet private weak var loadingIndicator: NVActivityIndicatorView! {
//        didSet {
//            loadingIndicator.type = NVActivityIndicatorType.BallClipRotateMultiple
//            loadingIndicator.hidesWhenStopped = true
//            loadingIndicator.size = loadingIndicator.bounds.size
//        }
//    }
    
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        #if os(iOS) && !(arch(i386) || arch(x86_64))
        guard let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(.Video) else {
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            } else {
                print("adding input failed")
            }
        } catch {
            return
        }
        #endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #if os(iOS) && !(arch(i386) || arch(x86_64))
        capturePreviewLayer.session = captureSession
        capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        if captureSession.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
            
            captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            captureOutput.setMetadataObjectsDelegate(self, queue: captureCallbackQueue)
        }
        #endif
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        infoSwappingQueue.addOperation(qrGenOperation)

        let basicInfo = PrivyUser.currentUser.userInfo.basic
        
        if let first = basicInfo.firstName, last = basicInfo.lastName {
            nameLabel.text = "\(first) \(last)"
        } else {
            nameLabel.text = nil
        }

        if let email = basicInfo.emailAddress {
            emailAddressLabel.text = email
        } else {
            emailAddressLabel.text = nil
        }
        
        if let phone = basicInfo.phoneNumber {
            phoneNumberLabel.text = phone
        } else {
            phoneNumberLabel.text = nil
        }
        
        #if os(iOS) && !(arch(i386) || arch(x86_64))
        captureSession.startRunning()
        
        let front = AVCaptureDevice.frontCamera()
        let back = AVCaptureDevice.backCamera()
        
        toggleCameraButton.hidden = front == nil || back == nil
        #else
        toggleCameraButton.hidden = true
        #endif
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        shouldContinueScanning = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        captureSession.stopRunning()
        qrTimer?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }

    @objc private func qrTimerFired(timer: NSTimer) {
        captureOutlineView.hidden = true
    }
    
    @IBAction private func toggleCameraButtonTapped(button: UIButton) {
        #if os(iOS) && !(arch(i386) || arch(x86_64))
        captureSession.beginConfiguration()

        let deviceInputs = captureSession.inputs.flatMap { $0 as? AVCaptureDeviceInput }
        
        var newPosition = AVCaptureDevicePosition.Unspecified
        for deviceInput in deviceInputs {
            if deviceInput.device.position == .Front {
                newPosition = .Back
                break
            }
            
            if deviceInput.device.position == .Back {
                newPosition = .Front
                break
            }
        }

        captureSession.removeInput(captureSession.inputs.first as! AVCaptureInput)

        guard let captureDevice = newPosition == .Front ? AVCaptureDevice.frontCamera() : AVCaptureDevice.backCamera() else {
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            } else {
                print("adding input failed")
            }
        } catch {
            return
        }

        if captureSession.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        }

        captureSession.commitConfiguration()
        #endif
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

extension ExchangeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        let readableObjects = metadataObjects.flatMap { $0 as? AVMetadataMachineReadableCodeObject }
        
        for readableObject in readableObjects where readableObject.type == AVMetadataObjectTypeQRCode && readableObject.stringValue != nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.detectedReadableObject(readableObject)
            }
        }
    }
    
    private func detectedReadableObject(object: AVMetadataMachineReadableCodeObject) {
        guard shouldContinueScanning else {
            return
        }
        
        trackingMetadataObject = object
        
        guard let transformed = capturePreviewLayer.transformedMetadataObjectForMetadataObject(object) as? AVMetadataMachineReadableCodeObject else {
            return
        }
        
        captureOutlineView.hidden = false
        captureOutlineView.corners = translatePoints(
            transformed.corners as! [NSDictionary]
        )
        
        if qrTimer?.valid ?? false {
            qrTimer?.invalidate()
        }
        
        qrTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "qrTimerFired:", userInfo: nil, repeats: false)
        
        if let mapObject = Mapper<QRMapObject>().map(object.stringValue) {
            print("+++++++++++++++++++++++parsed successfully")
            shouldContinueScanning = false
            RequestManager.sharedManager.attemptLookupByUUIDs(mapObject.uuids, completion: { (user, errorStatus) in
                if let user = user, history = self.tabBarController?.viewControllers?.last as? HistoryTableViewController {
                    history.datasource.append(user)
                    print("adding to history")
                }
                
                print(user?.basic.firstName)
            })
        }
    }
    
    private func translatePoints(points: [NSDictionary]) -> [CGPoint] {
        return points.map {
            CGPoint(x: $0.objectForKey("X")!.doubleValue!, y: $0.objectForKey("Y")!.doubleValue!)
        }
    }
}





