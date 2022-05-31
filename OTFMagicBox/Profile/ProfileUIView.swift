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

struct ProfileUIView: View {
    
    @State private(set) var user: OCKPatient?
    @State var isLoading = true
    var body: some View {
        VStack {
            Text(ModuleAppYmlReader().profileData?.title ?? "Profile")
                .foregroundColor(Color(YmlReader().appTheme?.textColor.color ?? UIColor.black))
                .font(YmlReader().appTheme?.screenTitleFont.appFont ?? Font.system(size: 17.0))
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
            
            List {
                
                HStack(alignment: .bottom, spacing: 10){
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                Section {
                    if let user = user {
                        UpdateUserProfileView(user: user, backgroudColor: YmlReader().appTheme?.cellbackgroundColor.color ?? .black, textColor: YmlReader().appTheme?.textColor.color ?? .black, cellBackgroundColor: YmlReader().appTheme?.cellbackgroundColor.color ?? .black, headerColor: YmlReader().appTheme?.headerColor.color ?? .black, buttonColor: YmlReader().appTheme?.buttonTextColor.color ?? .black, borderColor: YmlReader().appTheme?.borderColor.color ?? .black, sepratorColor: YmlReader().appTheme?.separatorColor.color ?? .black)
                    } else {
                        LoadingView(username: "")
                    }
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                
                Section {
                    if ModuleAppYmlReader().isPasscodeEnabled {
                        ChangePasscodeView()
                    }
                    HelpView(site: YmlReader().teamWebsite, title: ModuleAppYmlReader().profileData?.help ?? "Help", textColor: YmlReader().appTheme?.textColor.color ?? .black)
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                
                if let email = user?.remoteID {
                    Section {
                        ChangePasswordView(email: email, resetPassword: ModuleAppYmlReader().profileData?.resetPasswordText ?? "Reset Password", textColor: YmlReader().appTheme?.textColor.color ?? UIColor.black, backgroudColor: YmlReader().appTheme?.backgroundColor.color ?? UIColor.black, buttonColor: YmlReader().appTheme?.buttonTextColor.color ?? UIColor.black, borderColor: YmlReader().appTheme?.borderColor.color ?? UIColor.black)
                    }
                    .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                }
                
                Section(header: Text(ModuleAppYmlReader().profileData?.reportProblemHeader ?? "Report a Problem")
                    .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
                    .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
                    .foregroundColor(Color(YmlReader().appTheme?.headerColor.color ?? UIColor.black))) {
                    ReportView(color: Color(YmlReader().appTheme?.textColor.color ?? UIColor.black), email: YmlReader().teamEmail, title: ModuleAppYmlReader().profileData?.reportProblemText ?? "Report a Problem")
                    SupportView(color: Color(YmlReader().appTheme?.textColor.color ?? UIColor.black), phone: YmlReader().teamPhone, title: ModuleAppYmlReader().profileData?.supportText ?? "Support")
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                
                if let documentsPath = UserDefaults.standard.object(forKey: Constants.UserDefaults.ConsentDocumentURL) as? String {
                    let url = URL(fileURLWithPath: documentsPath, isDirectory: false)
                    Section {
                        ConsentDocumentView(documentURL: url, title: ModuleAppYmlReader().profileData?.consentText ?? "Consent Document", color: YmlReader().appTheme?.textColor.color ?? .black)
                    }
                    .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                }
                
                Section {
                    WithdrawView(title: ModuleAppYmlReader().profileData?.WithdrawStudyText ?? "Withdraw from Study", textColor: YmlReader().appTheme?.textColor.color ?? UIColor.black)
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                Section {
                    Text(YmlReader().teamCopyright)
                        .foregroundColor(Color(YmlReader().appTheme?.textColor.color ?? UIColor.black))
                        .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                Section {
                    LogoutView(textColor: YmlReader().appTheme?.buttonTextColor.color ?? UIColor.black)
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
                
                Section {
                    if let user = user{
                        DeleteAccountView(user: user, textColor: YmlReader().appTheme?.buttonTextColor.color ?? UIColor.black, deleteUserHandler: { value in
                            isLoading = false
                        })
                    }
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
            }
            .listStyle(GroupedListStyle())
            .onLoad {
                fetchUserFromDB()
                UITableView.appearance().backgroundColor = YmlReader().appTheme?.backgroundColor.color
                UITableViewCell.appearance().backgroundColor = YmlReader().appTheme?.backgroundColor.color
                UITableView.appearance().separatorColor = YmlReader().appTheme?.separatorColor.color
            }
            .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { notification in
                fetchUserFromDB()
            }
        }
        .background(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? UIColor.black))
    }
    
    func fetchUserFromDB() {
        CareKitManager.shared.cloudantStore?.getThisPatient({ result in
            if case .success(let patient) = result {
                self.user = patient
            }
        })
    }
}

struct ProfileUIView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileUIView(user: nil)
    }
}
