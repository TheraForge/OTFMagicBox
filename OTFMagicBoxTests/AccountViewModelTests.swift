/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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

import Combine
import Foundation
import OTFCareKitStore
import OTFCloudClientAPI
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("Account view models")
struct AccountViewModelTests {
    @Test("Change password loads decoded configuration")
    func changePasswordLoadsDecodedConfiguration() {
        let config = ChangePasswordConfiguration(
            version: "2.1.0",
            navTitle: "Security",
            emailLabel: "Account Email",
            sectionTitle: "Password",
            oldPasswordPlaceholder: "Current Password",
            newPasswordPlaceholder: "New Password",
            resetButtonTitle: "Update",
            cancelButtonTitle: "Dismiss",
            failureAlertTitle: "Could Not Update",
            okayActionTitle: "Done"
        )
        let decoder = AccountFakeYAMLDecoder(stubs: ["ChangePasswordConfiguration": config])

        let model = ChangePasswordViewModel(email: "patient@example.com", decoder: decoder)

        #expect(decoder.decodedFiles == ["ChangePasswordConfiguration"])
        #expect(model.config.version == "2.1.0")
        #expect(model.config.navTitle.localized == "Security")
        #expect(model.config.resetButtonTitle.localized == "Update")
    }

    @Test("Change password falls back after decoder failure")
    func changePasswordFallsBackAfterDecoderFailure() {
        let decoder = AccountFakeYAMLDecoder(stubs: [:])

        let model = ChangePasswordViewModel(email: "patient@example.com", decoder: decoder)

        #expect(decoder.decodedFiles == ["ChangePasswordConfiguration"])
        #expect(model.config.navTitle.localized == ChangePasswordConfiguration.fallback.navTitle.localized)
        #expect(model.config.resetButtonTitle.localized == ChangePasswordConfiguration.fallback.resetButtonTitle.localized)
    }

    @Test("Change password sends request and dismisses on success")
    func changePasswordSendsRequestAndDismissesOnSuccess() async throws {
        var capturedRequest: (email: String, oldPassword: String, newPassword: String)?
        var dismissalValues = [Bool]()
        let model = ChangePasswordViewModel(
            email: "patient@example.com",
            decoder: AccountFakeYAMLDecoder(stubs: ["ChangePasswordConfiguration": ChangePasswordConfiguration.fallback]),
            changePasswordRequest: { email, oldPassword, newPassword in
                capturedRequest = (email, oldPassword, newPassword)
                return Just(Response.ChangePassword(message: "Password changed"))
                    .setFailureType(to: ForgeError.self)
                    .eraseToAnyPublisher()
            }
        )
        let cancellable = model.viewDismissModePublisher.sink { dismissalValues.append($0) }
        defer { cancellable.cancel() }
        model.oldPassword = "old-pass"
        model.newPassword = "new-pass"

        model.changePassword()

        try await waitUntil { dismissalValues == [true] }
        #expect(capturedRequest?.email == "patient@example.com")
        #expect(capturedRequest?.oldPassword == "old-pass")
        #expect(capturedRequest?.newPassword == "new-pass")
        #expect(!model.showFailureAlert)
    }

    @Test("Change password exposes failure message on request failure")
    func changePasswordExposesFailureMessageOnRequestFailure() async throws {
        let model = ChangePasswordViewModel(
            email: "patient@example.com",
            decoder: AccountFakeYAMLDecoder(stubs: ["ChangePasswordConfiguration": ChangePasswordConfiguration.fallback]),
            changePasswordRequest: { _, _, _ in
                Fail(error: makeAccountForgeError(message: "Current password is incorrect"))
                    .eraseToAnyPublisher()
            }
        )

        model.changePassword()

        try await waitUntil { model.showFailureAlert }
        #expect(model.errorMessage == "Current password is incorrect")
    }

    @Test("Change password repeated failures publish latest message")
    func changePasswordRepeatedFailuresPublishLatestMessage() async throws {
        var messages = ["Old password is wrong", "Password is too short"]
        let model = ChangePasswordViewModel(
            email: "patient@example.com",
            decoder: AccountFakeYAMLDecoder(stubs: ["ChangePasswordConfiguration": ChangePasswordConfiguration.fallback]),
            changePasswordRequest: { _, _, _ in
                let message = messages.removeFirst()
                return Fail(error: makeAccountForgeError(message: message))
                    .eraseToAnyPublisher()
            }
        )

        model.changePassword()
        try await waitUntil { model.errorMessage == "Old password is wrong" }
        model.changePassword()
        try await waitUntil { model.errorMessage == "Password is too short" }

        #expect(model.showFailureAlert)
    }

    @Test("Profile loads available configs and falls back only for missing legal config")
    func profileLoadsAvailableConfigsAndFallsBackOnlyForMissingLegalConfig() {
        let config = ProfileConfiguration(
            version: "2.1.0",
            navTitle: "Account",
            pdfViewerTitle: "Consent PDF",
            sectionSettingsTitle: "Settings",
            sectionSupportTitle: "Help",
            sectionLogsTitle: "Diagnostics",
            sectionAccountTitle: "Account",
            manageProfileTitle: "Edit Profile",
            diagnosticsTitle: "Logs",
            changePasswordTitle: "Security",
            consentDocumentTitle: "Consent",
            supportEmailLabel: "Email",
            supportPhoneLabel: "Phone",
            accountDeletedAlertTitle: "Deleted",
            accountDeletedAlertMessage: "Deleted elsewhere",
            okayActionTitle: "OK",
            logoutButtonTitle: "Sign Out",
            logoutConfirmDialogTitle: "Leave?",
            logoutConfirmActionTitle: "Sign Out",
            logoutCancelActionTitle: "Stay",
            logoutFailureAlertTitle: "Logout Failed",
            deleteAccountButtonTitle: "Delete",
            deleteAccountConfirmDialogTitle: "Delete account?",
            deleteAccountConfirmActionTitle: "Delete",
            deleteAccountCancelActionTitle: "Cancel",
            deleteAccountFailureAlertTitle: "Delete Failed",
            sectionLegalTitle: "Legal",
            privacyPolicyTitle: "Privacy",
            termsOfServiceTitle: "Terms"
        )
        let decoder = AccountFakeYAMLDecoder(stubs: [
            "ProfileConfiguration": config,
            "TermsOfServiceConfiguration": TermsOfServiceConfiguration.fallback
        ])

        let model = ProfileViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == [
            "ProfileConfiguration",
            "PrivacyPolicyConfiguration",
            "TermsOfServiceConfiguration"
        ])
        #expect(model.config.version == "2.1.0")
        #expect(model.config.navTitle.localized == "Account")
        #expect(model.privacyPolicyConfig.content.localized == PrivacyPolicyConfiguration.fallback.content.localized)
        #expect(model.termsOfServiceConfig.content.localized == TermsOfServiceConfiguration.fallback.content.localized)
    }

    @Test("Profile falls back for all configs after decoder failures")
    func profileFallsBackForAllConfigsAfterDecoderFailures() {
        let decoder = AccountFakeYAMLDecoder(stubs: [:])

        let model = ProfileViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == [
            "ProfileConfiguration",
            "PrivacyPolicyConfiguration",
            "TermsOfServiceConfiguration"
        ])
        #expect(model.config.navTitle.localized == ProfileConfiguration.fallback.navTitle.localized)
        #expect(model.privacyPolicyConfig.content.localized == PrivacyPolicyConfiguration.fallback.content.localized)
        #expect(model.termsOfServiceConfig.content.localized == TermsOfServiceConfiguration.fallback.content.localized)
    }

    @Test("Profile user name is empty without a loaded user")
    func profileUserNameIsEmptyWithoutLoadedUser() {
        let model = ProfileViewModel(decoder: AccountFakeYAMLDecoder(profileStubs: true))

        #expect(model.userName.isEmpty)
        #expect(model.changePasswordEmail == nil)
    }

    @Test("Profile signout runs local cleanup on success")
    func profileSignoutRunsLocalCleanupOnSuccess() async throws {
        var cleanupCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            signOutRequest: {
                Just(Response.LogOut(message: "Signed out"))
                    .setFailureType(to: ForgeError.self)
                    .eraseToAnyPublisher()
            },
            localLogoutCleanup: { cleanupCount += 1 }
        )

        model.signout()

        try await waitUntil { cleanupCount == 1 }
        #expect(!model.showingAlert)
    }

    @Test("Profile signout shows alert and skips cleanup on failure")
    func profileSignoutShowsAlertAndSkipsCleanupOnFailure() async throws {
        var cleanupCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            signOutRequest: {
                Fail(error: makeAccountForgeError(message: "Signout failed"))
                    .eraseToAnyPublisher()
            },
            localLogoutCleanup: { cleanupCount += 1 }
        )

        model.signout()

        try await waitUntil { model.showingAlert }
        #expect(cleanupCount == 0)
    }

    @Test("Profile delete account runs cleanup and posts notification on success")
    func profileDeleteAccountRunsCleanupAndPostsNotificationOnSuccess() async throws {
        let notificationCenter = NotificationCenter()
        var requestedUserID: String?
        var cleanupCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            deleteUserRequest: { userID in
                requestedUserID = userID
                return Just(Response.DeleteAccount(message: "Deleted"))
                    .setFailureType(to: ForgeError.self)
                    .eraseToAnyPublisher()
            },
            deleteAccountCleanup: {
                cleanupCount += 1
            },
            notificationCenter: notificationCenter
        )
        let notificationTask = Task {
            try await firstNotification(named: .deleteUserAccount, center: notificationCenter)
        }

        model.deleteUserAccount(userId: "user-123")

        _ = try await notificationTask.value
        #expect(requestedUserID == "user-123")
        #expect(cleanupCount == 1)
        #expect(!model.deleteFailureAlert)
    }

    @Test("Profile delete account shows failure alert without cleanup")
    func profileDeleteAccountShowsFailureAlertWithoutCleanup() async throws {
        var cleanupCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            deleteUserRequest: { _ in
                Fail(error: makeAccountForgeError(message: "Delete failed"))
                    .eraseToAnyPublisher()
            },
            deleteAccountCleanup: {
                cleanupCount += 1
            }
        )

        model.deleteUserAccount(userId: "user-123")

        try await waitUntil { model.deleteFailureAlert }
        #expect(cleanupCount == 0)
    }

    @Test("Profile acknowledge account deleted moves to onboarding")
    func profileAcknowledgeAccountDeletedMovesToOnboarding() {
        var moveToOnboardingCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            moveToOnboarding: { moveToOnboardingCount += 1 }
        )

        model.acknowledgeAccountDeleted()

        #expect(moveToOnboardingCount == 1)
    }

    @Test("Profile fetch trims lowercases email and publishes first patient")
    func profileFetchTrimsLowercasesEmailAndPublishesFirstPatient() async throws {
        var capturedEmail: String?
        let patient = makeAccountPatient(remoteID: "patient@example.com")
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            keychainEmail: { "  Patient@Example.COM  " },
            fetchPatientsByEmail: { email, completion in
                capturedEmail = email
                completion(.success([patient]))
            }
        )

        model.fetchUserFromDB()

        try await waitUntil { model.user?.remoteID == "patient@example.com" && !model.isLoading }
        #expect(capturedEmail == "patient@example.com")
        #expect(model.userName == "Test Patient")
        #expect(model.changePasswordEmail == "patient@example.com")
    }

    @Test("Profile fetch success with empty patients clears loading and leaves user empty")
    func profileFetchSuccessWithEmptyPatientsClearsLoadingAndLeavesUserEmpty() async throws {
        var fetchCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            keychainEmail: { "patient@example.com" },
            fetchPatientsByEmail: { _, completion in
                fetchCount += 1
                completion(.success([]))
            }
        )

        model.fetchUserFromDB()

        try await waitUntil { fetchCount == 1 && !model.isLoading }
        #expect(model.user == nil)
        #expect(model.userName.isEmpty)
        #expect(model.changePasswordEmail == nil)
    }

    @Test("Profile fetch skips store request when keychain email is empty")
    func profileFetchSkipsStoreRequestWhenKeychainEmailIsEmpty() {
        var fetchCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            keychainEmail: { "  " },
            fetchPatientsByEmail: { _, _ in fetchCount += 1 }
        )

        model.fetchUserFromDB()

        #expect(fetchCount == 0)
        #expect(!model.isLoading)
        #expect(model.user == nil)
    }

    @Test("Profile fetch failure clears loading without replacing user")
    func profileFetchFailureClearsLoadingWithoutReplacingUser() async throws {
        var fetchCount = 0
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            keychainEmail: { "patient@example.com" },
            fetchPatientsByEmail: { _, completion in
                fetchCount += 1
                completion(.failure(AccountProfileFetchError.failed))
            }
        )

        model.fetchUserFromDB()

        try await waitUntil { fetchCount == 1 && !model.isLoading }
        #expect(model.user == nil)
    }

    @Test("Profile onAppear is idempotent and subscribes to account notifications")
    func profileOnAppearIsIdempotentAndSubscribesToAccountNotifications() async throws {
        let notificationCenter = NotificationCenter()
        var syncCount = 0
        var fetchEmails = [String]()
        let patient = makeAccountPatient(remoteID: "patient@example.com")
        let model = ProfileViewModel(
            decoder: AccountFakeYAMLDecoder(profileStubs: true),
            syncCloudantStore: { syncCount += 1 },
            keychainEmail: { "patient@example.com" },
            fetchPatientsByEmail: { email, completion in
                fetchEmails.append(email)
                completion(.success([patient]))
            },
            notificationCenter: notificationCenter
        )

        model.onAppear()
        model.onAppear()
        notificationCenter.post(name: .databaseSynchronized, object: nil)
        notificationCenter.post(name: .deleteUserAccount, object: nil)

        try await waitUntil {
            fetchEmails == ["patient@example.com"] &&
            model.accountDeletedAlert &&
            model.user?.remoteID == "patient@example.com"
        }
        #expect(syncCount == 1)
    }
}

private final class AccountFakeYAMLDecoder: OTFYAMLDecoding {
    private let stubs: [String: Any]
    private(set) var decodedFiles: [String] = []

    init(stubs: [String: Any]) {
        self.stubs = stubs
    }

    convenience init(profileStubs: Bool) {
        self.init(stubs: [
            "ProfileConfiguration": ProfileConfiguration.fallback,
            "PrivacyPolicyConfiguration": PrivacyPolicyConfiguration.fallback,
            "TermsOfServiceConfiguration": TermsOfServiceConfiguration.fallback
        ])
    }

    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        decodedFiles.append(file)
        guard let value = stubs[file] as? T else {
            throw AccountFakeYAMLDecoderError.missingStub(file)
        }
        return value
    }
}

private enum AccountFakeYAMLDecoderError: Error {
    case missingStub(String)
}

private enum AccountProfileFetchError: Error {
    case failed
}

private func makeAccountForgeError(message: String, statusCode: Int = 500) -> ForgeError {
    ForgeError(error: .init(statusCode: statusCode, name: "Test", message: message, code: nil))
}

private func makeAccountPatient(remoteID: String) -> OCKPatient {
    var patient = OCKPatient(id: "patient-id", givenName: "Test", familyName: "Patient")
    patient.remoteID = remoteID
    return patient
}
