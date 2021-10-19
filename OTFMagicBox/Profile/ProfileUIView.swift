//
//  ProfileUIView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import SwiftUI

struct ProfileUIView: View {
    
    var body: some View {
        VStack {
            Text("Profile").font(.system(size: 25, weight:.bold))
            List {
                Section {
                    Text("Patient name")
                }.listRowBackground(Color.white)
                
                Section {
                    if YmlReader().isPasscodeEnabled {
                        ChangePasscodeView()
                    }
                    HelpView(site: YmlReader().teamWebsite)
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
            }.listStyle(GroupedListStyle())
        }
    }
}
