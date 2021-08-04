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
                   // PatientIDView()
                    Text("Patient name")
                }.listRowBackground(Color.white)
                
                Section {
                    SendRecordsView()
                    ChangePasscodeView()
                    HelpView(site: "https://www.hippocratestech.com/")
                }
                
                Section {
                    ReportView(color: .blue, email: "test@email.com")
                    SupportView(color: .blue, phone: "0730000")
                }
                
               /* Section {
                    WithdrawView(color: self.color)
                }*/
                
                Section {
                    Text("Copyright")
                }
            }.listStyle(GroupedListStyle())
        }
    }
}
