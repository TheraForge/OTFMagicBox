//
//  LaunchView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 15.05.21.
//

import SwiftUI

struct LaunchView: View {
    
    @State var didCompleteOnboarding = false
    
    var body: some View {
        
        VStack(spacing: 10) {
            if didCompleteOnboarding {
                MainView()
            } else {
                OnboardingView {
                    if let completed = UserDefaults.standard.object(forKey: Constants.onboardingDidComplete) as? Bool {
                       self.didCompleteOnboarding = completed
                    }
                }
            }
        }.onAppear(perform: ({
            if let completed = UserDefaults.standard.object(forKey: Constants.onboardingDidComplete) as? Bool {
               self.didCompleteOnboarding = completed
            }
        })).onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(Constants.onboardingDidComplete))) { notification in
            if let newValue = notification.object as? Bool {
                self.didCompleteOnboarding = newValue
            } else if let completed = UserDefaults.standard.object(forKey: Constants.onboardingDidComplete) as? Bool {
               self.didCompleteOnboarding = completed
            }
        }
        
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
