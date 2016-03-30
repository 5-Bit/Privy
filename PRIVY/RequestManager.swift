//
//  RequestManager.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import ObjectMapper

enum HttpMethod: String {
    case POST, GET, PUT, PATCH, DELETE
}

enum PrivyErrorStatus: ErrorType {
    case Ok, ServerError(String), NoResponse, UnknownError
}

enum PrivyHttpHeaderField: String {
    case Email = "privy-email"
    case Password = "privy-password"
    case Error = "Privy-Api-Error"
}

extension NSMutableURLRequest {
    var method: HttpMethod {
        get {
            return HttpMethod(rawValue: HTTPMethod)!
        }

        set {
            HTTPMethod = newValue.rawValue
        }
    }
}


typealias LoginCompletion = (response: LoginRegistrationResponse?, errorStatus: PrivyErrorStatus) -> Void

struct LoginCredential {
    let email: String
    let password: String
}

final class RequestManager {
    struct Static {
        static let host = NSURL(string: "https://privyapp.com")!
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

        handleRequest(url) { (data, response, error) in
            var infoTypes: PrivyUser.InfoTypes?
            var errorStatus = PrivyErrorStatus.Ok

            defer {
                self.completionOnMainThread(infoTypes, errorStatus: errorStatus, completion: completion)
            }

            guard let response = response as? NSHTTPURLResponse else {
                errorStatus = .NoResponse
                return
            }

            switch response.statusCode {
            case 200:
                if let data = data,
                    jsonString = String(data: data, encoding: NSUTF8StringEncoding),
                    registerResponse = Mapper<PrivyUser.InfoTypes>().map(jsonString) {

                    infoTypes = registerResponse
                } else {
                    errorStatus = .UnknownError
                }
            case 400, 405, 500..<600:
                errorStatus = .ServerError(response.allHeaderFields[PrivyHttpHeaderField.Error.rawValue] as? String ?? "")
            default:
                errorStatus = .UnknownError
            }
        }
    }

    private func userJsonData() -> NSData? {
        PrivyUser.currentUser.userInfo.sessionid = PrivyUser.currentUser.registrationInformation?.sessionid

        guard PrivyUser.currentUser.userInfo.sessionid != nil else {
            return nil
        }

        let jsonString = Mapper<PrivyUser.InfoTypes>().toJSONString(PrivyUser.currentUser.userInfo)
        return jsonString?.dataUsingEncoding(NSUTF8StringEncoding)
    }

    func attemptUserInfoSave() {
        guard let userData = userJsonData() else {
            return
        }

        let url = RequestManager.Static.host.URLByAppendingPathComponent("/users/info")

        handleRequest(url, method: .POST, body: userData) { (data, response, error) in
            guard let response = response as? NSHTTPURLResponse else {
                return
            }

            print(response.statusCode)
        }
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
        let body = query?.dataUsingEncoding(NSUTF8StringEncoding)

        handleRequest(url, method: .POST, body: body) { (data, response, error) in
            var loginResponse: LoginRegistrationResponse?
            var errorStatus = PrivyErrorStatus.Ok

            defer {
                self.completionOnMainThread(loginResponse, errorStatus: errorStatus, completion: completion)
            }

            guard let response = response as? NSHTTPURLResponse else {
                errorStatus = .NoResponse
                return
            }

            switch response.statusCode {
            case 200:
                if let data = data,
                    jsonString = String(data: data, encoding: NSUTF8StringEncoding),
                    registerResponse = Mapper<LoginRegistrationResponse>().map(jsonString) {
                    loginResponse = registerResponse
                } else {
                    errorStatus = .UnknownError
                }
            case 400, 405, 500 ..< 600:
                errorStatus = .ServerError(response.allHeaderFields[PrivyHttpHeaderField.Error.rawValue] as? String ?? "")
            default:
                errorStatus = .UnknownError
            }
        }
    }

    func logout() {
        
    }

    func requestPasswordReset(email: String, completion: (success: Bool) -> Void) {
        let url = RequestManager.Static.host.URLByAppendingPathComponent("users/resetpassword")
        let queryItems = [
            NSURLQueryItem(name: "email", value: email)
        ]

        let body = url.urlByAppendingQueryItems(queryItems).query?.dataUsingEncoding(NSUTF8StringEncoding)

        handleRequest(url, method: .POST, body: body) { (data, response, error) in
            var success = false
            defer {
                self.completionOnMainThread(success, completion: completion)
            }

            guard let response = response as? NSHTTPURLResponse where error == nil else {
                return
            }

            success = response.statusCode == 200
        }
    }

    private func handleRequest(url: NSURL, method: HttpMethod = .GET, body: NSData? = nil, completion: (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(
            URL: url,
            cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: RequestManager.Static.defaultTimeout
        )

        request.method = method
        request.HTTPBody = body

        session.dataTaskWithRequest(request, completionHandler: completion).resume()
    }

    private func completionOnMainThread(user: PrivyUser.InfoTypes?, errorStatus: PrivyErrorStatus, completion: (user: PrivyUser.InfoTypes?, errorStatus: PrivyErrorStatus) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(user: user, errorStatus: errorStatus)
        }
    }

    private func completionOnMainThread(response: LoginRegistrationResponse? = nil, errorStatus: PrivyErrorStatus, completion: LoginCompletion) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(response: response, errorStatus: errorStatus)
        }
    }

    private func completionOnMainThread(success: Bool, completion: (success: Bool) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(success: success)
        }
    }
}
