//
//  PrivyUser.swift
//  Privy
//
//  Created by Michael MacCallum on 2/21/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import ObjectMapper

struct QRMapObject: Mappable {
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    var emailAddress: String?
    
    var uuids = [String]()
    
    init() {
        
    }
    
    init?(_ map: Map) {
        firstName       <-  map["firstName"]
        lastName        <-  map["lastName"]
        emailAddress    <-  map["emailAddress"]
        phoneNumber     <-  map["phoneNumber"]
        uuids           <-  map["uuids"]
    }
    
    mutating func mapping(map: Map) {
        firstName       <-  map["firstName"]
        lastName        <-  map["lastName"]
        emailAddress    <-  map["emailAddress"]
        phoneNumber     <-  map["phoneNumber"]
        uuids           <-  map["uuids"]
    }
}

final class PrivyUser {
    static let currentUser = PrivyUser()
    
    var info: LoginRegistrationResponse?
    
    private init() {

    }
    
    var qrString: String {
        var data = QRMapObject()
        data.firstName = userInfo.basic.firstName
        data.lastName = userInfo.basic.lastName
        data.emailAddress = userInfo.basic.emailAddress
        data.phoneNumber = userInfo.basic.phoneNumber
        
        if let info = info {
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
        return info != nil
    }
    
    struct InfoTypes: Mappable {
        var sessionid: String?
        
        struct Basic: Mappable {
            var firstName: String?
            var lastName: String?
            var emailAddress: String?
            var phoneNumber: String?
        
            init() {
                
            }
            
            init?(_ map: Map) {
                firstName       <-  map["firstName"]
                lastName        <-  map["lastName"]
                emailAddress    <-  map["emailAddress"]
                phoneNumber     <-  map["phoneNumber"]
            }
            
            mutating func mapping(map: Map) {
                firstName       <-  map["firstName"]
                lastName        <-  map["lastName"]
                emailAddress    <-  map["emailAddress"]
                phoneNumber     <-  map["phoneNumber"]
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
                facebook       <-  map["facebook"]
                twitter        <-  map["twitter"]
                googlePlus     <-  map["googlePlus"]
                instagram      <-  map["instagram"]
                snapchat       <-  map["snapchat"]
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
                linkedin        <-  map["linkedin"]
                emailAddress    <-  map["emailAddress"]
                phoneNumber     <-  map["phoneNumber"]
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
                github           <-  map["github"]
                stackoverflow    <-  map["stackoverflow"]
                bitbucket        <-  map["bitbucket"]
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
                website      <-  map["website"]
                wordpress    <-  map["wordpress"]
                tumblr       <-  map["tumblr"]
                medium       <-  map["medium"]
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
                flickr        <-  map["flickr"]
                soundcloud    <-  map["soundcloud"]
                youtube       <-  map["youtube"]
                vine          <-  map["vine"]
                vimeo         <-  map["vimeo"]
                pintrest      <-  map["pintrest"]
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
            sessionid   <-  map["sessionid"]
            basic       <-  map["basic"]
            social      <-  map["social"]
            business    <-  map["business"]
            developer   <-  map["developer"]
            media       <-  map["media"]
            blogging    <-  map["blogging"]
        }
        
        mutating func mapping(map: Map) {
            sessionid   <-  map["sessionid"]
            basic       <-  map["basic"]
            social      <-  map["social"]
            business    <-  map["business"]
            developer   <-  map["developer"]
            media       <-  map["media"]
            blogging    <-  map["blogging"]
        }
    }
    
    var userInfo = InfoTypes()
    
    func saveChangesToUserInfo() {
        RequestManager.sharedManager.attemptUserInfoSave()
    }
}

