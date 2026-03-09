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
import OTFTemplateBox
import RawModel

@RawGenerable
struct ChangePasswordConfiguration: Codable {
    let version: String
    let navTitle: OTFStringLocalized
    let emailLabel: OTFStringLocalized
    let sectionTitle: OTFStringLocalized
    let oldPasswordPlaceholder: OTFStringLocalized
    let newPasswordPlaceholder: OTFStringLocalized
    let resetButtonTitle: OTFStringLocalized
    let cancelButtonTitle: OTFStringLocalized
    let failureAlertTitle: OTFStringLocalized
    let okayActionTitle: OTFStringLocalized
}

extension ChangePasswordConfiguration: OTFVersionedDecodable {
    typealias Raw = RawChangePasswordConfiguration

    static let fallback = ChangePasswordConfiguration(
        version: "2.0.0",
        navTitle: "Change Passcode",
        emailLabel: "Email",
        sectionTitle: "Change Passcode",
        oldPasswordPlaceholder: "Old Password",
        newPasswordPlaceholder: "New Password",
        resetButtonTitle: "Reset Password",
        cancelButtonTitle: "Cancel",
        failureAlertTitle: "Password Reset Error!",
        okayActionTitle: "OK"
    )

    init(from raw: RawChangePasswordConfiguration) {
        let fallback = Self.fallback
        version = raw.version ?? fallback.version
        navTitle = raw.navTitle ?? fallback.navTitle
        emailLabel = raw.emailLabel ?? fallback.emailLabel
        sectionTitle = raw.sectionTitle ?? fallback.sectionTitle
        oldPasswordPlaceholder = raw.oldPasswordPlaceholder ?? fallback.oldPasswordPlaceholder
        newPasswordPlaceholder = raw.newPasswordPlaceholder ?? fallback.newPasswordPlaceholder
        resetButtonTitle = raw.resetButtonTitle ?? fallback.resetButtonTitle
        cancelButtonTitle = raw.cancelButtonTitle ?? fallback.cancelButtonTitle
        failureAlertTitle = raw.failureAlertTitle ?? fallback.failureAlertTitle
        okayActionTitle = raw.okayActionTitle ?? fallback.okayActionTitle
    }

    static func migrate(from version: OTFSemanticVersion, raw: Raw) throws -> ChangePasswordConfiguration {
        ChangePasswordConfiguration(from: raw)
    }
}
