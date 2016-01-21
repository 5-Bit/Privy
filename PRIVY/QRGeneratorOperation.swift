//
//  QRGeneratorOperation.swift
//  Privy
//
//  Created by Michael MacCallum on 1/18/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics

typealias QRGeneratorCompletion = UIImage? -> Void

class QRGeneratorOperation: ObservableOperation {
    private let data: NSData
    private let size: CGSize
    private let scale: CGFloat
    private let completionHandler: QRGeneratorCompletion
    
    override var asynchronous: Bool {
        return true
    }
    
    required init(data: NSData, size: CGSize = CGSize(width: 151.0, height: 151.0), scale: CGFloat = 1.0, completionHandler: QRGeneratorCompletion) {
        self.data = data
        self.size = size
        self.scale = scale
        self.completionHandler = completionHandler
    }
    
    override func start() {
        super.start()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            if let image = QRGeneratorOperation.imageFromData(self.data, size: self.size, scale: self.scale) {
                self.finished = true
                self.completionHandler(image)
                return
            } else {
                self.cancel()
                self.completionHandler(nil)
            }
        }
    }
    
    /**
     <#Description#>
     
     - parameter data:  <#data description#>
     - parameter size:  <#size description#>
     - parameter scale: <#scale description#>
     
     - returns: <#return value description#>
     */
    static func imageFromData(data: NSData, size: CGSize, scale: CGFloat) -> UIImage? {
        let options: NSDataBase64EncodingOptions = [.EncodingEndLineWithCarriageReturn, .EncodingEndLineWithLineFeed]
        let base64 = data.base64EncodedStringWithOptions(options)
        
        // If we fail to encoded the base 64 data as ISO Latin 1, fail.
        guard let isoLatin = base64.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion: false) else {
            return nil
        }
        
        // If we can't create a CIQRCodeGenerator filter, fail.
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(isoLatin, forKey: "inputMessage")
        filter.setValue(QrCorrectionLevel.High, forKey: "inputCorrectionLevel")
        
        // If the filter didn't generate an output image, fail.
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        return upscaledImageFromCIImage(outputImage,
            size: size,
            scale: scale
        )
    }
    
    /**
     Attempts to create an upscaled version of the input CIImage and returns it as a UIImage.
     
     - parameter inputImage: A CIImage representing a QR code.
     - parameter size:       The size of the output image in points.
     - parameter scale:      The scale factor that should be applied to the size.
     
     - returns: If the upscaling was successful, a UIImage object representing a non-interpolated upscaled
     version of the input QR code. If anything goes wrong along the way, this method returns nil.
     */
    private static func upscaledImageFromCIImage(inputImage: CIImage, size: CGSize, scale: CGFloat) -> UIImage? {
        // Convert the input CIImage into a CGImage that we can work with.
        let cgImage = CIContext().createCGImage(inputImage, fromRect: inputImage.extent)
        
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        
        // Make sure the context is ended upon return from this method.
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // Disable interpolation. We want exact upscaling and don't want to distort the QR code.
        CGContextSetInterpolationQuality(context, .None);
        // Draw the input image in the full size of the context.
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
