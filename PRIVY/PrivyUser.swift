//
//  PrivyUser.swift
//  Privy
//
//  Created by Michael MacCallum on 2/21/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation

final class PrivyUser {
    static let currentUser = PrivyUser()
    
    private init() {
        
    }
    
    var qrString: String {
        return "{name:\"Michael MacCallum\",phone:2392335730,uid:1234567890,key:" + NSUUID().UUIDString + "}"
    }
}