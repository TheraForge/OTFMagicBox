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
    let title: String
    
    /// Description of the onboarding item.
    let description: String
}

/// The onboarding view.
struct OnboardingView: View {
    
    /// The list of the onboarding view elements.
    var onboardingElements: [OnboardingElement] = []
    
    @State var showingOnboard = false
    var onComplete: (() -> Void)? = nil
    
    /// Creates the on boarding view.
    init(onComplete: (() -> Void)? = nil) {
        
        let onboardingData = [["Title":"Title1", "Description":"Lorem Ipsum is simply dummy text."], ["Title":"Title2", "Description":"Lorem Ipsum is simply dummy text."]]
        self.onComplete = onComplete
        for data in onboardingData {
            self.onboardingElements.append(OnboardingElement(title: data["Title"]!, description: data["Description"]!))
        }
    }

    /// Onboarding  view.
    var body: some View {
       
        VStack(spacing: 10) {
            
            Spacer()
            
           Text("HIPPOCRATES TECHNOLOGIES")
                .foregroundColor(UIColor.primaryColor)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .bold, design: .default))
            
            OnboardingItemView(self.onboardingElements.map { OnboardingDetailsView(title: $0.title, description: $0.description, color: UIColor.primaryColor) })

            Spacer()
            
            HStack {
                
                Spacer()
                
                Button(action: {
                    self.showingOnboard.toggle()
                }, label: {
                     Text("Login")
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(UIColor.primaryColor)
                        .cornerRadius(15)
                        .font(.system(size: 20, weight: .bold, design: .default))
                })
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .sheet(isPresented: $showingOnboard, onDismiss: {
                    self.onComplete?()
                }, content: {
                    ActivitiesViewController()
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
    let title: String
    
    /// Description of the onboarding item.
    let description: String
    
    /// Color of the onboarding item.
    let color: Color
    
    /// Onboarding detailed view.
    var body: some View {
        VStack(spacing: 10) {

            Text(title).font(.title)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.leading, 40)
                .padding(.trailing, 40)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

