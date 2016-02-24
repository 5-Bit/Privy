//
//  ServerResponses.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation

struct LoginResponse {
    let error: String?
    let userId: Int?
    let sessionKey: String?
}