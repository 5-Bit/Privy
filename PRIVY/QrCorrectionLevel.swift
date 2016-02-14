//
//  QrCorrectionLevel.swift
//  Privy
//
//  Created by Michael MacCallum on 1/18/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

/// Represents the correction level to be used when generating a QR code.
enum QrCorrectionLevel: NSString, CustomStringConvertible {
    /// Use the low correction level (7%)
    case Low = "L"
    
    /// Use the medium correction level (15%)
    case Medium = "M"
    
    /// Use the quartile correction level (25%)
    case Quartile = "Q"
    
    /// Use the high correction level (30%)
    case High = "H"
    
    /// A numeric representation of the correction level.
    var multiplier: CGFloat {
        switch self {
        case .Low:
            return 0.07
        case .Medium:
            return 0.15
        case .Quartile:
            return 0.25
        case .High:
            return 0.30
        }
    }
    
    /// returns "\(rawValue) (\(multiplier * 100.0)%)"
    var description: String {
        return "\(rawValue) (\(multiplier * 100.0)%)"
    }
}

extension NSObject {
    /**
     Overloads NSObject's `setValue(_:forKey:)` to accept arbitrary enums whose RawValue is AnyObject
     */
    func setValue <RawType: RawRepresentable where RawType.RawValue: AnyObject> (value: RawType?, forKey key: String) {
        setValue(value?.rawValue, forKey: key)
    }
}