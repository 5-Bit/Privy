//
//  NSQualityOfService+qos_class_t.swift
//  Privy
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Privy. All rights reserved.
//

import Foundation

// MARK: - Adds shims to NSQuality of service to allow easy conversion between it and GCD's QOS_CLASS.
extension NSQualityOfService {
    /**
     Creates an NSQualityOfService instance from a qos_class_t from GCD.
     */
    init?(qosClass: qos_class_t) {
        switch qosClass {
        case QOS_CLASS_USER_INTERACTIVE:
            self = .UserInteractive
        case QOS_CLASS_USER_INITIATED:
            self = .UserInitiated
        case QOS_CLASS_DEFAULT:
            self = .Default
        case QOS_CLASS_UTILITY:
            self = .Utility
        case QOS_CLASS_BACKGROUND:
            self = .Background
        default:
            return nil
        }
    }
    
    /**
     Converts the receiver into its equivalent qos_class_t. 
     */
    func toQosClass() -> qos_class_t {
        switch self {
        case .UserInteractive:
            return QOS_CLASS_USER_INTERACTIVE
        case .UserInitiated:
            return QOS_CLASS_USER_INITIATED
        case .Default:
            return QOS_CLASS_DEFAULT
        case .Utility:
            return QOS_CLASS_UTILITY
        case .Background:
            return QOS_CLASS_BACKGROUND
        }
    }
}
