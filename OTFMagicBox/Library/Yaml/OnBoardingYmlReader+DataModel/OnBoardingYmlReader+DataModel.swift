//
//  OnBoardingYmlReader+DataModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 26/04/2022.
//

import Foundation
import UIKit
import SwiftUI
import Yams

public class OnBoardingYmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.onboardingFileName
    
    var onBoardingDataModel : OnBoardingScreen?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: OnBoardingScreen].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    onBoardingDataModel = data["DataModel"]
                }
            }
        }
    }
    
    
    var defaultLanguage: String{
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        return langStr
    }
    
    var onboardingData: [Onboarding]? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.onboarding
        default:
            return onBoardingDataModel?.en.onboarding
        }
    }
    
    var primaryColor: UIColor {
        switch defaultLanguage {
        case "fr":
            let valueSet = (onBoardingDataModel?.fr.onboarding ?? [])
            for item in valueSet{
                return item.color.color ?? UIColor.black
            }
        default:
            let valueSet = (onBoardingDataModel?.en.onboarding ?? [])
            for item in valueSet{
                return item.color.color ?? UIColor.black
            }
        }
        return UIColor.black
    }
    
    var reasonForConsentText: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        default:
            return onBoardingDataModel?.en.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        }
    }
    
    var consentFileName: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        default:
            return onBoardingDataModel?.en.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        }
    }
    
    var consentTitle: String? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.consent.title ?? Constants.YamlDefaults.ConsentTitle
        default:
            return onBoardingDataModel?.en.consent.title ?? Constants.YamlDefaults.ConsentTitle
        }
    }
    
    var consent: Consent? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.consent
        default:
            return onBoardingDataModel?.en.consent
        }
    }
    
    var registration: Registration? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.registration
        default:
            return onBoardingDataModel?.en.registration
        }
    }
    
    
    var showGender: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showGender = onBoardingDataModel?.fr.registration.showGender else { return false }
            return showGender == Constants.true
        default:
            guard let showGender = onBoardingDataModel?.en.registration.showGender else { return false }
            return showGender == Constants.true
        }
    }
    
    var showDateOfBirth: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showDOB = onBoardingDataModel?.fr.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        default:
            guard let showDOB = onBoardingDataModel?.en.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        }
    }
    
    var completionStepTitle: String? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        default:
            return onBoardingDataModel?.en.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        }
    }
    
    var completionStepText: String? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        default:
            return onBoardingDataModel?.en.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        }
    }
    
    var isPasscodeEnabled: Bool {
        switch defaultLanguage {
        case "fr":
            guard let passcode = onBoardingDataModel?.fr.passcode.enable else { return true }
            return passcode != Constants.false
        default:
            guard let passcode = onBoardingDataModel?.en.passcode.enable else { return true }
            return passcode != Constants.false
        }
    }
    
    var failedLoginText: String? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        default:
            return onBoardingDataModel?.en.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        }
    }
    
    var failedLoginTitle: String? {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        default:
            return onBoardingDataModel?.en.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        }
    }
    
    
    var passcodeOnReturnText: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        default:
            return onBoardingDataModel?.en.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        }
    }
    
    var passcodeType: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeType ?? Constants.Passcode.lengthFour
        default:
            return onBoardingDataModel?.en.passcode.passcodeType ?? Constants.Passcode.lengthFour
        }
    }
    
    
    var loginPasswordless: Bool {
        switch defaultLanguage {
        case "fr":
            guard let passwordless = onBoardingDataModel?.fr.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        default:
            guard let passwordless = onBoardingDataModel?.en.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        }
    }
    
    var loginStepTitle: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        default:
            return onBoardingDataModel?.en.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        }
    }
    
    var loginStepText: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        default:
            return onBoardingDataModel?.en.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        }
    }
    
    var passcodeText: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        default:
            return onBoardingDataModel?.en.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        }
    }
    var loginOptionsText: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        default:
            return onBoardingDataModel?.en.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        }
    }
    
    var loginOptionsIcon: String {
        switch defaultLanguage {
        case "fr":
            return onBoardingDataModel?.fr.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        default:
            return onBoardingDataModel?.en.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        }
    }
}

struct Consent: Codable {
    let reviewConsentStepText: String
    let reasonForConsentText: String
    let fileName: String
    let title: String
    let data: [ConsentDescription]
}

struct ConsentDescription: Codable {
    let show: String
    let summary: String
    let content: String
}

struct Onboarding: Codable, Equatable {
    let image: String
    let icon: String
    let title: String
    let color: String
    let description: String
}

struct Registration: Codable {
    let showDateOfBirth: String
    let showGender: String
}

struct CompletionStep: Codable {
    let title: String
    let text: String
}

struct OnBoardingScreen: Codable{
    let en: OnBoardingDataModel
    let fr: OnBoardingDataModel
}

struct LoginOptionsInfo: Codable {
    let text: String
    let icon: String
}

struct OnBoardingDataModel: Codable{
    let onboarding: [Onboarding]
    let consent: Consent
    let registration: Registration
    let completionStep: CompletionStep
    let passcode: Passcode
    let login: Login
    let loginOptionsInfo: LoginOptionsInfo
    //    let designConfig: [DesignConfig]
}
