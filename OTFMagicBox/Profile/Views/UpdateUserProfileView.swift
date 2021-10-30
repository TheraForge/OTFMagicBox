//
//  UpdateUserProfileView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 25/10/21.
//

import SwiftUI

struct UpdateUserProfileView: View {
    
    @State var showUserProfile = false
    let email = UserDefaults.standard.object(forKey: Constants.UserDefaults.patientEmail)
    
    var body: some View {
        VStack {
            Image.avatar
                .iconStyle()
                .frame(width: 40, height: 40, alignment: .center)
             
            HStack {
                Text(email as? String ?? Constants.UserDefaults.patientEmail)
                Spacer()
                Text("›")
            }
        }.frame(height: 80).contentShape(Rectangle())
        .gesture(TapGesture().onEnded({
            self.showUserProfile.toggle()
        })).sheet(isPresented: $showUserProfile, onDismiss: {
            
        }, content: {
            UpdateUserProfileDetailView()
        })
    }
}

struct UpdateUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateUserProfileView()
    }
}
