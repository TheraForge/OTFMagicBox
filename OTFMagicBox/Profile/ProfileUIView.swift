/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFCareKitStore
import Sodium

/// A view that displays and manages the user's profile information
struct ProfileUIView: View {
    // MARK: - Core State Properties
    @State private(set) var user: OCKPatient?
    @State var isLoading = true
    @State private var isPresenting = false
    @State private var isPresentingDiagnosticAlert = false
    @State var document = Data()
    let manager = UploadDocumentManager()
    @StateObject private var viewModel = UpdateUserViewModel()
    var hint: String?
    
    // MARK: - New State Management
    /// Manages and observes network connectivity status
    @StateObject private var networkManager = OTFNetworkObserver()
    /// Controls the presentation of the change password sheet
    @State private var isShowingChangePassword = false
    /// Stores the user's profile image
    @State var profileImage: UIImage?

    // MARK: - Computed Properties
    /// Formats the user's full name from given and family names
    var userName: String {
        guard let givenName = user?.name.givenName,
              let familyName = user?.name.familyName else {
            return ""
        }
        return "\(givenName) \(familyName)"
    }
    
    /// Converts the profile image to SwiftUI Image type if available
    var patientImage: Image? {
        guard let profileImage = viewModel.profileImage else { return nil }
        return Image(uiImage: profileImage)
    }
    
    @ViewBuilder
    func patientAvatarHeader(for user: OCKPatient) -> some View {
        let avatar = PatientAvatar(image: patientImage,
                                   givenName: user.name.givenName ?? "",
                                   familyName: user.name.familyName ?? "")
            
        let networkIndicator = NetworkIndicator(status: networkManager.status)
        
        if #available(iOS 15.0, *) {
            avatar
            .overlay(alignment: .bottomTrailing) {
                networkIndicator
            }
        } else {
            ZStack(alignment: .bottomTrailing) {
                avatar
                networkIndicator
            }
        }
    }

    // MARK: - View Body
    var body: some View {
        NavigationView {
            List {
                if let user = user {
                    // MARK: Profile Header Section
                    Section {
                        // Profile avatar and network status indicator
                        VStack {
                            patientAvatarHeader(for: user)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(Constants.CustomiseStrings.profilePicture) \(userName)")
                                .frame(width: Metrics.PROFILE_MAIN_AVATAR_SIZE,
                                       height: Metrics.PROFILE_MAIN_AVATAR_SIZE)
                            
                            // User name display
                            Text(userName)
                                .font(.title)
                                .fontWeight(.bold)
                                .accessibilityAddTraits(.isHeader)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // MARK: Settings Section
                    Section {
                        NavigationLink(destination: UpdateUserProfileDetailView(user: user, viewModel: viewModel)) {
                            Text(Constants.CustomiseStrings.viewProfile)
                        }
                    } header: {
                        listHeader(.init(stringLiteral: Constants.CustomiseStrings.settings))
                    }
                    .listRowBackground(Color.otfCellBackground)
                    
                    Section {
                        HStack {
                            Text(Constants.CustomiseStrings.email)
                            Spacer()
                            Text(YmlReader().teamEmail)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(Constants.CustomiseStrings.email): \(YmlReader().teamEmail)")
                        
                        HStack {
                            Text(Constants.CustomiseStrings.telephone)
                            Spacer()
                            Text(YmlReader().teamPhone)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(Constants.CustomiseStrings.telephone): \(YmlReader().teamPhone)")
                        
                        NavigationLink {
                            ContactsViewController(storeManager: CareKitStoreManager.shared.synchronizedStoreManager)
                                .ignoresSafeArea()
                                .navigationTitle(Constants.CustomiseStrings.contacts)
                        } label: {
                            Text(Constants.CustomiseStrings.contacts)
                                .textCase(nil)
                        }
                        .accessibilityHint(Constants.CustomiseStrings.contacts)
                    } header: {
                        listHeader(.init(stringLiteral: Constants.CustomiseStrings.support))
                    }.listRowBackground(Color.otfCellBackground)
                    
                    // MARK: Log Viewer section
                    
                    Section {
                        if #available(iOS 15.0, *){
                            NavigationLink(destination: LogViewer()) {
                                Text(ModuleAppYmlReader().profileData?.diagnosticsText ?? Constants.CustomiseStrings.diagnostics)
                            }
                            .accessibilityHint(Constants.CustomiseStrings.logs)
                            .listRowBackground(Color.otfCellBackground)
                        }
                        else {
                            Button(action: {
                                isPresentingDiagnosticAlert = true
                            }) {
                                Text(ModuleAppYmlReader().profileData?.diagnosticsText ?? Constants.CustomiseStrings.diagnostics)
                                    .foregroundColor(.otfTextColor)
                                    .font(Font.otfAppFont)
                                    .fontWeight(Font.otfFontWeight)
                            }
                            .accessibilityHint(Constants.CustomiseStrings.logs)
                        }
                    } header: {
                        listHeader(.init(stringLiteral: Constants.CustomiseStrings.logs))
                    }
                
                    // MARK: Account Management Section
                    Section {
                        Button(Constants.CustomiseStrings.changePassword) {
                            isShowingChangePassword = true
                        }
                        .accessibilityHint(Constants.CustomiseStrings.password)
                        LogoutView()
                    } header: {
                        listHeader(.init(stringLiteral: Constants.CustomiseStrings.account))
                    }.listRowBackground(Color.otfCellBackground)
                    
                    // MARK: Consent Document Section
                    if let attachmentID = user.attachments?.consentForm?.attachmentID, let hashFileKey = user.attachments?.consentForm?.hashFileKey {
                        let doc = document.retriveFile(fileName: attachmentID)
                        if doc != nil {
                            Section {
                                NavigationLink(destination: PDFViewer(
                                    pdfData:
                                        KeychainCloudManager.isKeyStored(key: KeychainKeys.defaultStorageKey) ? manager.decryptedFile(file: doc!, hashFileKey: hashFileKey) : doc!),
                                               label: {
                                    Text(ModuleAppYmlReader().profileData?.consentText ?? Constants.CustomiseStrings.consetDocument)
                                })
                            }
                        }
                    }
                    
                    // MARK: Account Deletion Section
                    Section {
                        DeleteAccountView(user: user)
                    }
                    .listRowBackground(Color.otfCellBackground)
                }
            }
            // MARK: - View Modifiers and Event Handlers
            .accessibilityLabel(Constants.CustomiseStrings.profile)
            .onLoad {
                // Initialize view and fetch user data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    fetchUserFromDB()
                }
                // Configure UI appearance
                UITableView.appearance().backgroundColor = YmlReader().appStyle.backgroundColor.color
                UITableViewCell.appearance().backgroundColor = YmlReader().appStyle.backgroundColor.color
                UITableView.appearance().separatorColor = YmlReader().appStyle.separatorColor.color
            }
            // Handle database synchronization and account deletion events
            .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { _ in
                fetchUserFromDB()
            }
            .onReceive(NotificationCenter.default.publisher(for: .deleteUserAccount)) { _ in
                isPresenting = true
            }
            // Handle profile image updates
            .onReceive(viewModel.profileImageData) { data in
                if let image = UIImage(data: data) {
                    self.profileImage = image
                }
            }
            .onChange(of: viewModel.isLoading) { loading in
                isLoading = loading
            }
            .onReceive(viewModel.profileUpdateComplete) { _ in
                fetchUserFromDB()
            }
            .background(Color(YmlReader().appStyle.backgroundColor.color ?? UIColor.black))
            .alert(isPresented: $isPresenting) {
                Alert(
                    title: Text(Constants.CustomiseStrings.accountDeleted)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    message: Text(Constants.CustomiseStrings.deleteAccount),
                    dismissButton: .default(Text(Constants.CustomiseStrings.okay), action: {
                        OTFTheraforgeNetwork.shared.moveToOnboardingView()
                    })
                )
            }
            .alert(isPresented: $isPresentingDiagnosticAlert) {
                Alert(
                    title: Text(Constants.CustomiseStrings.diagnosticsNotSupported)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    message: Text(Constants.CustomiseStrings.diagnosticsSupportMessage),
                    dismissButton: .default(Text(Constants.CustomiseStrings.okay), action: {
                        isPresentingDiagnosticAlert = false
                    })
                )
            }
            .sheet(isPresented: $isShowingChangePassword) {
                if let email = user?.remoteID {
                    ChangePasswordDetailsView(viewModel: ChangePasswordViewModel(email: email))
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .deleteUserAccount, object: nil)
            }
            .navigationTitle(Constants.CustomiseStrings.profile)
        }
    }
    
    // MARK: - Helper Methods
    /// Creates a consistently styled section header
    func listHeader(_ string: LocalizedStringKey) -> some View {
        Text(string)
            .font(.otfheaderTitleFont)
            .fontWeight(Font.otfheaderTitleWeight)
            .foregroundColor(.otfHeaderColor)
            .textCase(nil)
    }

    /// Fetches user data from the database and downloads associated files
    func fetchUserFromDB() {
        CareKitStoreManager.shared.cloudantStore?.getThisPatient({ result in
            if case .success(let patient) = result {
                self.user = patient
                let attachmentID = self.user?.attachments?.profile?.attachmentID ??
                                 UserDefaults.standard.string(forKey: "LastKnownProfileAttachmentID")
                
                if let attachmentID = attachmentID {
                    viewModel.downloadFile(attachmentID: attachmentID, isProfile: true)
                }
                
                if let consentFormId = self.user?.attachments?.consentForm?.attachmentID {
                    viewModel.downloadFile(attachmentID: consentFormId, isProfile: false)
                }
            }
        })
    }
}

struct ProfileUIView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileUIView(user: .init(id: "1", givenName: "Branson", familyName: "Ashwin"))
    }
}
