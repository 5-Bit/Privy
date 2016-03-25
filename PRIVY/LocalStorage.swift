//
//  LocalStorage.swift
//  Privy
//
//  Created by Michael MacCallum on 2/29/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation
import RNCryptor
import ObjectMapper
import Locksmith

enum LocalStorageError: ErrorType {
    case Encrypt, SaveData, SaveKey
}

/**
   Facilitates the loading and saving of the current user's data to and from disk.

   - note: Usage of <code>user</code> is thread safe.
   - author: Michael MacCallum
   - date: 2016-02-29 10:02:43-0500
   - since: 1.0
 */
final class LocalStorage {
    enum Static: String {
        case UserInfo
    }

    static let defaultStorage = LocalStorage()
    private let fileManager = NSFileManager.defaultManager()

    private let saveQueue = dispatch_queue_create("com.privy.localstorage.save", DISPATCH_QUEUE_CONCURRENT)

    private init() {

    }

    // MARK: - Reading

    /**
     <#Description#>

     - throws: <#throws value description#>

     - returns: <#return value description#>
     */
    func retrieveUser() throws -> PrivyUser? {
        var user: PrivyUser?
        
        dispatch_sync(saveQueue) {
            guard let password = self.retrieveEncryptionKey(),
                userData = self.retrieveUserData() else {
                    return
            }

            user = self.decryptUserData(userData, withPassword: password)
        }

        return user
    }

    /**
     <#Description#>

     - returns: <#return value description#>
     */
    private func retrieveEncryptionKey() -> String? {
        return Locksmith.loadDataForUserAccount("user")?["password"] as? String
    }

    /**
     <#Description#>

     - returns: <#return value description#>
     */
    private func retrieveUserData() -> NSData? {
        return NSData(contentsOfURL: userInfoPath())
    }

    /**
     <#Description#>

     - parameter data:     <#data description#>
     - parameter password: <#password description#>

     - returns: <#return value description#>
     */
    private func decryptUserData(data: NSData, withPassword password: String) -> PrivyUser? {
        guard let decrypted = try? RNCryptor.decryptData(data, password: password) else {
            return nil
        }

        guard let userJsonString = String(data: decrypted, encoding: NSUTF8StringEncoding) else {
            return nil
        }

        return Mapper<PrivyUser>().map(userJsonString)
    }

    // MARK: - Saving

    /**
     <#Description#>

     - parameter user:       <#user description#>
     - parameter completion: <#completion description#>
     */
    func saveUser(user: PrivyUser, completion: (error: ErrorType?) -> Void) {
        dispatch_barrier_async(saveQueue) {
            var saveUserError: ErrorType?
            let password = NSUUID().UUIDString

            defer {
                completion(error: saveUserError)
            }

            do {
                let encryptedData = try self.encrypUser(user, withPassword: password)
                try self.saveEncryptedData(encryptedData)
                try self.saveUserEncryptionKey(password)
            } catch {
                saveUserError = error
            }
        }
    }

    /**
     <#Description#>

     - parameter user:     <#user description#>
     - parameter password: <#password description#>

     - returns: <#return value description#>
     */
    private func encrypUser(user: PrivyUser, withPassword password: String) throws -> NSData {
        guard let jsonString = Mapper<PrivyUser>().toJSONString(user),
            jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {
                throw LocalStorageError.Encrypt
        }

        return RNCryptor.encryptData(jsonData, password: password)
    }

    /**
     <#Description#>

     - parameter data: <#data description#>
     - parameter path: <#path description#>

     - returns: <#return value description#>
     */
    private func saveEncryptedData(data: NSData) throws {
        try data.writeToURL(userInfoPath(), options: .AtomicWrite)
    }

    /**
     <#Description#>

     - parameter key: <#key description#>

     - throws: <#throws value description#>
     */
    private func saveUserEncryptionKey(key: String) throws {
        try Locksmith.updateData(["password": key], forUserAccount: "user")
    }

    /**
     <#Description#>

     - returns: <#return value description#>
     */
    private func userInfoPath() -> NSURL {
        return documentsDirectoryPath().URLByAppendingPathComponent(
            Static.UserInfo.rawValue,
            isDirectory: false
        )
    }

    /**
     <#Description#>

     - returns: <#return value description#>
     */
    private func documentsDirectoryPath() -> NSURL {
        let paths = fileManager.URLsForDirectory(
            .ApplicationSupportDirectory,
            inDomains: .UserDomainMask
        )

        return paths[0]
    }
}
