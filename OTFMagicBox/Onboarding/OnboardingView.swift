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
import OTFUtilities

/// The onboarding view.
struct OnboardingView: View {
    
    /// The list of the onboarding view elements.
    let color: Color
    var onboardingElements: [Onboarding] = []
    var onComplete: (() -> Void)? = nil
    
    @State var showingOnboard = false
    @State var showingLogin = false
    
    @State private var selectedAuthMethod = AuthMethod.email
    
    /// Creates the on boarding view.
    init(onComplete: (() -> Void)? = nil) {
        
        // TODO: Add the actual default image, if the user doesnt enter any image.
        let config = ModuleAppYmlReader()
        let onboardingdata: [Onboarding] = {
            config.onboardingData ?? [Onboarding(image: Constants.CustomiseStrings.splashImage, icon: Constants.CustomiseStrings.splashIcon, title: Constants.CustomiseStrings.welcome, color: "black", description: Constants.CustomiseStrings.defaultDescription)]
        }()
        
        onboardingElements = onboardingdata
        
        self.color = Color(config.primaryColor)
        
        self.onComplete = onComplete
    }
    
    /// Onboarding  view.
    var body: some View {
        ZStack {
            OnboardingItemView(self.onboardingElements.map {
                OnboardingDetailsView(icon: $0.icon, image: $0.image,
                                      title: $0.title ?? Constants.YamlDefaults.AppTitle,
                                      description: $0.description,
                                      color: Color($0.color.color ?? .black))
            })
            
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            self.showingOnboard = true
                        }, label: {
                            Text(Constants.CustomiseStrings.signUp)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Metrics.PADDING_VERTICAL_ROW)
                                .foregroundColor(.white)
                                .background(self.color)
                                .cornerRadius(Metrics.RADIUS_CORNER_BUTTON)
                                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        })
                        .padding(.leading, Metrics.PADDING_HORIZONTAL_BUTTON)
                        .padding(.trailing, Metrics.PADDING_HORIZONTAL_BUTTON / 2)
                        
                        Button(action: {
                            self.showingLogin = true
                        }, label: {
                            Text(Constants.CustomiseStrings.signIn)
                                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Metrics.PADDING_VERTICAL_ROW)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(Metrics.RADIUS_CORNER_BUTTON)
                        })
                        .padding(.trailing, Metrics.PADDING_HORIZONTAL_BUTTON)
                        .padding(.leading, Metrics.PADDING_HORIZONTAL_BUTTON / 2)
                    }
                    
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom > 0 ? 0 : Metrics.BOTTOM_SPACER)
                }
            }
        }
        .sheet(isPresented: $showingLogin, onDismiss: {
            OTFLog("Login sheet dismissed")
            onComplete?()
        }, content: {
            LoginExistingUserViewController()
                .ignoresSafeArea(.container)
        })
        .sheet(isPresented: $showingOnboard, onDismiss: {
            OTFLog("Onboard sheet dismissed")
            onComplete?()
        }, content: {
            OnboardingViewController()
                .ignoresSafeArea(.container)
        })
    }
}

/// The onboarding detailed view.
struct OnboardingDetailsView: View {
    
    /// Image of the onboarding item.
    let icon: String
    
    /// Image of the onboarding item.
    let image: String
    
    /// Title of the onboarding item.
    let title: String
    
    /// Description of the onboarding item.
    let description: String
    
    /// Color of the onboarding item.
    let color: Color
    
    /// Onboarding detailed view.
    var body: some View {
        ZStack {
            Image(image)
                .resizable()
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            VStack {
                Image(systemName: icon)
                    .imageScale(.large)
                    .foregroundColor(color)
                    .font(.system(size: 60.0).bold())
                    .padding(.top, Metrics.PADDING_VERTICAL_BUTTON * 2)
                    .padding(.bottom, Metrics.PADDING_VERTICAL_BUTTON)
                    .accessibilityHidden(true)
                
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(YmlReader().appTheme?.appTitleSize.appFont ?? Constants.YamlDefaults.AppTitleSize.appFont)
                    .foregroundColor(color)
                    .shadow(color: .black, radius: 15)
                    .padding([.horizontal, .bottom],
                             Metrics.PADDING_VERTICAL_BUTTON)
                
                Text(description)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(color)
                    .shadow(radius: 5)
                    .padding(.horizontal,
                             Metrics.PADDING_HORIZONTAL_BUTTON)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

