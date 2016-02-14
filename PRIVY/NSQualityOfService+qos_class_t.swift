//
//  NSQualityOfService+qos_class_t.swift
//  Privy
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Privy. All rights reserved.
//

import Foundation

// MARK: - <#Description#>
extension NSQualityOfService {
    /**
     <#Description#>
     
     - parameter qosClass: <#qosClass description#>
     
     - returns: <#return value description#>
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
     <#Description#>
     
     - returns: <#return value description#>
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
