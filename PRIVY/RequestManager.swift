//
//  RequestManager.swift
//  Privy
//
//  Created by Michael MacCallum on 2/22/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation

private enum PrivyHttpHeaderField: String {
    case Email = "privy-email"
    case Password = "privy-password"
}

private extension NSMutableURLRequest {
    func addValue(value: String, forHTTPHeaderField field: PrivyHttpHeaderField) {
        addValue(value, forHTTPHeaderField: field.rawValue)
    }
}

typealias LoginCompletion = (success: Bool, error: NSError?, sessionKey: String?) -> Void

struct LoginCredential {
    let email: String
    let password: String
}

final class RequestManager {
    struct Static {
        static let host = NSURL(string: "http://")!
        static let defaultTimeout = 15.0
    }
    
    static let sharedManager = RequestManager()
    
    private let session: NSURLSession
    
    
    private init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration)
    }
    
    func attemptLoginWithCredentials(credential: LoginCredential, completion: LoginCompletion) {
        let request = NSMutableURLRequest(
            URL: RequestManager.Static.host.URLByAppendingPathComponent("login"),
            cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: RequestManager.Static.defaultTimeout
        )
        
        request.addValue(credential.email, forHTTPHeaderField: .Email)
        request.addValue(credential.password, forHTTPHeaderField: .Password)
        
        let loginTask = session.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                completion(success: false, error: error, sessionKey: nil)
                return
            }
            
            if let httpResponse = response as? NSHTTPURLResponse, data = data {
                if 200..<300 ~= httpResponse.statusCode {
                    let key = String(data: data, encoding: NSUTF8StringEncoding)
                    completion(success: true, error: nil, sessionKey: key)
                } else {
                    completion(success: false, error: error, sessionKey: nil)
                }
            } else {
                completion(success: false, error: nil, sessionKey: nil)
            }
        }
        
        loginTask.resume()
    }
}