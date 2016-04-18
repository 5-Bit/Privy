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

private enum DetectionStatus {
    case Unknown, Failed, Succeeded, Pending, Processed
}

/// <#Description#>
final class ExchangeViewController: UIViewController {
    private let locationManager = CLLocationManager()

    private let captureSession = AVCaptureSession()
    private let captureOutput = AVCaptureMetadataOutput()
    
    // Serial dispatch queue used for AVCaptureMetadataOutputObjectsDelegate callbacks.
    private let captureCallbackQueue = dispatch_queue_create("com.Privy.qrScan", DISPATCH_QUEUE_SERIAL)
    private let infoSwappingQueue = NSOperationQueue()

    private var detectedStringsMapping = [String: (OutlinedTransformableView, NSDate, DetectionStatus)]()

    private var player: AVAudioPlayer?
    private var lastKnownLocation: CLLocation?

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

    @IBOutlet private weak var cardBackgroundView: UIView!

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
    
    private func commonInit() {
        // Only attempt to setup the capture session if we're running on a real device. No support in simulator.
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


        // Only attempt to setup the preview layer if we're running on a real device. No support in simulator.
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

    private func applyCurrentTheme() {
        let currentTheme = ThemeManager.defaultManager.defaultTheme
        let primaryColor = UIColor(CGColor: currentTheme.primaryColor.CGColor)
        let secondaryColor = UIColor(CGColor: currentTheme.secondaryColor.CGColor)

        nameLabel.textColor = primaryColor
        primaryDetailLabel.textColor = primaryColor
        secondaryDetailLabel.textColor = primaryColor
        ternaryDetailLabel.textColor = primaryColor

        cardBackgroundView.backgroundColor = secondaryColor

        regenerateQrCode()
    }

    private func regenerateQrCode() {
        let operation = QRGeneratorOperation(
            qrString: PrivyUser.currentUser.qrString,
            size: self.qrCodeImageView?.bounds.size ?? CGSize(width: 151, height: 151),
            scale: UIScreen.mainScreen().scale,
            correctionLevel: .Medium,
            backgroundColor: ThemeManager.defaultManager.defaultTheme.secondaryColor) { image in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.qrCodeImage = image
                }
        }

        infoSwappingQueue.addOperation(operation)
    }

    /**
     <#Description#>
     
     - parameter animated: <#animated description#>
     */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        applyCurrentTheme()

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

        let fields = [primaryDetailLabel, secondaryDetailLabel, ternaryDetailLabel]

        for field in fields {
            if flattened.count > 0 {
                field.text = flattened.removeFirst()
            } else {
                field.text = nil
            }
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

        if qrTimer?.valid ?? false {
            qrTimer?.invalidate()
        }

        qrTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(ExchangeViewController.qrTimerFired(_:)), userInfo: nil, repeats: true)

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        qrTimer?.invalidate()
    }

    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        captureSession.stopRunning()
        locationManager.stopUpdatingLocation()
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

        for (view, date, status) in detectedStringsMapping.values {

            if date.timeIntervalSinceNow < -0.05 {
                view.removeFromSuperview()
            } else {
                if view.superview == nil {
                    captureOutputView.addSubview(view)
                }
            }

            let fillColor: UIColor
            let borderColor: UIColor
            let backgroundColor: UIColor

            switch status {
            case .Unknown:
                fillColor = UIColor.clearColor()
                borderColor = UIColor.clearColor()
                backgroundColor = UIColor.clearColor()
            case .Failed:
                fillColor = UIColor.redColor()
                borderColor = UIColor.redColor()
                backgroundColor = UIColor.clearColor()
            case .Succeeded, .Pending:
                fillColor = UIColor.clearColor()
                borderColor = UIColor.greenColor()
                backgroundColor = UIColor.blackColor()
            case .Processed:
                fillColor = UIColor.greenColor()
                borderColor = UIColor.greenColor()
                backgroundColor = UIColor.blackColor()
            }

            UIView.animateWithDuration(
                0.05,
                delay: 0.0,
                options: .BeginFromCurrentState,
                animations: { 
                    view.shapeLayer.fillColor = fillColor.colorWithAlphaComponent(0.5).CGColor
                    view.shapeLayer.borderColor = borderColor.colorWithAlphaComponent(0.5).CGColor
                    view.shapeLayer.backgroundColor = backgroundColor.colorWithAlphaComponent(0.25).CGColor
                },
                completion: nil
            )
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

        if let (view, _, _) = detectedStringsMapping[object.stringValue] {
            outlineView = view
        } else {

            outlineView = OutlinedTransformableView(frame: captureOutputView.bounds)
            captureOutputView.addSubview(outlineView)

            player = try! AVAudioPlayer(
                contentsOfURL: NSBundle.mainBundle().URLForResource("success", withExtension: "mp3")!
            )
            player!.play()
        }

        // reset view and date associate with this QR string.
        let oldState = detectedStringsMapping[object.stringValue]?.2 ?? DetectionStatus.Unknown
        detectedStringsMapping[object.stringValue] = (outlineView, NSDate(), oldState)

        outlineView.corners = translatePoints(
            transformed.corners as! [NSDictionary]
        )

        guard let mapObject = Mapper<QRMapObject>().map(object.stringValue) else {
            var (view, date, state) = self.detectedStringsMapping[object.stringValue]!
            state = .Failed
            self.detectedStringsMapping[object.stringValue] = (view, date, state)

            return
        }

        var (view, date, state) = self.detectedStringsMapping[object.stringValue]!

        guard state != .Processed && state != .Pending else {
            return
        }

        state = .Pending
        detectedStringsMapping[object.stringValue] = (view, date, state)

        var history = LocalStorage.defaultStorage.loadHistory()

        RequestManager.sharedManager.attemptLookupByUUIDs(mapObject.uuids, inLocation: lastKnownLocation) { (user, errorStatus) in

            var (view, date, state) = self.detectedStringsMapping[object.stringValue]!
            if var user = user {
                user.location = HistoryUser.Location(
                    latitude: self.lastKnownLocation?.coordinate.latitude,
                    longitude: self.lastKnownLocation?.coordinate.longitude
                )

                if !history.contains(user) {
                    history.append(user)
                    LocalStorage.defaultStorage.saveHistory(history)

                    self.tabBarController?.tabBar.items?.last?.badgeValue = "New"
                }

                state = .Processed
            } else {
                state = .Succeeded
            }

            self.detectedStringsMapping[object.stringValue] = (view, date, state)
        }
    }

    /**
     Maps an AVFoundation points dictionary map into a consumable CGPoint Array.
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

    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        lastKnownLocation = newLocation
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
