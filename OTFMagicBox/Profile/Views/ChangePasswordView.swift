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

import Foundation
import SwiftUI

// This view creates the section in the Profile view, which navigates to the another page where we can reset the password.
struct ChangePasswordView: View {
    
    let email: String
    let resetPassword: String
    let textColor: UIColor
    let backgroudColor: UIColor
    let buttonColor: UIColor
    let borderColor: UIColor
    @State var showResetPassword = false
    
//    init(resetPassword: String) {
//        self.resetPassword = resetPassword
//    }
    
    var body: some View {
        HStack {
            Text(resetPassword)
                .foregroundColor(Color(textColor))
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
            Spacer()
            Text("›")
        }.frame(height: 60)
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded {
            self.showResetPassword.toggle()
        }).sheet(isPresented: $showResetPassword, onDismiss: {
            
        }, content: {
            ChangePasswordDeatilsView(email: email, textColor: textColor, backgroudColor: backgroudColor, buttonColor: buttonColor, borderColor: borderColor)
        })
    }
}

// View where we can reset the password.
struct ChangePasswordDeatilsView: View {
    
    let textColor: UIColor
    let backgroudColor: UIColor
    let buttonColor: UIColor
    let borderColor: UIColor
    @State var email: String
    @State var oldPassword: String = ""
    @State var newPassword: String = ""
    let color = Color(YmlReader().primaryColor)
    @State var showFailureAlert = false
    @State var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(email: String, textColor: UIColor, backgroudColor: UIColor, buttonColor: UIColor, borderColor: UIColor) {
        self.backgroudColor = backgroudColor
        self.buttonColor = buttonColor
        self.borderColor = borderColor
        self.textColor = textColor
        _email = State(initialValue: email)
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Image.theraforgeLogo.logoStyle()
            
            Spacer()
            
            TextField("Email", text: $email)
                .style(.emailField)
                .foregroundColor(Color(textColor))
                .disabled(true)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))

                
            SecureField(ModuleAppYmlReader().profileData?.oldPassword ?? "Old Password", text: $oldPassword)
                .style(.secureField)
                .foregroundColor(Color(textColor))
            
            SecureField(ModuleAppYmlReader().profileData?.newPassword ?? "New Password", text: $newPassword)
                .style(.secureField)
                .foregroundColor(Color(textColor))
            
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
                Text(ModuleAppYmlReader().profileData?.resetPassword ?? "Reset Password")
                    .padding(Metrics.PADDING_BUTTON_LABEL)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(buttonColor))
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .overlay(
                        Capsule().stroke(Color(buttonColor), lineWidth: 2)
                    )
            })
            .padding()
            .alert(isPresented: $showFailureAlert, content: ({
                Alert(title: Text("Password Reset Error!").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                    .fontWeight(YmlReader().appTheme?.textWeight.fontWeight), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }))
            
            Spacer()
        }
        .background(Color(backgroudColor))
    }
}
