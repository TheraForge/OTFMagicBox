//
//  UserDefaultsManager.swift
//  OTFMagicBox
//
//  Created by Admin on 29/10/2021.
//

import Foundation

class UserDefaultsManager {
    static var onboardingDidComplete: Bool {
        return UserDefaults.standard.bool(forKey: Constants.onboardingDidComplete)
    }
    
    static func setOnboardingCompleted(_ completed: Bool) {
        UserDefaults.standard.setValue(completed, forKey: Constants.onboardingDidComplete)
    }
}
