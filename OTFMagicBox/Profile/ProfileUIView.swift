/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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

struct ProfileUIView: View {

    @State private(set) var user: OCKPatient?
    @State var isLoading = true
    @State private var isPresenting = false
    @State var document = Data()
    let manager = UploadDocumentManager()
    @StateObject private var viewModel = UpdateUserViewModel()
    @State private var isPresentingEditUser: Bool = false
    var hint: String?

    var userName: String {
        guard let givenName = user?.name.givenName,
              let familyName = user?.name.familyName else {
            return ""
        }
        return "\(givenName) \(familyName)"
    }

    var body: some View {

        NavigationView {
            VStack {
                Text(ModuleAppYmlReader().profileData?.title ?? Constants.CustomiseStrings.profile)
                    .foregroundColor(.otfTextColor)
                    .font(Font.otfscreenTitleFont)
                    .fontWeight(Font.otfFontWeight)

                List {
                    Section {
                        if let user = user {
                            UpdateUserProfileView(user: user)
                        } else {
                            LoadingView(username: "")
                        }
                    }
                    .listRowBackground(Color.otfCellBackground)

                    Section {
                        if ModuleAppYmlReader().isPasscodeEnabled {
                            ChangePasscodeView()
                        }
                        HelpView(site: YmlReader().teamWebsite, title: ModuleAppYmlReader().profileData?.help ?? Constants.CustomiseStrings.help)
                    }
                    .listRowBackground(Color.otfCellBackground)

                    if let email = user?.remoteID {
                        Section {
                            ChangePasswordView(email: email, resetPassword: ModuleAppYmlReader().profileData?.resetPasswordText ?? Constants.CustomiseStrings.resetPassword)
                        }
                        .listRowBackground(Color.otfCellBackground)
                    }

                    Section(header: Text(ModuleAppYmlReader().profileData?.reportProblemHeader ?? Constants.CustomiseStrings.reportProblem)
                                .font(.otfheaderTitleFont)
                                .fontWeight(Font.otfheaderTitleWeight)
                                .foregroundColor(.otfHeaderColor)) {
                        ReportView(email: YmlReader().teamEmail, title: ModuleAppYmlReader().profileData?.reportProblemText ?? Constants.CustomiseStrings.reportProblem)
                        SupportView(phone: YmlReader().teamPhone, title: ModuleAppYmlReader().profileData?.supportText ?? Constants.CustomiseStrings.support)
                    }
                    .listRowBackground(Color.otfCellBackground)

                    if let user = user {
                        if let attachmentID = user.attachments?.consentForm?.attachmentID, let hashFileKey = user.attachments?.consentForm?.hashFileKey {
                            let doc = document.retriveFile(fileName: attachmentID)
                            if doc != nil {
                                Section {
                                    ZStack {
                                        NavigationLink(destination: PDFViewer(
                                            pdfData: 
                                            KeychainCloudManager.isKeyStored(key: KeychainKeys.defaultStorageKey) ? manager.decryptedFile(file: doc!, hashFileKey: hashFileKey) : doc!), label: {
                                            EmptyView()
                                        }).opacity(0.0)
                                        ConsentDocumentView(title: ModuleAppYmlReader().profileData?.consentText ?? Constants.CustomiseStrings.consetDocument)
                                    }
                                }.listRowBackground(Color.otfCellBackground)
                            }
                        }
                    }

                    Section {
                        WithdrawView(title: ModuleAppYmlReader().profileData?.withdrawStudyText ?? Constants.CustomiseStrings.withdrawFromStudy)
                    }
                    .listRowBackground(Color.otfCellBackground)
                    Section {
                        Text(YmlReader().teamCopyright)
                            .foregroundColor(.otfTextColor)
                            .font(Font.otfAppFont)
                            .fontWeight(Font.otfFontWeight)
                    }
                    .listRowBackground(Color.otfCellBackground)

                    Section {
                        LogoutView()
                    }.listRowBackground(Color.otfCellBackground)

                    Section {
                        if let user = user {
                            DeleteAccountView(user: user)
                        }
                    }
                    .listRowBackground(Color.otfCellBackground)
                }
                .listStyle(.insetGrouped)
                .onLoad {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        fetchUserFromDB()
                    }
                    UITableView.appearance().backgroundColor = YmlReader().appStyle.backgroundColor.color
                    UITableViewCell.appearance().backgroundColor = YmlReader().appStyle.backgroundColor.color
                    UITableView.appearance().separatorColor = YmlReader().appStyle.separatorColor.color
                }
                .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { _ in
                    fetchUserFromDB()
                }
                .onReceive(NotificationCenter.default.publisher(for: .deleteUserAccount)) { _ in
                    isPresenting = true
                }
            }
            .background(Color(YmlReader().appStyle.backgroundColor.color ?? UIColor.black))
            .alert(isPresented: $isPresenting) {
                Alert(
                    title: Text(Constants.CustomiseStrings.accountDeleted)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    message: Text(Constants.deleteAccount),
                    dismissButton: .default(Text(Constants.CustomiseStrings.okay), action: {
                        OTFTheraforgeNetwork.shared.moveToOnboardingView()
                    })
                )
            }
            .onAppear {
                
//                let careKitManager =  CareKitManager.shared
//                careKitManager.cloudantStore?.populateSampleData()
//                
//                careKitManager.cloudantStore?.fetchTasks(completion: { result in
//                    switch result {
//                    case .success(let tasks):
//                        print(tasks)
//                        
//                    case .failure(_):
//                        print("Error ==> ")
//                    }
//                })
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .deleteUserAccount, object: nil)
            }
            .background(Color.otfCellBackground)
        }
    }

    func fetchUserFromDB() {
        CareKitStoreManager.shared.cloudantStore?.getThisPatient({ result in
            if case .success(let patient) = result {
                self.user = patient
                if let attachmentID = self.user?.attachments?.profile?.attachmentID {
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
        ProfileUIView(user: nil)
    }
}
