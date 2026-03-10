/*
// Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
// be used to endorse or promote products derived from this software without specific
// prior written permission. No license is granted to the trademarks of the copyright
// holders even if such marks are included in this software.
//
// 4. Commercial redistribution in any form requires an explicit license agreement with the
// copyright holder(s). Please contact support@hippocratestech.com for further information
// regarding licensing.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
// OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
// OF SUCH DAMAGE.
 */

import Foundation
import OTFUtilities
import Sodium

enum KeychainCloudManager {
    static var getEmailAddress: String {
        let emailData = SwiftSodium().loadKey(keychainKey: KeychainKeys.emailKey)
        return String(data: emailData, encoding: .utf8) ?? ""
    }

    static var getPassword: String {
        let passwordData = SwiftSodium().loadKey(keychainKey: KeychainKeys.passwordKey)
        return String(data: passwordData, encoding: .utf8) ?? ""
    }

    static var getMasterKey: Bytes {
        let swiftSodium = SwiftSodium()
        let masterKeyData = swiftSodium.loadKey(keychainKey: KeychainKeys.masterKey)
        if masterKeyData.isEmpty {
            OTFLogger.logger().warning("Keychain item '\(KeychainKeys.masterKey)' not found.")
        }
        return Array(masterKeyData)
    }

    static var getDefaultStorageKey: Bytes {
        let swiftSodium = SwiftSodium()
        let data = swiftSodium.loadKey(keychainKey: KeychainKeys.defaultStorageKey)
        if data.isEmpty {
            OTFLogger.logger().warning("Keychain item '\(KeychainKeys.defaultStorageKey)' not found.")
        }
        return Array(data)
    }

    static var getConfidentialStorageKey: Bytes {
        let swiftSodium = SwiftSodium()
        let data = swiftSodium.loadKey(keychainKey: KeychainKeys.confidentialStorageKey)
        if data.isEmpty {
            OTFLogger.logger().warning("Keychain item '\(KeychainKeys.confidentialStorageKey)' not found.")
        }
        return Array(data)
    }

    static func saveUserCredentialsInKeychain(email: String, password: String) {
        let swiftSodium = SwiftSodium()
        swiftSodium.saveStringValue(email, keychainKey: KeychainKeys.emailKey)
        swiftSodium.saveStringValue(password, keychainKey: KeychainKeys.passwordKey)
    }

    static func isKeyStored(key: String) -> Bool {
        let swiftSodium = SwiftSodium()
        return swiftSodium.isKeyStored(keychainKey: key)
    }

    static func saveUserKeys(masterKey: Bytes, publicKey: Bytes, secretKey: Bytes, defaultStorageKey: Bytes, confidentialStorageKey: Bytes) {
        let swiftSodium = SwiftSodium()
        swiftSodium.saveKey(publicKey, keychainKey: KeychainKeys.publicKey)
        swiftSodium.saveKey(secretKey, keychainKey: KeychainKeys.secretKey)
        swiftSodium.saveKey(masterKey, keychainKey: KeychainKeys.masterKey)
        swiftSodium.saveKey(defaultStorageKey, keychainKey: KeychainKeys.defaultStorageKey)
        swiftSodium.saveKey(confidentialStorageKey, keychainKey: KeychainKeys.confidentialStorageKey)
    }
}

enum KeychainKeys {
    static let secretKey = "secretKey"
    static let publicKey = "publicKey"
    static let passwordKey = "passwordKey"
    static let emailKey = "emailKey"
    static let masterKey = "masterKey"
    static let confidentialStorageKey = "confidentialStorageKey"
    static let defaultStorageKey = "defaultStorageKey"
}

enum KeychainWiper {
    static func wipeAll() {
        let classes: [CFString] = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for itemClass in classes {
            SecItemDelete([kSecClass as String: itemClass] as CFDictionary)
        }
    }
}

enum KeychainCleaner {
    private static let didRunKey = "didRunKeychainCleaner_v1"

    /// Keychain survives app deletion. UserDefaults does not.
    /// So this runs once per install and clears any leftover Keychain from prior installs.
    static func cleanOnFreshInstallIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: didRunKey) == false else { return }
        KeychainWiper.wipeAll()
        defaults.set(true, forKey: didRunKey)
    }
}
