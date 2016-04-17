//
//  CaptureLayerView.swift
//  Privy
//
//  Created by Michael MacCallum on 2/21/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit.UIView
import AVFoundation.AVCaptureVideoPreviewLayer

/**
 A UIView backed by a AVCaptureVideoPreviewLayer instead of a CALayer. Used for rendering
 the output stream from the devices camera on screen.
 */
final class CaptureLayerView: UIView {

    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
