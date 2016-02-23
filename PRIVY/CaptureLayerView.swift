//
//  CaptureLayerView.swift
//  Privy
//
//  Created by Michael MacCallum on 2/21/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit.UIView
import AVFoundation.AVCaptureVideoPreviewLayer

class CaptureLayerView: UIView {

    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
