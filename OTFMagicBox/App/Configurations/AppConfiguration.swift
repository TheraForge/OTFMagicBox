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
struct AppConfiguration: Codable {
    let version: String
    let apiKey: String
    let teamWebsite: String
    let teamEmail: String
    let teamPhone: String
    let scheduleTitle: OTFStringLocalized
    let contactsTitle: OTFStringLocalized
    let checkupTitle: OTFStringLocalized
    let uiTitle: OTFStringLocalized
    let profileTitle: OTFStringLocalized
    let playgroundTitle: OTFStringLocalized
    let scheduleSymbol: String
    let contactsSymbol: String
    let checkupSymbol: String
    let playgroundSymbol: String
    let uiSymbol: String
    let profileSymbol: String
    let useFilledSymbols: Bool
    let useCareKit: Bool
    let showCheckupScreen: Bool
    let showUIScreen: Bool
    let showPrivacyAndTerms: Bool
    let showConsentDocument: Bool
    let playgroundMode: Bool
    let alertTitle: OTFStringLocalized
    let alertMessage: OTFStringLocalized
}

extension AppConfiguration: OTFVersionedDecodable {
    typealias Raw = RawAppConfiguration

    static let fallback = AppConfiguration(
        version: "2.0.0",
        apiKey: "<your-api-key>",
        teamWebsite: "<your-web-site-url>",
        teamEmail: "<your-team-email>",
        teamPhone: "<your-team-phone>",
        scheduleTitle: "Schedule",
        contactsTitle: "Contacts",
        checkupTitle: "Check-Up",
        uiTitle: "UI Lab",
        profileTitle: "Profile",
        playgroundTitle: "Playground",
        scheduleSymbol: "calendar",
        contactsSymbol: "heart",
        checkupSymbol: "checkmark.circle",
        playgroundSymbol: "apple.image.playground",
        uiSymbol: "uiwindow.split.2x1",
        profileSymbol: "person",
        useFilledSymbols: false,
        useCareKit: true,
        showCheckupScreen: true,
        showUIScreen: true,
        showPrivacyAndTerms: true,
        showConsentDocument: true,
        playgroundMode: false,
        alertTitle: "API Key Missing",
        alertMessage: "Please set a valid API Key to use the app"
    )

    init(from raw: RawAppConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.apiKey = raw.apiKey ?? fallback.apiKey
        self.teamWebsite = raw.teamWebsite ?? fallback.teamWebsite
        self.teamEmail = raw.teamEmail ?? fallback.teamEmail
        self.teamPhone = raw.teamPhone ?? fallback.teamPhone
        self.scheduleTitle = raw.scheduleTitle ?? fallback.scheduleTitle
        self.contactsTitle = raw.contactsTitle ?? fallback.contactsTitle
        self.checkupTitle = raw.checkupTitle ?? fallback.checkupTitle
        self.uiTitle = raw.uiTitle ?? fallback.uiTitle
        self.profileTitle = raw.profileTitle ?? fallback.profileTitle
        self.playgroundTitle = raw.playgroundTitle ?? fallback.playgroundTitle
        self.scheduleSymbol = raw.scheduleSymbol ?? fallback.scheduleSymbol
        self.contactsSymbol = raw.contactsSymbol ?? fallback.contactsSymbol
        self.checkupSymbol = raw.checkupSymbol ?? fallback.checkupSymbol
        self.playgroundSymbol = raw.playgroundSymbol ?? fallback.playgroundSymbol
        self.uiSymbol = raw.uiSymbol ?? fallback.uiSymbol
        self.profileSymbol = raw.profileSymbol ?? fallback.profileSymbol
        self.useFilledSymbols = raw.useFilledSymbols ?? fallback.useFilledSymbols
        self.useCareKit = raw.useCareKit ?? fallback.useCareKit
        self.showCheckupScreen = raw.showCheckupScreen ?? fallback.showCheckupScreen
        self.showUIScreen = raw.showUIScreen ?? fallback.showUIScreen
        self.showPrivacyAndTerms = raw.showPrivacyAndTerms ?? fallback.showPrivacyAndTerms
        self.showConsentDocument = raw.showConsentDocument ?? fallback.showConsentDocument
        self.playgroundMode = raw.playgroundMode ?? fallback.playgroundMode
        self.alertTitle = raw.alertTitle ?? fallback.alertTitle
        self.alertMessage = raw.alertMessage ?? fallback.alertMessage
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawAppConfiguration) throws -> AppConfiguration {
        AppConfiguration(from: raw)
    }
}
