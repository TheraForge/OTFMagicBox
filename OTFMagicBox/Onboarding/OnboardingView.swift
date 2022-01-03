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

import SwiftUI
import UIKit

/// The onboarding view elements.
struct OnboardingElement {
    
    /// Title or image of the onboarding item.
    let image: String
    
    /// Description of the onboarding item.
    let description: String
}

/// The onboarding view.
struct OnboardingView: View {
    
    /// The list of the onboarding view elements.
    let color: Color
    let includeSocialLogin = YmlReader().showSocialLogin
    
    var onboardingElements: [OnboardingElement] = []
    var onComplete: (() -> Void)? = nil
    
    @State var showingOnboardOptions = false
    @State var showingOnboard = false
    
    @State var showingLoginOptions = false
    @State var showingLogin = false
    
    @State private var selectedAuthMethod = AuthMethod.email
    
    /// Creates the on boarding view.
    init(onComplete: (() -> Void)? = nil) {
        
        // TODO: Add the actual default image, if the user doesnt enter any image.
        let onboardingdata: [Onboarding] = {
            YmlReader().onboardingData ?? [Onboarding(image: "image",
                                                      description: "Default: This is the description.")]
        }()
        
        for data in onboardingdata {
            self.onboardingElements.append(OnboardingElement(image: data.image,
                                                             description: data.description))
        }
        
        self.color = Color(YmlReader().primaryColor)
        self.onComplete = onComplete
    }
    
    /// Onboarding  view.
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image.theraforgeLogo.logoStyle()
            
            Spacer(minLength: 2)
            
            VStack() {
                Text(YmlReader().studyTitle)
                Text(YmlReader().teamName)
            }
            .foregroundColor(self.color)
            .multilineTextAlignment(.center)
            .font(.titleFontStyle)
            .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
            .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
            
            OnboardingItemView(self.onboardingElements.map {
                OnboardingDetailsView(image: $0.image, description: $0.description, color: self.color)
            })
            
            Spacer()
            
            HStack {
                Button(action: {
                    if self.includeSocialLogin {
                        self.showingOnboardOptions = true
                    } else {
                        self.showingOnboard = true
                    }
                }, label: {
                    Text("Create New Account")
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(self.color)
                        .cornerRadius(Metrics.RADIUS_CORNER_BUTTON)
                        .font(.subHeaderFontStyle)
                })
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
                .actionSheet(isPresented: $showingOnboardOptions) {
                    ActionSheet(title: Text("Select sign up method"),
                                message: nil,
                                buttons: AuthMethod.allCases.map { method in
                                    .default(Text(method.signupTitle)) {
                                        self.selectedAuthMethod = method
                                        self.showingOnboard = true
                                        self.showingOnboardOptions = false
                                    }
                                } + [.cancel(Text("Cancel"))]
                    )
                }
            }
            
            HStack {
                Button(action: {
                    if self.includeSocialLogin {
                        self.showingLoginOptions = true
                    } else {
                        self.showingLogin = true
                    }
                }, label: {
                    Text("I'm a Returning User")
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(self.color)
                        .font(.subHeaderFontStyle)
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.RADIUS_CORNER_BUTTON)
                                .stroke(self.color, lineWidth: 2)
                        )
                })
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
                .actionSheet(isPresented: $showingLoginOptions) {
                    ActionSheet(title: Text("Select sign in method"),
                                message: nil,
                                buttons: AuthMethod.allCases.map { method in
                                    .default(Text(method.signinTitle)) {
                                        self.selectedAuthMethod = method
                                        self.showingLogin = true
                                        self.showingLoginOptions = false
                                    }
                                } + [.cancel(Text("Cancel"))]
                    )
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingLogin, onDismiss: {
            debugPrint("Login sheet dismissed")
            onComplete?()
        }, content: {
            LoginExistingUserViewController(authMethod: self.selectedAuthMethod)
        })
        .sheet(isPresented: $showingOnboard, onDismiss: {
            debugPrint("Onboard sheet dismissed")
            onComplete?()
        }, content: {
            ActivitiesViewController(authMethod: self.selectedAuthMethod)
        })
    }
}

/// The onboarding detailed view.
struct OnboardingDetailsView: View {
    
    /// Title of the onboarding item.
    let image: String
    
    /// Description of the onboarding item.
    let description: String
    
    /// Color of the onboarding item.
    let color: Color
    
    /// Onboarding detailed view.
    var body: some View {
        VStack(spacing: 10) {
            
            Spacer()
            
            if image.containsEmojis {
                Text(image)
                    .foregroundColor(.white)
                    .font(.system(size: 42, weight: .light, design: .default))
            } else {
                UIImage.loadImage(named: image)
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.leading, 40)
                .padding(.trailing, 40)
            
            Spacer()
        }
    }
    
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

