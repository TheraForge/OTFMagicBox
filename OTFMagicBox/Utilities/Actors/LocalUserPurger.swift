/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import Foundation
import UIKit

/// Centralized app-layer cleanup for user-local artifacts.
///
/// `LocalUserPurger` clears **app-owned** data created for the current user:
/// - Thumbnails managed by `Thumbnailer` (memory + disk)
/// - Original files saved by the app (e.g., full-size profile image under `Documents`)
///
/// This actor deliberately **does not** know how to fetch or compute new user state.
/// It’s meant to be called by flows like **Logout** and **Delete Account**.
///
/// ### Example: Logout flow
/// ```swift
/// Task {
///   await LocalUserPurger.shared.purgeAll()
///   await MainActor.run {
///     OTFTheraforgeNetwork.shared.moveToOnboardingView()
///   }
/// }
/// ```
///
/// ### Example: Account deletion flow
/// ```swift
/// Task {
///   await LocalUserPurger.shared.purgeAll()
///   NotificationCenter.default.post(name: .deleteUserAccount, object: nil)
/// }
/// ```
public actor LocalUserPurger {

    /// Global instance for common flows.
    public static let shared = LocalUserPurger()

    private let defaults = UserDefaults.standard

    // MARK: - High-level API

    /// Purges **all** user-local artifacts: thumbnails and originals.
    ///
    /// Call this on logout and account deletion, **before** navigating away from the session UI.
    public func purgeAll() async {
        await purgeThumbnails()
        await purgeOriginals()
    }

    /// Removes all cached thumbnails (memory + disk) created by `Thumbnailer`.
    ///
    /// This does **not** touch your app’s originals in `Documents`.
    public func purgeThumbnails() async {
        await Thumbnailer.shared.clearMemory()
        await Thumbnailer.shared.clearDisk()
    }

    /// Removes app-owned original files for the current user (non-cache).
    ///
    /// - Note: The concrete keys/filenames are application-specific. This implementation
    ///   removes the last known profile image stored in `Documents`, tracked via
    ///   `Constant.Storage.kLastProfileAttachmentID`.
    ///
    /// - Important: Keep this method aligned with wherever you **save** originals
    ///   (e.g., your profile download/upload pipelines).
    public func purgeOriginals() async {
        if let id = defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) {
            do {
                // Uses OTFUtilities’s FileManager extension.
                try FileManager.deleteFile(filename: id)
            } catch {
                // Missing is fine; nothing to delete.
            }
            defaults.removeObject(forKey: Constants.Storage.kLastProfileAttachmentID)
            defaults.removeObject(forKey: Constants.Storage.kLastProfileHashFileKey)
        }

        // Add more user-specific files here as your app persists them, e.g.:
        // if let consentID = defaults.string(forKey: Constant.Storage.kConsentAttachmentID) {
        //     try? FileManager.deleteFile(filename: consentID)
        //     defaults.removeObject(forKey: Constant.Storage.kConsentAttachmentID)
        // }
    }
}
