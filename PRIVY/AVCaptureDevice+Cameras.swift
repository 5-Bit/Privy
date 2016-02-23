//
//  AVCaptureDevice+Cameras.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    class func frontCamera() -> AVCaptureDevice? {
        return firstDeviceAtPosition(.Front, forMediaType: .Video)
    }

    class func backCamera() -> AVCaptureDevice? {
        return firstDeviceAtPosition(.Back, forMediaType: .Video)
    }
    
    private class func firstDeviceAtPosition(position: AVCaptureDevicePosition, forMediaType mediaType: AVMediaType) -> AVCaptureDevice? {
        let devices = devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        
        return devices.filter {
            $0.position == position
        }.first
    }
}