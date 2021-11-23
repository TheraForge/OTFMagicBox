//
//  KeychainStore.swift
//  OTFMagicBox
//
//  Created by Zeeshan Ahmed on 22/11/2021.
//

import Foundation
import KeychainAccess

class OTFKeychain {
    lazy private(set) var keychain: Keychain = {
        return Keychain(service: "com.theraforge.magicbox.ios")
    }()
    
    func getAppleAuthCredentials() -> AppleAuthCredentials? {
        guard let data = keychain[data: "apple-auth-credentials"] else { return nil }
        do {
            let appleAuth = try JSONDecoder().decode(AppleAuthCredentials.self, from: data)
            return appleAuth
        } catch {
            return nil
        }
    }
    
    func saveAppleAuthCredentials(_ credentials: AppleAuthCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        keychain[data: "apple-auth-credentials"] = data
    }
}
