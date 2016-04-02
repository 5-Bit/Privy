//
//  Misc Extensions.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

private extension NSMutableURLRequest {
    func addValue(value: String, forHTTPHeaderField field: PrivyHttpHeaderField) {
        addValue(value, forHTTPHeaderField: field.rawValue)
    }
}

extension NSURL {
    func urlByAppendingQueryItems(queryItems: [NSURLQueryItem]) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        return components!.URL!
    }
}

extension NSData {
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

extension UIImage {
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
