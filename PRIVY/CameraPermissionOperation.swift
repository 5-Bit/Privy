//
//  CameraPermissionOperation.swift
//  Privy
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Privy. All rights reserved.
//

import UIKit
import AVFoundation


/**
 *
 */
class CameraPermissionOperation: ObservableOperation {
    let mediaType: AVMediaType
    
    private var rootViewController: UIViewController? {
        return (UIApplication.sharedApplication().delegate as? AppDelegate)?.window?.rootViewController
    }
    
    override var asynchronous: Bool {
        return true
    }
    
    required init(mediaType: AVMediaType) {
        self.mediaType = mediaType
    }
    
    override func start() {
        super.start()
        checkAuthorizationStatus()
    }

    /**
     *
     */
    private func checkAuthorizationStatus() {
        let status = AVCaptureDevice.authorizationStatusForMediaType(mediaType)

        switch status {
        case .Authorized:
            finished = true
        case .Denied:
            showEnableCameraDialog()
        case .NotDetermined:
            requestAuthorization()
            checkAuthorizationStatus()
        case .Restricted:
            showRestrictedDialog()
        }
    }
    
    /**
     <#Description#>
     */
    private func showEnableCameraDialog() {
        dispatch_async(dispatch_get_main_queue()) {
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { [unowned self] _ in
                self.cancel()
            }
            
            let confirmAction = UIAlertAction(title: "Settings", style: .Default) { [unowned self] _ in
                self.cancel()
                if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            
            let controller = UIAlertController(
                title: "Permission Denied",
                message: "Please enable camera permissions for this app in your settings",
                preferredStyle: .Alert
            )
            
            controller.addAction(cancelAction)
            controller.addAction(confirmAction)
            
            self.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    private func showRestrictedDialog() {
        dispatch_async(dispatch_get_main_queue()) {
            let dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel) { [unowned self] _ in
                self.cancel()
            }
            
            let controller = UIAlertController(
                title: "Restricted",
                message: "parental controls",
                preferredStyle: .Alert
            )
            
            controller.addAction(dismissAction)
            self.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    private func requestAuthorization() -> Bool {
        let semaphore = dispatch_semaphore_create(0)
        var succeeded = false
        AVCaptureDevice.requestAccessForMediaType(mediaType) { success in
            succeeded = success
            dispatch_semaphore_signal(semaphore)
        }
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return succeeded
    }
    
    override func waitUntilFinished() {
        fatalError("waitUntilFinished not implemented")
    }
}