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
    @State private var patient: OCKPatient?
    
    init() {
        didCompleteOnBoarding()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if onboardingCompleted, let user = TheraForgeKeychainService.shared.loadUser() {
                if let patient = patient {
                    MainView(user: patient)
                } else {
                    LoadingView(username: "\(user.firstName ?? "") \(user.lastName ?? "")")
                        .onLoad {
                            CareKitManager.shared.cloudantStore?.getThisPatient({ result in
                                switch result {
                                case .success(let patient):
                                    self.patient = patient
                                    
                                case .failure:
                                    UserDefaultsManager.setOnboardingCompleted(false)
                                    didCompleteOnBoarding()
                                }
                            })
                        }
                }
            } else {
                OnboardingView {
                    didCompleteOnBoarding()
                }
            }
        }.onAppear(perform: {
            didCompleteOnBoarding()
        }).onReceive(NotificationCenter.default.publisher(for: .onboardingDidComplete)) { notification in
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
