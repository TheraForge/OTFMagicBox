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
struct ProfileConfiguration: Codable {
    let version: String

    let navTitle: OTFStringLocalized
    let pdfViewerTitle: OTFStringLocalized

    let sectionSettingsTitle: OTFStringLocalized
    let sectionSupportTitle: OTFStringLocalized
    let sectionLogsTitle: OTFStringLocalized
    let sectionAccountTitle: OTFStringLocalized

    let manageProfileTitle: OTFStringLocalized
    let diagnosticsTitle: OTFStringLocalized
    let changePasswordTitle: OTFStringLocalized
    let consentDocumentTitle: OTFStringLocalized

    let supportEmailLabel: OTFStringLocalized
    let supportPhoneLabel: OTFStringLocalized

    let accountDeletedAlertTitle: OTFStringLocalized
    let accountDeletedAlertMessage: OTFStringLocalized
    let okayActionTitle: OTFStringLocalized

    let logoutButtonTitle: OTFStringLocalized
    let logoutConfirmDialogTitle: OTFStringLocalized
    let logoutConfirmActionTitle: OTFStringLocalized
    let logoutCancelActionTitle: OTFStringLocalized
    let logoutFailureAlertTitle: OTFStringLocalized

    let deleteAccountButtonTitle: OTFStringLocalized
    let deleteAccountConfirmDialogTitle: OTFStringLocalized
    let deleteAccountConfirmActionTitle: OTFStringLocalized
    let deleteAccountCancelActionTitle: OTFStringLocalized
    let deleteAccountFailureAlertTitle: OTFStringLocalized

    let sectionLegalTitle: OTFStringLocalized
    let privacyPolicyTitle: OTFStringLocalized
    let termsOfServiceTitle: OTFStringLocalized
}

extension ProfileConfiguration: OTFVersionedDecodable {
    typealias Raw = RawProfileConfiguration

    static let fallback = ProfileConfiguration(
        version: "2.0.0",
        navTitle: "Profile",
        pdfViewerTitle: "TheraForge Consent",
        sectionSettingsTitle: "Settings",
        sectionSupportTitle: "Support",
        sectionLogsTitle: "Logs",
        sectionAccountTitle: "Account",
        manageProfileTitle: "Manage Profile",
        diagnosticsTitle: "Diagnostics",
        changePasswordTitle: "Change Password",
        consentDocumentTitle: "Consent Document",
        supportEmailLabel: "Email",
        supportPhoneLabel: "Telephone",
        accountDeletedAlertTitle: "Account Deleted",
        accountDeletedAlertMessage: "Your account is deleted from one of your device",
        okayActionTitle: "OK",
        logoutButtonTitle: "Logout",
        logoutConfirmDialogTitle: "Are you sure?",
        logoutConfirmActionTitle: "Logout",
        logoutCancelActionTitle: "Cancel",
        logoutFailureAlertTitle: "Failed to logout",
        deleteAccountButtonTitle: "Delete Account",
        deleteAccountConfirmDialogTitle: "Are you sure? This will remove all your information",
        deleteAccountConfirmActionTitle: "Delete Account",
        deleteAccountCancelActionTitle: "Cancel",
        deleteAccountFailureAlertTitle: "Failed to delete account",
        sectionLegalTitle: "Legal",
        privacyPolicyTitle: "Privacy Policy",
        termsOfServiceTitle: "Terms of Service"
    )

    init(from raw: RawProfileConfiguration) {
        let fallback = Self.fallback
        version = raw.version ?? fallback.version
        navTitle = raw.navTitle ?? fallback.navTitle
        pdfViewerTitle = raw.pdfViewerTitle ?? fallback.pdfViewerTitle
        sectionSettingsTitle = raw.sectionSettingsTitle ?? fallback.sectionSettingsTitle
        sectionSupportTitle = raw.sectionSupportTitle ?? fallback.sectionSupportTitle
        sectionLogsTitle = raw.sectionLogsTitle ?? fallback.sectionLogsTitle
        sectionAccountTitle = raw.sectionAccountTitle ?? fallback.sectionAccountTitle
        manageProfileTitle = raw.manageProfileTitle ?? fallback.manageProfileTitle
        diagnosticsTitle = raw.diagnosticsTitle ?? fallback.diagnosticsTitle
        changePasswordTitle = raw.changePasswordTitle ?? fallback.changePasswordTitle
        consentDocumentTitle = raw.consentDocumentTitle ?? fallback.consentDocumentTitle
        supportEmailLabel = raw.supportEmailLabel ?? fallback.supportEmailLabel
        supportPhoneLabel = raw.supportPhoneLabel ?? fallback.supportPhoneLabel
        accountDeletedAlertTitle = raw.accountDeletedAlertTitle ?? fallback.accountDeletedAlertTitle
        accountDeletedAlertMessage = raw.accountDeletedAlertMessage ?? fallback.accountDeletedAlertMessage
        okayActionTitle = raw.okayActionTitle ?? fallback.okayActionTitle
        logoutButtonTitle = raw.logoutButtonTitle ?? fallback.logoutButtonTitle
        logoutConfirmDialogTitle = raw.logoutConfirmDialogTitle ?? fallback.logoutConfirmDialogTitle
        logoutConfirmActionTitle = raw.logoutConfirmActionTitle ?? fallback.logoutConfirmActionTitle
        logoutCancelActionTitle = raw.logoutCancelActionTitle ?? fallback.logoutCancelActionTitle
        logoutFailureAlertTitle = raw.logoutFailureAlertTitle ?? fallback.logoutFailureAlertTitle
        deleteAccountButtonTitle = raw.deleteAccountButtonTitle ?? fallback.deleteAccountButtonTitle
        deleteAccountConfirmDialogTitle = raw.deleteAccountConfirmDialogTitle ?? fallback.deleteAccountConfirmDialogTitle
        deleteAccountConfirmActionTitle = raw.deleteAccountConfirmActionTitle ?? fallback.deleteAccountConfirmActionTitle
        deleteAccountCancelActionTitle = raw.deleteAccountCancelActionTitle ?? fallback.deleteAccountCancelActionTitle
        deleteAccountFailureAlertTitle = raw.deleteAccountFailureAlertTitle ?? fallback.deleteAccountFailureAlertTitle
        sectionLegalTitle = raw.sectionLegalTitle ?? fallback.sectionLegalTitle
        privacyPolicyTitle = raw.privacyPolicyTitle ?? fallback.privacyPolicyTitle
        termsOfServiceTitle = raw.termsOfServiceTitle ?? fallback.termsOfServiceTitle
    }

    static func migrate(from version: OTFSemanticVersion, raw: Raw) throws -> ProfileConfiguration {
        ProfileConfiguration(from: raw)
    }
}
