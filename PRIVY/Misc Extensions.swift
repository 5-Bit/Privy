//
//  Misc Extensions.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

// MARK: - NSMutableURLRequest
extension NSMutableURLRequest {
    func addValue(value: String, forHTTPHeaderField field: PrivyHttpHeaderField) {
        addValue(value, forHTTPHeaderField: field.rawValue)
    }
}

// MARK: - NSURL
extension NSURL {
    /**
     Creates a new NSURL by appending queryItems to the receiver.
     */
    func urlByAppendingQueryItems(queryItems: [NSURLQueryItem]) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        return components!.URL!
    }
}

// MARK: - NSData
extension NSData {
    /**
     Creates a Hex encoded string representative of the receiver.
     */
    func hexString() -> String {
        guard length > 0 else {
            return ""
        }

        let kHexChars = [UInt8]("0123456789abcdef".utf8)
        let buffer = UnsafeBufferPointer<UInt8>(
            start: UnsafePointer(bytes),
            count: length
        )

        var output = [UInt8](
            count: length * 2 + 1,
            repeatedValue: 0
        )

        var i = 0
        for b in buffer {
            let h = Int((b & 0xf0) >> 4)
            let l = Int(b & 0x0f)

            output[i] = kHexChars[h]
            i = i.successor()
            output[i] = kHexChars[l]
            i = i.successor()
        }

        return String.fromCString(UnsafePointer(output))!
    }
}

// MARK: - UIImage
extension UIImage {
    /**
     Returns the receiver after applying color as a tint use a screen blend mode.
     */
    func tintedImageWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        let rect = CGRect(origin: CGPointZero, size: size)

        drawInRect(rect)
        color.set()
        UIRectFillUsingBlendMode(rect, CGBlendMode.Screen)
        drawInRect(rect, blendMode: CGBlendMode.DestinationIn, alpha: 1.0)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - NSUserDefaults
extension NSUserDefaults {

    /**
     Attempts for extract a UIColor object for the given key in the receiver.
     */
    func colorForKey(key: String) -> UIColor? {
        var color: UIColor?

        if let colorData = dataForKey(key) {
            color = NSKeyedUnarchiver.unarchiveObjectWithData(colorData) as? UIColor
        }

        return color
    }

    /**
     Sets the given color for the given key in the receiver.
     */
    func setColor(color: UIColor?, forKey key: String) {
        var colorData: NSData?

        if let color = color {
            colorData = NSKeyedArchiver.archivedDataWithRootObject(color)
        }

        setObject(colorData, forKey: key)
    }
}

// MARK: - NSMutableURLRequest
extension NSMutableURLRequest {

    /// Bridges enum HttpMethod in the existing String HTTPMethod property on NSMutableURLRequest.
    var method: HttpMethod {
        get {
            return HttpMethod(rawValue: HTTPMethod)!
        }

        set {
            HTTPMethod = newValue.rawValue
        }
    }
}