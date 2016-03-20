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

    func retrieveUser() throws -> PrivyUser? {
        var user: PrivyUser?
        dispatch_sync(saveQueue) {

        }

        return user
    }

    func saveUser(user: PrivyUser, completion: (success: Bool) throws -> Void) {
        dispatch_barrier_async(saveQueue) {

        }
    }

    /**
     <#Description#>

     - parameter user:     <#user description#>
     - parameter password: <#password description#>

     - returns: <#return value description#>
     */
    private func encrypUser(user: PrivyUser, withPassword password: String) -> NSData? {
        guard let jsonString = Mapper<PrivyUser>().toJSONString(user),
            jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        return RNCryptor.encryptData(jsonData, password: password)
    }

    /**
     <#Description#>

     - parameter data: <#data description#>
     - parameter path: <#path description#>

     - returns: <#return value description#>
     */
    private func saveEncryptedData(data: NSData, toPath path: NSURL) -> Bool {
        do {
            try data.writeToURL(path, options: .AtomicWrite)
            return true
        } catch {
            return false
        }
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

//// Encryption
//let data: NSData = ...
//let password = "Secret password"
//let ciphertext = RNCryptor.encryptData(data, password: password)
//
//// Decryption
//do {
//    let originalData = try RNCryptor.decryptData(ciphertext, password: password)
//    // ...
//} catch {
//    print(error)
//}