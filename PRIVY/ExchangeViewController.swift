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
import CoreLocation

/// <#Description#>
class ExchangeViewController: UIViewController {
    private let locationManager = CLLocationManager()

    private let captureSession = AVCaptureSession()
    private let captureOutput = AVCaptureMetadataOutput()
    
    // Serial dispatch queue used for AVCaptureMetadataOutputObjectsDelegate callbacks.
    private let captureCallbackQueue = dispatch_queue_create("com.Privy.qrScan", DISPATCH_QUEUE_SERIAL)
    private let infoSwappingQueue = NSOperationQueue()
    
    /// Creates a QRGeneratorOperation on access.
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

    private var detectedStringsMapping = [String: (OutlinedTransformableView, NSDate)]()

    private var player: AVAudioPlayer?

    /*
     Property observers on qrCodeImage and qrCodeImageView guarentee that the QR code image
     is added to the view, regardless of whether or not it is done being generated by the time
     the imageView is added to the view hierarchy.
     */
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
    @IBOutlet private weak var primaryDetailLabel: UILabel!
    @IBOutlet private weak var secondaryDetailLabel: UILabel!
    @IBOutlet private weak var ternaryDetailLabel: UILabel!

    @IBOutlet private weak var captureOutputView: CaptureLayerView!
    @IBOutlet private weak var toggleCameraButton: UIButton!

    private var qrTimer: NSTimer?

    private weak var capturePreviewLayer: AVCaptureVideoPreviewLayer! {
        return captureOutputView.layer as! AVCaptureVideoPreviewLayer
    }

    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /**
     <#Description#>
     */
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
    
    /**
     <#Description#>
     */
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
    
    /**
     <#Description#>
     
     - parameter animated: <#animated description#>
     */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        infoSwappingQueue.addOperation(qrGenOperation)

        let basicInfo = PrivyUser.currentUser.userInfo.basic
        
        if let first = basicInfo.firstName, last = basicInfo.lastName {
            nameLabel.text = "\(first) \(last)"
        } else {
            nameLabel.text = nil
        }

        var candidates = [
            basicInfo.emailAddress, basicInfo.phoneNumber,
        ]

        let socialInfo = PrivyUser.currentUser.userInfo.social

        if let twitter = socialInfo.twitter {
            candidates.append("@" + twitter)
        } else {
            if let googlePlus = socialInfo.googlePlus {
                candidates.append("+" + googlePlus)
            } else {
                candidates.append(socialInfo.snapchat ?? socialInfo.instagram ?? socialInfo.facebook)
            }
        }

        let bloggingInfo = PrivyUser.currentUser.userInfo.blogging
        candidates.append(bloggingInfo.website ?? bloggingInfo.wordpress ?? bloggingInfo.tumblr ?? bloggingInfo.medium)

        let mediaInfo = PrivyUser.currentUser.userInfo.media
        candidates.append(mediaInfo.youtube ?? mediaInfo.vimeo ?? mediaInfo.vine ?? mediaInfo.soundcloud ?? mediaInfo.flickr ?? mediaInfo.pintrest)

        let devInfo = PrivyUser.currentUser.userInfo.developer
        candidates.append(devInfo.github ?? devInfo.stackoverflow ?? devInfo.bitbucket)

        var flattened = candidates.flatMap { $0 }

        primaryDetailLabel.text = flattened.removeFirst()
        secondaryDetailLabel.text = flattened.removeFirst()
        ternaryDetailLabel.text = flattened.removeFirst()


        #if os(iOS) && !(arch(i386) || arch(x86_64))
        captureSession.startRunning()
        
        let front = AVCaptureDevice.frontCamera()
        let back = AVCaptureDevice.backCamera()
        
        toggleCameraButton.hidden = front == nil || back == nil
        #else
        toggleCameraButton.hidden = true
        #endif

        locationManager.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if qrTimer?.valid ?? false {
            qrTimer?.invalidate()
        }

        qrTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(ExchangeViewController.qrTimerFired(_:)), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        qrTimer?.invalidate()
    }

    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        captureSession.stopRunning()
        locationManager.delegate = nil
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
        let keys = detectedStringsMapping.keys

        for key in keys {
            let (view, date) = detectedStringsMapping[key]!

            if date.timeIntervalSinceNow < -0.05 {
                view.removeFromSuperview()
            } else {
                if view.superview == nil {
                    captureOutputView.addSubview(view)
                }
            }
        }
    }

    /**
     <#Description#>
     
     - parameter button: <#button description#>
     */
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
        guard let transformed = capturePreviewLayer.transformedMetadataObjectForMetadataObject(object) as? AVMetadataMachineReadableCodeObject else {
            return
        }

        let outlineView: OutlinedTransformableView
        var firstDetection = false

        if let (view, _) = detectedStringsMapping[object.stringValue] {
            outlineView = view
        } else {
            firstDetection = true

            outlineView = OutlinedTransformableView(frame: captureOutputView.bounds)
            captureOutputView.addSubview(outlineView)

            player = try! AVAudioPlayer(
                contentsOfURL: NSBundle.mainBundle().URLForResource("success", withExtension: "mp3")!
            )
            player!.play()
        }

        // reset view and date associate with this QR string.
        detectedStringsMapping[object.stringValue] = (outlineView, NSDate())

        outlineView.corners = translatePoints(
            transformed.corners as! [NSDictionary]
        )

        let color: CGColor
        if let mapObject = Mapper<QRMapObject>().map(object.stringValue) {
            if firstDetection {
                for uuid in mapObject.uuids {
                    print(uuid)
                }

                RequestManager.sharedManager.attemptLookupByUUIDs(mapObject.uuids, completion: { (user, errorStatus) in
                    if let user = user, history = self.tabBarController?.viewControllers?.last as? HistoryTableViewController {
                        history.datasource.append(user)
                        print("adding to history")
                    }

                    print(user?.basic.firstName)
                })
            }

            color = UIColor.greenColor().colorWithAlphaComponent(0.5).CGColor
        } else {
            color = UIColor.redColor().colorWithAlphaComponent(0.5).CGColor
        }

        outlineView.shapeLayer.fillColor = color
        outlineView.shapeLayer.strokeColor = color
    }

    /**
     <#Description#>
     
     - parameter points: <#points description#>
     
     - returns: <#return value description#>
     */
    private func translatePoints(points: [NSDictionary]) -> [CGPoint] {
        return points.map {
            CGPoint(x: $0.objectForKey("X")!.doubleValue!, y: $0.objectForKey("Y")!.doubleValue!)
        }
    }
}

extension ExchangeViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            break
        case .Denied:
            showLocationErrorDialogWithMessage("Location unavailable. Please enable the location capability for this app in your settings.")
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .Restricted:
            showLocationErrorDialogWithMessage("Location unavailable. If you want to use this feature, ask your parent to disable this restriction.")
        }
    }

    private func showLocationErrorDialogWithMessage(message: String) {
        let alertController = UIAlertController(
            title: "",
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let dismissAction = UIAlertAction(
            title: "Dismiss",
            style: .Default) { action in

        }

        alertController.addAction(dismissAction)

        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension ExchangeViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }

    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        player.pause()
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        self.player = nil
    }

    func audioPlayerEndInterruption(player: AVAudioPlayer) {
        if player.prepareToPlay() {
            player.play()
        }
    }
}
