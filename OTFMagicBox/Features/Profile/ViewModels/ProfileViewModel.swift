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
import Combine
import OTFCareKitStore
import OTFUtilities
import OTFTemplateBox
import OTFResearchKit
import OTFCloudClientAPI
import OTFCloudantStore

final class ProfileViewModel: ObservableObject {

    private enum FileConstants {
        static let profileConfig = "ProfileConfiguration"
        static let privacyPolicyConfig = "PrivacyPolicyConfiguration"
        static let termsOfServiceConfig = "TermsOfServiceConfiguration"
    }

    private enum ProfileFetchError: LocalizedError {
        case cloudantStoreUnavailable

        var errorDescription: String? {
            "Cloudant store unavailable"
        }
    }

    // MARK: - Publishers

    @Published var user: OCKPatient?
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var accountDeletedAlert = false
    @Published var deleteFailureAlert = false

    @Published private(set) var config: ProfileConfiguration = .fallback
    @Published private(set) var privacyPolicyConfig: PrivacyPolicyConfiguration = .fallback
    @Published private(set) var termsOfServiceConfig: TermsOfServiceConfiguration = .fallback

    // MARK: - Properties

    private var didFetchUser = false
    private var disposables = Set<AnyCancellable>()
    private let logger = OTFLogger.logger()
    private let decoder: OTFYAMLDecoding
    private let signOutRequest: () -> AnyPublisher<Response.LogOut, ForgeError>
    private let deleteUserRequest: (String) -> AnyPublisher<Response.DeleteAccount, ForgeError>
    private let moveToOnboarding: () -> Void
    private let localLogoutCleanup: () -> Void
    private let deleteAccountCleanup: () async -> Void
    private let syncCloudantStore: () -> Void
    private let keychainEmail: () -> String
    private let fetchPatientsByEmail: (String, @escaping (Result<[OCKPatient], Error>) -> Void) -> Void
    private let notificationCenter: NotificationCenter

    var userName: String {
        guard let components = user?.name else { return "" }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        return formatter.string(from: components)
    }

    var changePasswordEmail: String? {
        user?.remoteID
    }

    // MARK: - Init

    init(
        decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine(),
        signOutRequest: @escaping () -> AnyPublisher<Response.LogOut, ForgeError> = {
            OTFTheraforgeNetwork.shared.signOut()
        },
        deleteUserRequest: @escaping (String) -> AnyPublisher<Response.DeleteAccount, ForgeError> = {
            OTFTheraforgeNetwork.shared.deleteUser(userId: $0)
        },
        moveToOnboarding: @escaping () -> Void = {
            OTFTheraforgeNetwork.shared.moveToOnboardingView()
        },
        localLogoutCleanup: @escaping () -> Void = {
            ProfileViewModel.performLocalLogoutCleanup()
        },
        deleteAccountCleanup: @escaping () async -> Void = {
            ProfileViewModel.prepareWatchAuthForLocalAuthTransition()
            await LocalUserPurger.shared.purgeAll()
        },
        syncCloudantStore: @escaping () -> Void = {
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true, completion: nil)
        },
        keychainEmail: @escaping () -> String = {
            KeychainCloudManager.getEmailAddress
        },
        fetchPatientsByEmail: @escaping (String, @escaping (Result<[OCKPatient], Error>) -> Void) -> Void = { email, completion in
            guard let store = CareKitStoreManager.shared.cloudantStore else {
                completion(.failure(ProfileFetchError.cloudantStoreUnavailable))
                return
            }

            var query = OCKPatientQuery()
            query.remoteIDs = [email]
            query.limit = 1
            store.fetchPatients(query: query, callbackQueue: .main) { result in
                completion(result.mapError { $0 as Error })
            }
        },
        notificationCenter: NotificationCenter = .default
    ) {
        self.decoder = decoder
        self.signOutRequest = signOutRequest
        self.deleteUserRequest = deleteUserRequest
        self.moveToOnboarding = moveToOnboarding
        self.localLogoutCleanup = localLogoutCleanup
        self.deleteAccountCleanup = deleteAccountCleanup
        self.syncCloudantStore = syncCloudantStore
        self.keychainEmail = keychainEmail
        self.fetchPatientsByEmail = fetchPatientsByEmail
        self.notificationCenter = notificationCenter
        loadProfileConfiguration()
        loadLegalConfiguration()
    }

    // MARK: - Methods

    func onAppear() {
        guard !didFetchUser else { return }
        didFetchUser = true
        syncCloudantStore()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchUserFromDB()

            // Populate sample for previews
            if self?.user == nil, ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                self?.user = .samplePatient
            }
        }

        notificationCenter.publisher(for: .databaseSynchronized)
            .sink { [weak self] _ in self?.fetchUserFromDB() }
            .store(in: &disposables)

        notificationCenter.publisher(for: .deleteUserAccount)
            .sink { [weak self] _ in self?.accountDeletedAlert = true }
            .store(in: &disposables)
    }

    func acknowledgeAccountDeleted() {
        moveToOnboarding()
    }

    func fetchUserFromDB() {
        let email = keychainEmail()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !email.isEmpty else {
            logger.error("Profile fetch aborted: emailKey is empty in KeychainCloudManager.")
            return
        }

        isLoading = true
        fetchPatientsByEmail(email) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let patients):
                    self.user = patients.first
                    if self.user == nil {
                        self.logger.warning("No patient found for the current account.")
                    }
                case .failure:
                    self.logger.error("Profile patient fetch failed.")
                }
            }
        }
    }

    func signout() {
        signOutRequest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.showingAlert = true
                    self?.logger.error("Logout request failed.")
                }
            } receiveValue: { [weak self] _ in
                self?.localLogoutCleanup()
            }
            .store(in: &disposables)
    }

    func deleteUserAccount(userId: String) {
        deleteUserRequest(userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure:
                    self?.deleteFailureAlert = true
                    self?.logger.error("Delete account request failed.")
                default: break
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Delete account request succeeded.")
                Task {
                    await self.deleteAccountCleanup()
                    await MainActor.run {
                        self.notificationCenter.post(name: .deleteUserAccount, object: nil)
                    }
                }
            }
            .store(in: &disposables)
    }

    // MARK: - Private Methods

    private func loadProfileConfiguration() {
        do {
            config = try decoder.decode(FileConstants.profileConfig, as: ProfileConfiguration.self)
        } catch {
            logger.error("Profile config load error: \(error)")
            config = .fallback
        }
    }

    private func loadLegalConfiguration() {
        do {
            privacyPolicyConfig = try decoder.decode(FileConstants.privacyPolicyConfig, as: PrivacyPolicyConfiguration.self)
        } catch {
            logger.error("Privacy policy config load error: \(error)")
            privacyPolicyConfig = .fallback
        }

        do {
            termsOfServiceConfig = try decoder.decode(FileConstants.termsOfServiceConfig, as: TermsOfServiceConfiguration.self)
        } catch {
            logger.error("Terms of service config load error: \(error)")
            termsOfServiceConfig = .fallback
        }
    }
}

// MARK: - Forced logout

extension ProfileViewModel {

    private static var staticDisposables = Set<AnyCancellable>()
    private static let logger = OTFLogger.logger()

    static func forceLogoutDueToFailedPasscode() {
        OTFTheraforgeNetwork.shared.signOut()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    logger.warning("Force logout signOut failed.")
                }
                performLocalLogoutCleanup()
            } receiveValue: { _ in }
            .store(in: &staticDisposables)
    }

    private static func performLocalLogoutCleanup() {
        Task {
            prepareWatchAuthForLocalAuthTransition()
            await LocalUserPurger.shared.purgeAll()
            await MainActor.run {
                if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
                    ORKPasscodeViewController.removePasscodeFromKeychain()
                }
                KeychainWiper.wipeAll()
                OTFTheraforgeNetwork.shared.moveToOnboardingView()
            }
        }
    }

    private static func prepareWatchAuthForLocalAuthTransition() {
        let command = WatchAuthSessionStore.shared.makeLogoutCommand()
        CareKitStoreManager.shared.setWatchSyncReady(false)
        WatchAuthCommandPublisher.shared.publish(command, cancelOutstandingUserInfoTransfers: true)
    }
}
