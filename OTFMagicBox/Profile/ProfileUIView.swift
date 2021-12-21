//
//  ProfileUIView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import SwiftUI
import OTFCareKitStore

struct ProfileUIView: View {
    
    let user: OCKPatient
    
    var body: some View {
        VStack {
            Text("Profile").font(.headerFontStyle)
            List {
                Section {
                    UpdateUserProfileView(user: user)
                }
                
                Section {
                    if YmlReader().isPasscodeEnabled {
                        ChangePasscodeView()
                    }
                    HelpView(site: YmlReader().teamWebsite)
                }
                
                Section {
                    ChangePasswordView()
                }
                
                Section {
                    ReportView(color: .blue, email: YmlReader().teamEmail)
                    SupportView(color: .blue, phone: YmlReader().teamPhone)
                }
                
                if let documentsPath = UserDefaults.standard.object(forKey: Constants.UserDefaults.ConsentDocumentURL) as? String {
                    let url = URL(fileURLWithPath: documentsPath, isDirectory: false)
                    Section {
                        ConsentDocumentView(documentURL: url)
                    }
                }
                
                Section {
                    WithdrawView()
                }
                
                Section {
                    Text(YmlReader().teamCopyright)
                }
                
                Section {
                    LogoutView()
                }
                
            }.listStyle(GroupedListStyle())
        }
    }
}
