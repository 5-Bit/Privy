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
//    func retrieveUser() throws -> PrivyUser? {
//        var user: PrivyUser?
//        
//        dispatch_sync(saveQueue) {
//            guard let password = self.retrieveEncryptionKey(),
//                userData = self.retrieveUserData() else {
//                    return
//            }
//
//            user = self.decryptUserData(userData, withPassword: password)
//        }
//
//        return user
//    }

    /**
     Attempts to load the encryption key for the user's data out of the Keychain.

     - returns: The key found in the keychain, nil otherwise.
     */
    private func retrieveEncryptionKey() -> String? {
        return Locksmith.loadDataForUserAccount("user")?["password"] as? String
    }

    /**
     Attempts to load the data stored at `userInfoPath()`.

     - returns: The data found at `userInfoPath()` if there is any, nil otherwise.
     */
    private func retrieveDataForUser(user: PrivyUser) -> NSData? {
        return NSData(contentsOfURL: userInfoPathForUser(user))
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
                try self.saveEncryptedData(encryptedData, forUser: user)
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
    private func saveEncryptedData(data: NSData, forUser user: PrivyUser) throws {
        try data.writeToURL(userInfoPathForUser(user), options: .AtomicWrite)
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
    private func userInfoPathForUser(user: PrivyUser) -> NSURL {
        guard let email = user.registrationInformation?.email else {
            fatalError()
        }

        return documentsDirectoryPath().URLByAppendingPathComponent(
            md5(string: email),
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

    /**
     <#Description#>

     - parameter string: <#string description#>

     - returns: <#return value description#>
     */
    func md5(string string: String) -> String {
        var digest = [UInt8](
            count: Int(CC_MD5_DIGEST_LENGTH),
            repeatedValue: 0
        )

        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }

        return (0 ..< Int(CC_MD5_DIGEST_LENGTH))
            .reduce("") {
                $0 + String(format: "%02x", $1)
        }
    }
}
