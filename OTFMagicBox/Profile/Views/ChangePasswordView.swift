/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFUtilities

// This view creates the section in the Profile view, which navigates to the another page where we can reset the password.
struct ChangePasswordView: View {

    let email: String
    let resetPassword: String
    @State var showResetPassword = false

    var body: some View {
        HStack {
            Text(resetPassword)
                .foregroundColor(.otfTextColor)
                .font(Font.otfAppFont)
                .fontWeight(Font.otfFontWeight)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .font(.footnote.weight(.semibold))
        }.frame(height: Metrics.TITLE_VIEW_HEIGHT)
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded {
            self.showResetPassword.toggle()
        }).sheet(isPresented: $showResetPassword, content: {
            ChangePasswordDetailsView(viewModel: ChangePasswordViewModel(email: email))
        })
        .accessibilityAddTraits(.isButton)
        .accessibilityElement(children: .combine)
    }
}

// View where we can reset the password.
struct ChangePasswordDetailsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: ChangePasswordViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(Constants.CustomiseStrings.email)
                        Spacer()
                        Text(viewModel.email)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(Constants.CustomiseStrings.email): \(viewModel.email)")
                }
                
                Section(header: Text(Constants.CustomiseStrings.changePasscode)) {
                    SecureField(Constants.CustomiseStrings.oldPassword, text: $viewModel.oldPassword)
                        .accessibilityLabel(Constants.CustomiseStrings.oldPassword)
                    
                    SecureField(Constants.CustomiseStrings.newPassword, text: $viewModel.newPassword)
                        .accessibilityLabel(Constants.CustomiseStrings.newPassword)
                }
                
                Section {
                    Button(action: {
                        viewModel.changePassword()
                    }) {
                        Text(Constants.CustomiseStrings.resetPassword)
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityHint("Double tap to reset your password")
                }
            }
            .navigationTitle(Constants.CustomiseStrings.changePasscode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Constants.CustomiseStrings.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accessibilityLabel("Cancel password change")
                }
            }
            .alert(isPresented: $viewModel.showFailureAlert) {
                Alert(
                    title: Text(Constants.CustomiseStrings.passwordResetError)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text(Constants.CustomiseStrings.okay))
                )
            }
        }
        .onReceive(viewModel.viewDismissModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
