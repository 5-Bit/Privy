//
//  RequestManager.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import ObjectMapper
import CoreLocation

/// Switch for some common HTTP verbs.
enum HttpMethod: String {
    case POST, GET, PUT, PATCH, DELETE
}

enum PrivyErrorStatus: ErrorType, Equatable {
    case Ok, ServerError(String), NoResponse, UnknownError
}

/**
 PrivyErrorStatus Equatable conformance.

 - returns: true iff both operands represent the same error state. Comparison is not made on assosicated
            values. i.e. if both operands represent two difference ServerErrors, this will return true.
 */
func == (lhs: PrivyErrorStatus, rhs: PrivyErrorStatus) -> Bool {
    switch (lhs, rhs) {
    case (.Ok, .Ok), (.ServerError(_), .ServerError(_)), (.NoResponse, .NoResponse), (.UnknownError, .UnknownError):
        return true
    default:
        return false
    }
}

/// Switch for some common custom headers expected from the Privy server.
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

/// Facilitates all of networking operations performed in this application.
final class RequestManager {
    struct Static {
        static let host = NSURL(string: "https://privyapp.com")!
        static let defaultTimeout = 15.0
    }
    
    static let sharedManager = RequestManager()
    private let session: NSURLSession

    private var sessionId: String? {
        return PrivyUser.currentUser.userInfo.sessionId
            ?? PrivyUser.currentUser.registrationInformation?.sessionid
    }
    
    private init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration)
    }

    // MARK: -

    // MARK: Login and Registration

    func attemptRegistrationWithCredentials(credential: LoginCredential, completion: LoginCompletion) {
        registerLoginWithPath("users/new", credential: credential, completion: completion)
    }

    func attemptLoginWithCredentials(credential: LoginCredential, completion: LoginCompletion) {
        registerLoginWithPath("users/login", credential: credential, completion: completion)
    }

    /**
     Handles both registration and login requests for the given credentials, and then calls its completion handler
     on the main thread.
     */
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

    // MARK: Logout

    /**
     Sends a request for the current user to logout (invalidate session) and then calls its
     completion handler on the main thread.
     */
    func logout(completion: (success: Bool) -> Void) {
        guard let session = sessionId else {
            completionOnMainThread(false, completion: completion)
            return
        }

        let baseUrl = RequestManager.Static.host.URLByAppendingPathComponent("users/logout")
        let queryItems = [
            NSURLQueryItem(name: "sessionid", value: session)
        ]

        let url = baseUrl.urlByAppendingQueryItems(queryItems)


        handleRequest(url) { (data, response, error) in
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

    // MARK: Password Reset

    /**
     Triggers a password reset email for the given email address and invokes its completion
     handler on the main thread.
     */
    func requestPasswordReset(email: String, completion: (success: Bool) -> Void) {
        let url = RequestManager.Static.host.URLByAppendingPathComponent("users/resetpassword")
        let queryItems = [
            NSURLQueryItem(name: "email", value: email)
        ]

        let body = url.urlByAppendingQueryItems(queryItems).query?.dataUsingEncoding(NSUTF8StringEncoding)

        handleRequest(url, method: .POST, body: body) { data, response, error in
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

    // MARK: - 

    // MARK: Profile Information

    /**
     Opon invokation, saves all of the current user's profile information to the server.
     */
    func attemptUserInfoSave() {
        guard let userData = userJsonData() else {
            return
        }

        let url = RequestManager.Static.host.URLByAppendingPathComponent("/users/info")

        handleRequest(url, method: .POST, body: userData)
    }

    /**
     Uploads the given UIImage to the server as the new profile picture for the current user.

     - parameter image:      The new profile picture for the current user.
     - parameter completion: The function call upon completion of this operation. 
                             Takes a Bool parameter representing whether or not the operation
                             was successful. Guarenteed to be called on the main thread.
     */
    func uploadUserProfilePicture(image: UIImage?, completion: (success: Bool) -> Void) {
        guard let sessionId = sessionId else {
            completionOnMainThread(false, completion: completion)
            return
        }

        let baseUrl = RequestManager.Static.host.URLByAppendingPathComponent("users/image")
        let queryItems = [
            NSURLQueryItem(name: "sessionid", value: sessionId)
        ]

        let url = baseUrl.urlByAppendingQueryItems(queryItems)

        let boundary = NSUUID().UUIDString
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\"\(boundary)\""
        ]

        let imageData = image == nil ? nil : UIImageJPEGRepresentation(image!, 0.5)
        let multiPartData = multiPartDataStringFromData(imageData!, boundary: boundary)

        handleRequest(url, method: .POST, additionalHeaders: headers, body: multiPartData) { data, response, error in
            var success = false
            defer {
                self.completionOnMainThread(success, completion: completion)
            }

            guard error == nil else {
                return
            }

            guard let status = (response as? NSHTTPURLResponse)?.statusCode where status == 200 else {
                return
            }

            success = true
        }
    }

    /**
     Fetches the current profile picture for the current user and then invokes its completion
     handler with the resulting image. This is guarenteed to happen on the main thread.
     */
    func fetchMyProfilePicture(completion: (image: UIImage?) -> Void) {
        guard let sessionId = sessionId else {
            completionOnMainThread(nil, completion: completion)
            return
        }

        let baseUrl = RequestManager.Static.host.URLByAppendingPathComponent("users/myimage")
        let queryItems = [
            NSURLQueryItem(name: "sessionid", value: sessionId)
        ]

        let url = baseUrl.urlByAppendingQueryItems(queryItems)

        handleImageRequest(url, completion: completion)
    }

    /**
     Fetches the current profile picture for the user associated with the given UUID and
     then invokes its completion handler with the resulting image. 
     This is guarenteed to happen on the main thread.
     */
    func fetchProfilePictureForUser(uuid: String, completion: (image: UIImage?) -> Void) {
        guard let sessionId = sessionId else {
            completionOnMainThread(nil, completion: completion)
            return
        }

        let baseUrl = RequestManager.Static.host.URLByAppendingPathComponent("users/image")
        let queryItems = [
            NSURLQueryItem(name: "uuid", value: uuid),
            NSURLQueryItem(name: "sessionid", value: sessionId)
        ]

        let url = baseUrl.urlByAppendingQueryItems(queryItems)

        handleImageRequest(url, completion: completion)
    }

    /**
     Fetches all of the swapping history of the current user and invokes its completion
     handler on the main thread.
     */
    func refreshHistory(completion: (history: [HistoryUser]?, errorStatus: PrivyErrorStatus) -> Void) {
        let queryItems: [NSURLQueryItem] = [
            NSURLQueryItem(
                name: "sessionid",
                value: sessionId
            )
        ]

        let url = Static.host
            .URLByAppendingPathComponent("users/history")
            .urlByAppendingQueryItems(queryItems)

        handleRequest(url, method: .GET) { data, response, error in
            var errorStatus = PrivyErrorStatus.Ok
            var history: [HistoryUser]?

            defer {
                self.completionOnMainThread(history, errorStatus: errorStatus, completion: completion)
            }

            guard let response = response as? NSHTTPURLResponse else {
                errorStatus = .NoResponse
                return
            }

            switch response.statusCode {
            case 200:
                if let data = data,
                    jsonString = String(data: data, encoding: NSUTF8StringEncoding),
                    users = Mapper<HistoryUser>().mapArray(jsonString) {

                    history = users
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

    /**
     Registers the given token data with the server as an APNS id for the current device.
     This essentially adds the current device to the list of devices that will receive push
     notifications for events that this user is to be notified of.
     */
    func addApnsToken(token: NSData, completion: (success: Bool) -> Void) {
        let url = Static.host.URLByAppendingPathComponent("users/registerapnsclient")

        let queryItems = [
            NSURLQueryItem(name: "apnsid", value: token.hexString()),
            NSURLQueryItem(name: "sessionid", value: sessionId)
        ]

        let body = url.urlByAppendingQueryItems(queryItems).query?.dataUsingEncoding(NSUTF8StringEncoding)

        handleRequest(url, method: .POST, body: body) { data, response, error in
            var success = false

            defer {
                self.completionOnMainThread(success, completion: completion)
            }

            print(response)
            guard let response = response as? NSHTTPURLResponse
                where error == nil else {
                    return
            }

            guard response.statusCode == 200 else {
                return
            }

            success = true
        }
    }

    /**
     Looks up the profile information of a user by the UUIDs supplied. This facilitates the ability
     to only lookup information about a user that they have chosen to share with the current user, since
     the current user will only have the UUIDs associated with that information.
     */
    func attemptLookupByUUIDs(uuids: [String], inLocation location: CLLocation?, completion: (user: InfoTypes?, errorStatus: PrivyErrorStatus) -> Void) {
        guard let sessionId = sessionId else {
            completionOnMainThread(nil, errorStatus: .UnknownError, completion: completion)
            return
        }
        
        var queryItems = [
            NSURLQueryItem(name: "uuids", value: uuids.joinWithSeparator(",")),
            NSURLQueryItem(name: "sessionid", value: sessionId),
        ]

        if let location = location {
            let coordinates = [
                NSURLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
                NSURLQueryItem(name: "longitude", value: String(location.coordinate.longitude))
            ]

            queryItems.appendContentsOf(coordinates)
        }
        
        let url = RequestManager.Static.host.URLByAppendingPathComponent("/users/info").urlByAppendingQueryItems(queryItems)

        handleRequest(url) { data, response, error in
            var infoTypes: InfoTypes?
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
                    registerResponse = Mapper<InfoTypes>().map(jsonString) {

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

    /**
     Gets all of the current user's profile data and returns it as a binary data blob.
     */
    private func userJsonData() -> NSData? {
        PrivyUser.currentUser.userInfo.sessionId = PrivyUser.currentUser.registrationInformation?.sessionid

        guard PrivyUser.currentUser.userInfo.sessionId != nil else {
            return nil
        }

        let jsonString = Mapper<InfoTypes>().toJSONString(PrivyUser.currentUser.userInfo)
        return jsonString?.dataUsingEncoding(NSUTF8StringEncoding)
    }

    // MARK: - Private helpers

    // MARK: Request Handlers

    /**
     A generic helper method designed to automatically perform data tasks on <code>session</code> based on
     its arguments.

     - parameter url:               The URL to make the request to.
     - parameter method:            The HTTP method to use when making the request.
     - parameter additionalHeaders: Any non-default headers to include within the request.
     - parameter body:              Binary data to fill the body of the HTTP request.
     - parameter completion:        The function to be called with the request has completed.
     */
    private func handleRequest(url: NSURL, method: HttpMethod = .GET, additionalHeaders: [String: String]? = nil, body: NSData? = nil, completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)? = nil) {
        RequestManager.updateNetworkOperationState(isNetworking: true)

        let request = NSMutableURLRequest(
            URL: url,
            cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: RequestManager.Static.defaultTimeout
        )

        request.method = method
        if let body = body {
            request.HTTPBody = body
        }

        if let headers = additionalHeaders {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        session.dataTaskWithRequest(request) { data, response, error in
            RequestManager.updateNetworkOperationState(isNetworking: false)
            completion?(data: data, response: response, error: error)
        }.resume()
    }

    /**
     A helper method to handle to transmition of an image to the given URL.
     */
    private func handleImageRequest(url: NSURL, completion: (image: UIImage?) -> Void) {
        handleRequest(url) { data, response, error in
            var image: UIImage?
            defer {
                self.completionOnMainThread(image, completion: completion)
            }

            guard error == nil else {
                return
            }

            guard let status = (response as? NSHTTPURLResponse)?.statusCode where status == 200 else {
                return
            }

            guard let data = data else {
                return
            }

            image = UIImage(data: data)
        }
    }

    // MARK: Network activity indicator state

    private static func updateNetworkOperationState(isNetworking networking: Bool) {
        guard NSThread.isMainThread() else {
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = networking
            }

            return
        }

        UIApplication.sharedApplication().networkActivityIndicatorVisible = networking
    }

    // MARK: Hooks to forward completion handler calls onto the main thread.

    private func completionOnMainThread(history: [HistoryUser]?, errorStatus: PrivyErrorStatus, completion: (history: [HistoryUser]?, errorStatus: PrivyErrorStatus) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(history: history, errorStatus: errorStatus)
        }
    }

    private func completionOnMainThread(user: InfoTypes?, errorStatus: PrivyErrorStatus, completion: (user: InfoTypes?, errorStatus: PrivyErrorStatus) -> Void) {
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

    private func completionOnMainThread(image: UIImage?, completion: (image: UIImage?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(image: image)
        }
    }

    // MARK: Multi-Part form generation

    /**
     Creates a data boundary delimited data blob acceptable for user in an HTTP body.

     - parameter data:     The data to be multipart encoded. Assumed to represent the binary form
                           of a JPEG encoded image.
     - parameter boundary: The delimiter to use around the body data and its content type/disposition.
     */
    private func multiPartDataStringFromData(data: NSData, boundary: String) -> NSData {
        let body = NSMutableData()

        func appendBoundary() {
            body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }

        appendBoundary()

        body.appendData("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: image/jpeg\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(data)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)

        appendBoundary()
        
        return body
    }
}
