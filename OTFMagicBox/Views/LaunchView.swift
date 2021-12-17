//
//  LaunchView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 15.05.21.
//

import SwiftUI
import OTFCareKitStore
import OTFCloudClientAPI

struct LaunchView: View {
    
    @State var onboardingCompleted = UserDefaultsManager.onboardingDidComplete
    
    init() {
        didCompleteOnBoarding()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if onboardingCompleted, let _ = TheraForgeKeychainService.shared.loadUser() {
                MainView()
            } else {
                OnboardingView {
                    didCompleteOnBoarding()
                }
            }
        }.onAppear(perform: {
            didCompleteOnBoarding()
        }).onReceive(NotificationCenter.default.publisher(for: .onboardingDidComplete)) { notification in
            didCompleteOnBoarding()
        }
    }
    
    func didCompleteOnBoarding() {
        self.onboardingCompleted = UserDefaultsManager.onboardingDidComplete
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}

struct LoadingView: View {
    
    private let username: String
    
    init(username: String) {
        self.username = username
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
}
