//
//  ProfileUIView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import SwiftUI
import OTFCloudClientAPI

struct ProfileUIView: View {
    
    let user: Response.User
    
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
