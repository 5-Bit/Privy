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

/// An NSOperation subclass that generates a UIImage representing a QR code from an input string/size/scale.
class QRGeneratorOperation: ObservableOperation {
    private let qrString: String
    private let size: CGSize
    private let scale: CGFloat
    private let correctionLevel: QrCorrectionLevel
    private let completionHandler: UIImage? -> Void
    private let queue = dispatch_queue_create("com.Privy.QRGeneratorOperation.queue", DISPATCH_QUEUE_SERIAL)

    /// Used exclusively by `waitUntilFinished`
    private let semaphore = dispatch_semaphore_create(0)
    
    override var asynchronous: Bool {
        return true
    }
    
    /**
     Creates a QRGeneratorOperation from the input data. Calls the given completion handler when done.
     
     - parameter qrString:          An arbitrary String to be encoded into a QR code. This string is expected
                                    to be encoded using ISO Latin 1 encoding.
     - parameter size:              The size the output image should be rendered as, in points.
     - parameter scale:             The scale factor to apply to the output image. If for example, a size
                                    of 300x300 is specificed with a scale factor of 2, the resultant image
                                    will be 600x600 pixels.
     - parameter correctionLevel:   See the QRCorrectionLevel enum.
     - parameter completionHandler: Called after the operation has finished. If the operation successfully
                                    created a QR code, a UIImage will be given. Otherwise, the closure's
                                    parameter will be nil.
     */
    required init(qrString: String, size: CGSize = CGSize(width: 151.0, height: 151.0), scale: CGFloat = 1.0, correctionLevel: QrCorrectionLevel = .High, completionHandler: UIImage? -> Void) {
        self.qrString = qrString
        self.size = size
        self.scale = scale
        self.correctionLevel = correctionLevel
        self.completionHandler = completionHandler
    }
    
    override func start() {
        super.start()

        if let image = QRGeneratorOperation.imageFromQrString(self.qrString, size: self.size, scale: self.scale, correctionLevel: self.correctionLevel) {
            self.finished = true

            self.completionHandler(image)
            return
        } else {
            self.cancel()
            self.completionHandler(nil)
        }
        
        dispatch_semaphore_signal(self.semaphore)
    }
    
    override func waitUntilFinished() {
        if let semaphore = semaphore {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        super.waitUntilFinished()
    }

    /**
     Generates a UIImage representation of a QR code from the input data at the input size and scale.
     Returns nil if not successful.
     */
    private static func imageFromQrString(qrString: String, size: CGSize, scale: CGFloat, correctionLevel: QrCorrectionLevel) -> UIImage? {
        guard let isoLatin = qrString.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion: false) else {
            return nil
        }
        
        // If we can't create a CIQRCodeGenerator filter, fail.
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(isoLatin, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        // If the filter didn't generate an output image, fail.
        guard let outputImage = filter.outputImage else {
            return nil
        }

        let inverted = QRGeneratorOperation.invertImage(outputImage)

        let background = UIColor(
            red: 30.0 / 255.0,
            green: 179.0 / 255.0,
            blue: 225.0 / 255.0,
            alpha: 1.0
        )

        let uiInverted = UIImage(CIImage: inverted)
        let colored = uiInverted.tintedImageWithColor(UIColor.privyDarkBlueColor)

        return upscaledImageFromCIImage(
            CIImage(CGImage: colored.CGImage!),
            size: size,
            scale: scale
        )
    }

    private static func invertImage(image: CIImage) -> CIImage {
//        filter = [CIFilter filterWithName:@"CIAdditionCompositing" keysAndValues:kCIInputImageKey, imageOne, kCIInputBackgroundImageKey, imageTwo, nil];

        let filter = CIFilter(
            name: "CIColorInvert",
            withInputParameters: [kCIInputImageKey: image]
        )!

        return filter.outputImage!
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
