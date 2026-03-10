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

import SwiftUI
import OTFUtilities
import OTFCareKitStore

struct ProfileView: View {

    @Environment(\.appConfiguration) private var appConfiguration

    @StateObject private var model = ProfileViewModel()
    @StateObject private var updateUserModel = UpdateUserViewModel()
    @StateObject private var networkObserver = OTFNetworkObserver()

    @State private var sheet: Sheet?
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false

    private let defaults: UserDefaults = .standard
    private let uploadManager = UploadDocumentManager()
    
    private var patientImage: Image? {
        guard let uiImage = updateUserModel.profileImage else { return nil }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        NavigationStack {
            List {
                if let user = model.user {

                    // Header
                    Section {
                        VStack {
                            let givenName = user.name.givenName ?? ""
                            let familyName = user.name.familyName ?? ""
                            PatientAvatar(image: patientImage, givenName: givenName, familyName: familyName)
                                .frame(width: 120, height: 120)
                                .overlay(alignment: .bottomTrailing) {
                                    NetworkIndicator(status: networkObserver.status)
                                        .offset(x: 16)
                                }

                            Text(model.userName)
                                .globalStyle(.titleFont)
                                .globalStyle(.titleFontWeight)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityAddTraits(.isHeader)
                    .listRowBackground(Color.clear)

                    // Settings
                    Section(model.config.sectionSettingsTitle.localized) {
                        NavigationLink {
                            UpdateUserProfileDetailView(user: user, model: updateUserModel)
                        } label: {
                            Text(model.config.manageProfileTitle.localized)
                                .globalStyle(.textFont)
                                .globalStyle(.textFontWeight)
                        }
                    }
                    .globalStyle(.headerProminence)

                    // Support
                    Section(model.config.sectionSupportTitle.localized) {
                        Group {
                            LabeledContent(model.config.supportEmailLabel.localized, value: appConfiguration.teamEmail)
                            LabeledContent(model.config.supportPhoneLabel.localized, value: appConfiguration.teamPhone)
                        }
                        .globalStyle(.textFont)
                        .globalStyle(.textFontWeight)
                    }
                    .globalStyle(.headerProminence)

                    // Logs
                    Section(model.config.sectionLogsTitle.localized) {
                        NavigationLink { LogView() } label: {
                            Text(model.config.diagnosticsTitle.localized)
                                .globalStyle(.textFont)
                                .globalStyle(.textFontWeight)
                        }
                    }
                    .globalStyle(.headerProminence)

                    // Account
                    Section(model.config.sectionAccountTitle.localized) {
                        Group {
                            Button(model.config.changePasswordTitle.localized) {
                                guard let email = model.changePasswordEmail else { return }
                                sheet = .changePassword(email: email)
                            }

                            Button(model.config.logoutButtonTitle.localized) {
                                showLogoutConfirmation = true
                            }
                        }
                        .globalStyle(.textFont)
                        .globalStyle(.textFontWeight)
                        .confirmationDialog(model.config.logoutConfirmDialogTitle.localized, isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                            Button(model.config.logoutConfirmActionTitle.localized, role: .destructive) {
                                model.signout()
                            }
                            Button(model.config.logoutCancelActionTitle.localized, role: .cancel) {}
                        }
                        .alert(model.config.logoutFailureAlertTitle.localized, isPresented: $model.showingAlert) {
                            Button(model.config.okayActionTitle.localized, role: .cancel) {}
                        }
                    }
                    .globalStyle(.headerProminence)

                    // Legal
                    let pdfData = consentPdfData(for: user)
                    let showConsent = appConfiguration.showConsentDocument && pdfData != nil
                    
                    if appConfiguration.showPrivacyAndTerms || showConsent {
                        Section(model.config.sectionLegalTitle.localized) {
                            if appConfiguration.showPrivacyAndTerms {
                                NavigationLink {
                                    LegalDetailView(
                                        title: model.config.privacyPolicyTitle.localized,
                                        content: model.privacyPolicyConfig.content.localized
                                    )
                                } label: {
                                    Text(model.config.privacyPolicyTitle.localized)
                                        .globalStyle(.textFont)
                                        .globalStyle(.textFontWeight)
                                }
                                
                                NavigationLink {
                                    LegalDetailView(
                                        title: model.config.termsOfServiceTitle.localized,
                                        content: model.termsOfServiceConfig.content.localized
                                    )
                                } label: {
                                    Text(model.config.termsOfServiceTitle.localized)
                                        .globalStyle(.textFont)
                                        .globalStyle(.textFontWeight)
                                }
                            }
                            
                            if showConsent, let pdfData {
                                NavigationLink {
                                    PDFViewer(pdfData: pdfData, navTitle: model.config.pdfViewerTitle.localized)
                                } label: {
                                    Text(model.config.consentDocumentTitle.localized)
                                        .globalStyle(.textFont)
                                        .globalStyle(.textFontWeight)
                                }
                            }
                        }
                        .globalStyle(.headerProminence)
                    }

                    // Delete Account
                    Section {
                        Button(model.config.deleteAccountButtonTitle.localized, role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .globalStyle(.textFont)
                        .globalStyle(.textFontWeight)
                        .confirmationDialog(model.config.deleteAccountConfirmDialogTitle.localized, isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button(model.config.deleteAccountConfirmActionTitle.localized, role: .destructive) {
                                model.deleteUserAccount(userId: user.id)
                            }
                            Button(model.config.deleteAccountCancelActionTitle.localized, role: .cancel) {}
                        }
                        .alert(model.config.deleteAccountFailureAlertTitle.localized, isPresented: $model.deleteFailureAlert) {
                            Button(model.config.okayActionTitle.localized, role: .cancel) {}
                        }
                    }
                }
            }
            .globalStyle(.navigationTitleDisplayMode)
            .navigationTitle(model.config.navTitle.localized)
            .task {
                model.onAppear()
                // First run: try to show something immediately from disk if we have it
                if let user = model.user {
                    updateUserModel.ensureProfileImage(for: user)
                }
            }
            .onChange(of: model.user) { user in
                guard let user else { return }
                // Profile image
                updateUserModel.ensureProfileImage(for: user)

                // Consent download (unchanged)
                if let consentId = user.attachments?.consentForm?.attachmentID {
                    updateUserModel.downloadFile(attachmentID: consentId, isProfile: false)
                }
            }
            .onReceive(updateUserModel.profileUpdateComplete) { _ in
                model.fetchUserFromDB()
            }
            .onReceive(NotificationCenter.default.publisher(for: .databaseSynchronized)) { _ in
                if let user = model.user {
                    updateUserModel.ensureProfileImage(for: user)
                }
            }
            .sheet(item: $sheet) { result in
                switch result {
                case .changePassword(let email):
                    ChangePasswordDetailsView(viewModel: ChangePasswordViewModel(email: email))
                }
            }
            .alert(model.config.accountDeletedAlertTitle.localized, isPresented: $model.accountDeletedAlert) {
                Button(model.config.okayActionTitle.localized, role: .cancel) {
                    model.acknowledgeAccountDeleted()
                }
            } message: {
                Text(model.config.accountDeletedAlertMessage.localized)
            }
        }
    }
}

// MARK: - Helpers

extension ProfileView {
    private func consentPdfData(for user: OCKPatient) -> Data? {
        guard let attachment = user.attachments?.consentForm,
              let localData = try? FileManager.readFromDocuments(filename: attachment.attachmentID),
              let keys = updateUserModel.attachmentKeys[attachment.attachmentID] else {  return nil }

        let decrypted = uploadManager.decryptedFile(
            file: localData,
            encryptedFileKeyHex: keys.encryptedFileKey,
            hashFileKey: keys.hashFileKey
        )
        return decrypted.isEmpty ? nil : decrypted
    }
}

extension ProfileView {
    enum Sheet: Hashable, Identifiable {
        var id: Self { self }
        case changePassword(email: String)
    }
}

// MARK: - Previews

#Preview {
    ProfileView()
}
