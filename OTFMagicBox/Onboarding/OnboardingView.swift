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
    
    /// Title of the onboarding item.
    let logo: String
    
    /// Description of the onboarding item.
    let description: String
}

/// The onboarding view.
struct OnboardingView: View {
    
    /// The list of the onboarding view elements.
    var onboardingElements: [OnboardingElement] = []
    
    //FIX ME
    @State var showingOnboard = false
    var onComplete: (() -> Void)? = nil
    @State var showingLogin = false
    let color: Color
    
    /// Creates the on boarding view.
    init(onComplete: (() -> Void)? = nil) {
        
        let onboardingdata = (YmlReader().onboardingData() ?? [Onboarding(logo: "logo", description: "Default: This is the description.")]) as Array
 
        for data in onboardingdata {
            self.onboardingElements.append(OnboardingElement(logo: data.logo, description: data.description))
        }
        
        self.color = Color(YmlReader().primaryColor())
    }

    /// Onboarding  view.
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image("TheraforgeLogo")
                .resizable()
                .scaledToFit()
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN*4)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN*4)
            
            Spacer(minLength: 2)
            
            Text(YmlReader().studyTitle())
                .foregroundColor(self.color)
                .multilineTextAlignment(.center)
                .font(.system(size: 35, weight: .bold, design: .default))
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
            
            Text(YmlReader().teamName())
                .foregroundColor(self.color)
                .multilineTextAlignment(.center)
                .font(.system(size: 35, weight: .bold, design: .default))
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
            
            OnboardingItemView(self.onboardingElements.map { OnboardingDetailsView(logo: $0.logo, description: $0.description, color: UIColor.primaryColor) })

            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    self.showingOnboard.toggle()
                }, label: {
                     Text("Join Study")
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(self.color)
                        .cornerRadius(Metrics.RADIUS_CORNER_BUTTON)
                        .font(.system(size: 20, weight: .bold, design: .default))
                })
                .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN)
                .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN)
                .sheet(isPresented: $showingOnboard, onDismiss: {
                    self.onComplete?()
                }, content: {
                    ActivitiesViewController()
                })
        
                Spacer()
            }
            
            HStack {
                Spacer()
                Button(action: {
                    self.showingLogin.toggle()
                }, label: {
                     Text("I'm a Returning User")
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(self.color)
                        .font(.system(size: 20, weight: .bold, design: .default))
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
                    LoginExistingUserViewController()
                })
        
                Spacer()
            }
            
            Spacer()
        }
    }
}

/// The onboarding detailed view.
struct OnboardingDetailsView: View {
    
    /// Title of the onboarding item.
    let logo: String
    
    /// Description of the onboarding item.
    let description: String
    
    /// Color of the onboarding item.
    let color: Color
    
    /// Onboarding detailed view.
    var body: some View {
        VStack(spacing: 10) {

            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 100, height: 100, alignment: .center)
                .padding(6)
                .overlay(
                    Text(logo)
                        .foregroundColor(.white)
                        .font(.system(size: 42, weight: .light, design: .default))
                )
            
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

