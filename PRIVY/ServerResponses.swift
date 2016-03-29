//
//  ServerResponses.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import ObjectMapper

struct LoginRegistrationResponse: Mappable {
    var sessionid: String?
    var basic: String?
    var social: String?
    var business: String?
    var developer: String?
    var media: String?
    var blogging: String?
    var email: String?
    
    init?(_ map: Map) {
        mapping(map)
    }
    
    mutating func mapping(map: Map) {
        sessionid   <-  map["sessionid"]
        basic       <-  map["basic"]
        social      <-  map["social"]
        business    <-  map["business"]
        developer   <-  map["developer"]
        media       <-  map["media"]
        blogging    <-  map["blogging"]
        email       <-  map["email"]
    }

    var valid: Bool {
        return sessionid != nil && basic != nil && social != nil
            && business != nil && developer != nil && media != nil
            && blogging != nil
    }
}
