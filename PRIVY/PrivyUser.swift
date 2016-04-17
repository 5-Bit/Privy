//
//  PrivyUser.swift
//  Privy
//
//  Created by Michael MacCallum on 2/21/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreGraphics
import CoreLocation

/**
 *  @author Michael MacCallum, 2016-02-28 15:02:49-0500
 *
 *  <#Description#>
 *
 *  @since <#1.0#>
 */
struct QRMapObject: Mappable {
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    var emailAddress: String?
    
    var uuids = [String]()
    
    init() {
        
    }
    
    init?(_ map: Map) {
        mapping(map)
    }
    
    mutating func mapping(map: Map) {
        firstName       <-  map["firstName"]
        lastName        <-  map["lastName"]
        emailAddress    <-  map["emailAddress"]
        phoneNumber     <-  map["phoneNumber"]
        uuids           <-  map["uuids"]
    }
}

/// <#Description#>
final class PrivyUser: Mappable {
    static let currentUser = PrivyUser()
    
    var registrationInformation: LoginRegistrationResponse?
    
    private init() {

    }

    init?(_ map: Map) {
        mapping(map)
    }

    func mapping(map: Map) {
        registrationInformation <- map["registrationInformation"]
        userInfo                <- map["userInfo"]
    }

    var qrString: String {
        var data = QRMapObject()
        data.firstName = userInfo.basic.firstName
        data.lastName = userInfo.basic.lastName
        data.emailAddress = userInfo.basic.emailAddress
        data.phoneNumber = userInfo.basic.phoneNumber
        
        if let info = registrationInformation {
            data.uuids.append(info.basic!)
            data.uuids.append(info.social!)
            data.uuids.append(info.business!)
            data.uuids.append(info.developer!)
            data.uuids.append(info.media!)
            data.uuids.append(info.blogging!)
        }

        return Mapper<QRMapObject>().toJSONString(data, prettyPrint: false) ?? ""
    }
    
    var isLoggedIn: Bool {
        return registrationInformation != nil
    }

    var userInfo = InfoTypes()
    
    func saveChangesToUserInfo(remote: Bool) {
        LocalStorage.defaultStorage.saveUser(PrivyUser.currentUser) { error in
            if remote && error == nil {
                RequestManager.sharedManager.attemptUserInfoSave()
            }
        }
    }
}

/**
 *  @author Michael MacCallum, 16-02-28 15:02:29
 *
 *  <#Description#>
 *
 *  @since <#1.0#>
 */
struct InfoTypes: Mappable {
    var uuid: String?
    var sessionId: String?
    
    var location: Location?

    struct Location: Mappable {
        var latitude: CLLocationDegrees?
        var longitude: CLLocationDegrees?

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            latitude     <- map["latitude"]
            longitude    <- map["longitude"]
        }
    }

    struct Basic: Mappable {
        var firstName: String?
        var lastName: String?
        var emailAddress: String?
        var phoneNumber: String?
        var profilePictureUrl: String?
        var birthDay: NSDate?
        var addressLine1: String?
        var addressLine2: String?
        var city: String?
        var state: String?
        var country: String?
        var postalCode: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            firstName               <-  map["First Name"]
            lastName                <-  map["Last Name"]
            emailAddress            <-  map["Email Address"]
            phoneNumber             <-  map["Phone Number"]
            profilePictureUrl       <-  map["Profile Picture URL"]
            birthDay                <-  (map["Birthday"], DateTransform())
            addressLine1            <-  map["Address Line 1"]
            addressLine2            <-  map["Address Line 2"]
            city                    <-  map["City"]
            state                   <-  map["State"]
            country                 <-  map["Country"]
            postalCode              <-  map["Zip Code"]
        }
    }

    struct Social: Mappable {
        var facebook: String?
        var twitter: String?
        var googlePlus: String?
        var instagram: String?
        var snapchat: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            facebook       <-  map["facebook"]
            twitter        <-  map["twitter"]
            googlePlus     <-  map["googlePlus"]
            instagram      <-  map["instagram"]
            snapchat       <-  map["snapchat"]
        }
    }

    struct Business: Mappable {
        var linkedin: String?
        var emailAddress: String?
        var phoneNumber: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            linkedin        <-  map["linkedin"]
            emailAddress    <-  map["emailAddress"]
            phoneNumber     <-  map["phoneNumber"]
        }
    }

    struct Developer: Mappable {
        var github: String?
        var stackoverflow: String?
        var bitbucket: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            github           <-  map["github"]
            stackoverflow    <-  map["stackoverflow"]
            bitbucket        <-  map["bitbucket"]
        }
    }

    struct Blogging: Mappable {
        var website: String?
        var wordpress: String?
        var tumblr: String?
        var medium: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            website      <-  map["website"]
            wordpress    <-  map["wordpress"]
            tumblr       <-  map["tumblr"]
            medium       <-  map["medium"]
        }
    }

    struct Media: Mappable {
        var flickr: String?
        var soundcloud: String?
        var youtube: String?
        var vine: String?
        var vimeo: String?
        var pintrest: String?

        init() {

        }

        init?(_ map: Map) {
            mapping(map)
        }

        mutating func mapping(map: Map) {
            flickr        <-  map["flickr"]
            soundcloud    <-  map["soundcloud"]
            youtube       <-  map["youtube"]
            vine          <-  map["vine"]
            vimeo         <-  map["vimeo"]
            pintrest      <-  map["pintrest"]
        }
    }

    var basic = Basic()
    var social = Social()
    var business = Business()
    var developer = Developer()
    var media = Media()
    var blogging = Blogging()

    init() {

    }

    init?(_ map: Map) {
        mapping(map)
    }

    mutating func mapping(map: Map) {
        uuid        <-  map["uuid"]
        sessionId   <-  map["sessionid"]
        basic       <-  map["basic"]
        social      <-  map["social"]
        business    <-  map["business"]
        developer   <-  map["developer"]
        media       <-  map["media"]
        blogging    <-  map["blogging"]
        location    <-  map["location"]
    }
}
