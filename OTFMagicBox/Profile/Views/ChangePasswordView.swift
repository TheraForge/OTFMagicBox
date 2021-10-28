//
//  ResetPasswordView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 16/10/21.
//

import Foundation
import SwiftUI

// This view creates the section in the Profile view, which navigates to the another page where we can reset the password.
struct ChangePasswordView: View {
    
    @State var showResetPassword = false
    
    var body: some View {
        HStack {
            Text("Reset Passsword")
            Spacer()
            Text("›")
        }.frame(height: 60)
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded {
            self.showResetPassword.toggle()
        }).sheet(isPresented: $showResetPassword, onDismiss: {
            
        }, content: {
            ChangePasswordDeatilsView()
        })
    }
}

// View where we can reset the password.
struct ChangePasswordDeatilsView: View {
    
    @State var email: String = UserDefaults.standard.object(forKey: Constants.patientEmail) as! String
    @State var oldPassword: String = ""
    @State var newPassword: String = ""
    let color = Color(YmlReader().primaryColor)
    @State var showFailureAlert = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Image.theraforgeLogo.logoStyle()
            
            Spacer()
            
            TextField("Email", text: $email)
                .style(.emailField)
                .disabled(true)
                
            SecureField("Old Password", text: $oldPassword)
                .style(.secureField)
            
            SecureField("New Password", text: $newPassword)
                .style(.secureField)
            
            Spacer()
            
            Button(action: {
                OTFTheraforgeNetwork.shared.changePassword(email: email, oldPassword: oldPassword, newPassword: newPassword, completionHandler: ({ results in
                    
                    switch results {
                    case .failure(let error):
                        showFailureAlert = true
                        print(error.localizedDescription)
                        
                    case .success:
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    
                }))
            }, label: {
                Text("Reset Password")
                    .padding(Metrics.PADDING_BUTTON_LABEL)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(self.color)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.RADIUS_CORNER_BUTTON)
                            .stroke(self.color, lineWidth: 2)
                    )
            })
            .alert(isPresented: $showFailureAlert, content: ({
                Alert(title: Text("Password Reset Error!"), message: Text(""), dismissButton: .default(Text("OK")))
            }))
            
            Spacer()
        }
        
    }
}
