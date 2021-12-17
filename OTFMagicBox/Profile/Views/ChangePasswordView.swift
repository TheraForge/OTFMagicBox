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
    
    let email: String
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
            ChangePasswordDeatilsView(email: email)
        })
    }
}

// View where we can reset the password.
struct ChangePasswordDeatilsView: View {
    
    @State var email: String
    @State var oldPassword: String = ""
    @State var newPassword: String = ""
    let color = Color(YmlReader().primaryColor)
    @State var showFailureAlert = false
    @State var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(email: String) {
        _email = State(initialValue: email)
    }
    
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
                        errorMessage = error.localizedDescription
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
                        Capsule().stroke(self.color, lineWidth: 2)
                    )
            })
            .padding()
            .alert(isPresented: $showFailureAlert, content: ({
                Alert(title: Text("Password Reset Error!"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }))
            
            Spacer()
        }
        
    }
}
