//
//  AVCaptureDevice+Cameras.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    
    /**
     Enumerates all the available capture devices, attempting to get the one representing the front camera.
     
     - returns: An AVCaptureDevice representing the front camera, if one exists, otherwise nil.
     */
    class func frontCamera() -> AVCaptureDevice? {
        return firstDeviceAtPosition(.Front, forMediaType: .Video)
    }

    /**
     Enumerates all the available capture devices, attempting to get the one representing the back camera.
     
     - returns: An AVCaptureDevice representing the back camera, if one exists, otherwise nil.
     */
    class func backCamera() -> AVCaptureDevice? {
        return firstDeviceAtPosition(.Back, forMediaType: .Video)
    }
    
    /**
     Enumerates all the available capture devices, attempting to fine one that matches the input criteria.
     
     - parameter position:  The camera position to search for (e.g. .Front, .Back)
     - parameter mediaType: The media type that the camera at the given position should support.
     
     - returns: The first AVCapture device found that matches the given criteria, if none exists, nil.
     */
    private class func firstDeviceAtPosition(position: AVCaptureDevicePosition, forMediaType mediaType: AVMediaType) -> AVCaptureDevice? {
        let devices = devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        
        return devices.filter {
            $0.position == position
        }.first
    }
}