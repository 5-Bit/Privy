//
//  RequestManager.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import ObjectMapper

enum PrivyErrorStatus: ErrorType {
    case Ok, ServerError(String), NoResponse, UnknownError
}

enum PrivyHttpHeaderField: String {
    case Email = "privy-email"
    case Password = "privy-password"
    case Error = "Privy-Api-Error"
}

typealias LoginCompletion = (response: LoginRegistrationResponse?, errorStatus: PrivyErrorStatus) -> Void

struct LoginCredential {
    let email: String
    let password: String
}

final class RequestManager {
    struct Static {
        static let host = NSURL(string: "http://privyapp.com")!
        static let defaultTimeout = 15.0
    }
    
    static let sharedManager = RequestManager()
    private let session: NSURLSession
    
    private init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration)
    }

    func attemptLookupByUUIDs(uuids: [String], completion: (user: PrivyUser.InfoTypes?, errorStatus: PrivyErrorStatus) -> Void) {
        guard let sessionId = PrivyUser.currentUser.registrationInformation?.sessionid else {
            return
        }
        
        let queryItems = [
            NSURLQueryItem(name: "uuids", value: uuids.joinWithSeparator(",")),
            NSURLQueryItem(name: "sessionid", value: sessionId)
        ]
        
        let url = RequestManager.Static.host.URLByAppendingPathComponent("/users/info").urlByAppendingQueryItems(queryItems)
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: RequestManager.Static.defaultTimeout)
        
        request.HTTPMethod = "GET"
    
        let lookupTask = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard let response = response as? NSHTTPURLResponse else {
                self.completionOnMainThread(nil, errorStatus: .NoResponse, completion: completion)
                return
            }
            
            switch response.statusCode {
            case 200:
                if let data = data,
                    jsonString = String(data: data, encoding: NSUTF8StringEncoding),
                    registerResponse = Mapper<PrivyUser.InfoTypes>().map(jsonString) {
                    
                    self.completionOnMainThread(registerResponse, errorStatus: .Ok, completion: completion)
                } else {
                    self.completionOnMainThread(nil, errorStatus: .UnknownError, completion: completion)
                }
            case 400: // sent wrong url, DB error (maybe user exists) has error message
                fallthrough
            case 405: // my bad invalid method
                fallthrough
            case 500..<600:
                let message = response.allHeaderFields[PrivyHttpHeaderField.Error.rawValue] as? String ?? ""
                self.completionOnMainThread(nil, errorStatus: .ServerError(message), completion: completion)
            default:
                self.completionOnMainThread(nil, errorStatus: .UnknownError, completion: completion)
            }
        }
        
        lookupTask.resume()
    }
    
    func attemptUserInfoSave() {
        PrivyUser.currentUser.userInfo.sessionid = PrivyUser.currentUser.registrationInformation?.sessionid
        
        guard PrivyUser.currentUser.userInfo.sessionid != nil else {
            return
        }
        
        let url = RequestManager.Static.host.URLByAppendingPathComponent("/users/info")
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: RequestManager.Static.defaultTimeout)
        
        let jsonString = Mapper<PrivyUser.InfoTypes>().toJSONString(PrivyUser.currentUser.userInfo)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonString?.dataUsingEncoding(NSUTF8StringEncoding)
    
        let saveTask = session.dataTaskWithRequest(request) { (data, response, error) in
            guard let response = response as? NSHTTPURLResponse else {
                return
            }
            
            print(response.statusCode)
        }
        
        saveTask.resume()
    }

    func attemptRegistrationWithCredentials(credential: LoginCredential, completion: LoginCompletion) {
        registerLoginWithPath("users/new", credential: credential, completion: completion)
    }
    
    func attemptLoginWithCredentials(credential: LoginCredential, completion: LoginCompletion) {
        registerLoginWithPath("users/login", credential: credential, completion: completion)
    }
    
    private func registerLoginWithPath(pathComponent: String, credential: LoginCredential, completion: LoginCompletion) {
        let queryItems = [
            NSURLQueryItem(name: "email", value: credential.email),
            NSURLQueryItem(name: "password", value: credential.password)
        ]
        
        let url = RequestManager.Static.host.URLByAppendingPathComponent(pathComponent)
        let query = url.urlByAppendingQueryItems(queryItems).query
        
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: RequestManager.Static.defaultTimeout)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = query?.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in

            guard let response = response as? NSHTTPURLResponse else {
                self.completionOnMainThread(nil, errorStatus: .NoResponse, completion: completion)
                return
            }
            
            switch response.statusCode {
            case 200:
                if let data = data,
                    jsonString = String(data: data, encoding: NSUTF8StringEncoding),
                    registerResponse = Mapper<LoginRegistrationResponse>().map(jsonString) {
                    
                    self.completionOnMainThread(registerResponse, errorStatus: .Ok, completion: completion)
                } else {
                    self.completionOnMainThread(nil, errorStatus: .UnknownError, completion: completion)
                }
            case 400: // sent wrong url, DB error (maybe user exists) has error message
                fallthrough
            case 405: // my bad invalid method
                fallthrough
            case 500..<600:
                let message = response.allHeaderFields[PrivyHttpHeaderField.Error.rawValue] as? String ?? ""
                self.completionOnMainThread(nil, errorStatus: .ServerError(message), completion: completion)
            default:
                self.completionOnMainThread(nil, errorStatus: .UnknownError, completion: completion)
            }
        }
        
        task.resume()
    }
    

    private func completionOnMainThread(user: PrivyUser.InfoTypes?, errorStatus: PrivyErrorStatus, completion: (user: PrivyUser.InfoTypes?, errorStatus: PrivyErrorStatus) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(user: user, errorStatus: errorStatus)
        }
    }

    private func completionOnMainThread(response: LoginRegistrationResponse?, errorStatus: PrivyErrorStatus, completion: LoginCompletion) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(response: response, errorStatus: errorStatus)
        }
    }
}
































