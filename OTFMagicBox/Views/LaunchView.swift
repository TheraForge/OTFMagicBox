//
//  LaunchView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 15.05.21.
//

import SwiftUI
import OTFCloudClientAPI

struct LaunchView: View {
    
    @State var onboardingCompleted = UserDefaultsManager.onboardingDidComplete
    
    var body: some View {
        
        VStack(spacing: 10) {
            if onboardingCompleted, let user = TheraForgeKeychainService.shared.loadUser() {
                MainView(user: user)
            } else {
                OnboardingView {
                    didCompleteOnBoarding()
                }
            }
        }.onAppear(perform: {
            didCompleteOnBoarding()
        }).onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(Constants.onboardingDidComplete))) { notification in
            if let newValue = notification.object as? Bool {
                self.onboardingCompleted = newValue
            } else {
                didCompleteOnBoarding()
            }
        }
        
    }
    
    func didCompleteOnBoarding() {
        if let completed = UserDefaults.standard.object(forKey: Constants.onboardingDidComplete) as? Bool {
            self.onboardingCompleted = completed
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
