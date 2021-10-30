//
//  ProfileUIView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import SwiftUI

struct ProfileUIView: View {
    
    let email = UserDefaults.standard.object(forKey: Constants.patientEmail)
    
    var body: some View {
        VStack {
            Text("Profile").font(.headerFontStyle)
            List {
                Section {
                    UpdateUserProfileView()
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
