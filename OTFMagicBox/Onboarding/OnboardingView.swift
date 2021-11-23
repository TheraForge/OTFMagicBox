//
//  OnboardingView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 11.05.21.
//

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
    
    @State private var showErrorAlert = false
    
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
            
            if includeSocialLogin {
                HStack {
                    Button(action: {
                        self.showingOnboardOptions.toggle()
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
                    .sheet(isPresented: $showingOnboard, onDismiss: {
                        self.showingOnboard = false
                    }) {
                        if self.selectedAuthMethod == .apple {
                            if OTFKeychain().getAppleAuthCredentials() == nil {
                                ActivitiesViewController(authMethod: .apple)
                            } else {
                                // Show alert that user should login
                                AlertViewController(title: "Can't sign up again",
                                                    message: "You have already signed up with Apple ID. Try logging in instead.",
                                                    dismissButtonTitle: "Okay",
                                                    buttonAction: {
                                                        // Perform action if needed
                                                    })
                            }
                        }
                        else {
                            ActivitiesViewController(authMethod: .email)
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        self.showingLoginOptions = true
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
                    .sheet(isPresented: $showingLogin, onDismiss: {
                        self.showingLogin = false
                    }) {
                        if self.selectedAuthMethod == .apple {
                            if OTFKeychain().getAppleAuthCredentials() != nil {
                                LoginExistingUserViewController(authMethod: self.selectedAuthMethod)
                            }
                            else {
                                // Show alert that user should sign up first
                                AlertViewController(title: "Missing Credentials",
                                                    message: "You cannot log in. Please sign up first.",
                                                    dismissButtonTitle: "Okay",
                                                    buttonAction: {
                                                        // Perform action if needed
                                                    })
                            }
                        }
                        else {
                            LoginExistingUserViewController(authMethod: self.selectedAuthMethod)
                        }
                    }
                }
            } else {
                HStack {
                    Button(action: {
                        self.showingOnboard.toggle()
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
                    .sheet(isPresented: $showingOnboard, onDismiss: {
                        self.onComplete?()
                    }, content: {
                        ActivitiesViewController(authMethod: .email)
                    })
                }
                
                HStack {
                    Button(action: {
                        self.showingLogin.toggle()
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
                    .sheet(isPresented: $showingLogin, onDismiss: {
                        self.onComplete?()
                    }, content: {
                        LoginExistingUserViewController(authMethod: .email)
                    })
                }
            }
            
            Spacer()
        }
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

