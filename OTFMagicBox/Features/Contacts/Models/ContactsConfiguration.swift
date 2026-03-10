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
struct ContactsConfiguration: Codable {
    let version: String
    let navTitle: OTFStringLocalized
    let emptyTitle: OTFStringLocalized
    let emptyDescription: OTFStringLocalized
    let emptySymbol: String
    let deletedAlertTitle: OTFStringLocalized
    let deletedAlertMessage: OTFStringLocalized
    let okayActionTitle: OTFStringLocalized
}

extension ContactsConfiguration: OTFVersionedDecodable {
    typealias Raw = RawContactsConfiguration

    static let fallback = ContactsConfiguration(
        version: "2.0.0",
        navTitle: "Contacts",
        emptyTitle: "No contacts yet",
        emptyDescription: "Your care team will appear here once added.",
        emptySymbol: "person.3",
        deletedAlertTitle: "Account Deleted",
        deletedAlertMessage: "Your account was deleted. You'll be returned to onboarding.",
        okayActionTitle: "OK"
    )

    init(from raw: RawContactsConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.navTitle = raw.navTitle ?? fallback.navTitle
        self.emptyTitle = raw.emptyTitle ?? fallback.emptyTitle
        self.emptyDescription = raw.emptyDescription ?? fallback.emptyDescription
        self.emptySymbol = raw.emptySymbol ?? fallback.emptySymbol
        self.deletedAlertTitle = raw.deletedAlertTitle ?? fallback.deletedAlertTitle
        self.deletedAlertMessage = raw.deletedAlertMessage ?? fallback.deletedAlertMessage
        self.okayActionTitle = raw.okayActionTitle ?? fallback.okayActionTitle
    }

    static func migrate(from version: OTFSemanticVersion, raw: Raw) throws -> ContactsConfiguration {
        ContactsConfiguration(from: raw)
    }
}
