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

import Foundation
import UIKit
import SwiftUI
import Yams

/**
 YmlReader decodes the Yaml values from the given file.
 */
public class YmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.FileName
    
    var dataModel : defaultConfig?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: defaultConfig].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    dataModel = data["DataModel"]
                }
            }
        }
    }
    
    var defaultLanguage: String{
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        return langStr
    }
    
    // Returns primary color.
    var primaryColor: UIColor {
        let valueSet = (dataModel?.en.designConfig ?? [])
        
        for value in valueSet where value.name == "label" {
            return value.textValue.color ?? UIColor.black
        }
        return .black
    }
    
    
    // Returns tint color.
    var tintColor: UIColor {
        let valueSet = (dataModel?.en.designConfig ?? [])
        
        for value in valueSet where value.name == "tintColor" {
            return value.textValue.color ?? UIColor.black
        }
        return .black
    }
    
    var apiKey: String {
        guard let apiKey = dataModel?.en.apiKey else {
            return Constants.YamlDefaults.APIKey
        }
        return apiKey
    }
    
    var loginPasswordless: Bool {
        switch defaultLanguage {
        case "fr":
            guard let passwordless = dataModel?.en.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        default:
            guard let passwordless = dataModel?.en.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        }
    }
    
    var loginStepTitle: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        default:
            return dataModel?.en.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        }
    }
    
    var loginStepText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        default:
            return dataModel?.en.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        }
    }
    
    var registration: Registration? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.registration
        default:
            return dataModel?.en.registration
        }
    }
    
    var studyTitle: String {
    switch defaultLanguage {
        case "fr":
            if let title = dataModel?.fr.studyTitle {
                return title
            }
        default:
            if let title = dataModel?.en.studyTitle {
                return title
            }
        }
        return Constants.YamlDefaults.TeamName
    }
    
    var teamName: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.teamName ?? Constants.YamlDefaults.TeamName
        default:
            return dataModel?.en.teamName ?? Constants.YamlDefaults.TeamName
        }
    }
    
    var teamEmail: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.teamEmail ?? Constants.YamlDefaults.TeamEmail
        default:
            return dataModel?.en.teamEmail ?? Constants.YamlDefaults.TeamEmail
        }
    }
    
    var teamPhone: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.teamPhone ?? Constants.YamlDefaults.TeamPhone
        default:
            return dataModel?.en.teamPhone ?? Constants.YamlDefaults.TeamPhone
        }
    }
    
    var teamCopyright: String {
        
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.copyright ?? Constants.YamlDefaults.TeamCopyright
        default:
            return dataModel?.en.copyright ?? Constants.YamlDefaults.TeamCopyright
        }
    }
    
    var teamWebsite: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
        default:
            return dataModel?.en.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
        }
    }
    
    var reviewConsentStepText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
        default:
            return dataModel?.en.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
        }
    }
    
    var reasonForConsentText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        default:
            return dataModel?.en.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        }
    }
    
    var consentFileName: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        default:
            return dataModel?.en.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        }
    }
    
    var consentTitle: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.consent.title ?? Constants.YamlDefaults.ConsentTitle
        default:
            return dataModel?.en.consent.title ?? Constants.YamlDefaults.ConsentTitle
        }
    }
    
    var passcodeText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        default:
            return dataModel?.en.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        }
    }
    
    var loginOptionsText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        default:
            return dataModel?.en.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        }
    }
    
    var loginOptionsIcon: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.en.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        default:
            return dataModel?.en.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        }
    }
    
    var isPasscodeEnabled: Bool {
        switch defaultLanguage {
        case "fr":
            guard let passcode = dataModel?.fr.passcode.enable else { return true }
            return passcode != Constants.false
        default:
            guard let passcode = dataModel?.en.passcode.enable else { return true }
            return passcode != Constants.false
        }
    }
    
    var passcodeOnReturnText: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        default:
            return dataModel?.en.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        }
    }
    
    var passcodeType: String {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.passcode.passcodeType ?? Constants.Passcode.lengthFour
        default:
            return dataModel?.en.passcode.passcodeType ?? Constants.Passcode.lengthFour
        }
    }
    
    var showAppleLogin: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showSocialLogin = dataModel?.fr.showAppleSignin else { return false }
            return showSocialLogin == Constants.true
        default:
            guard let showSocialLogin = dataModel?.en.showAppleSignin else { return false }
            return showSocialLogin == Constants.true
        }
    }
    
    var showGoogleLogin: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showSocialLogin = dataModel?.fr.showGoogleSignin else { return false }
            return showSocialLogin == Constants.true
        default:
            guard let showSocialLogin = dataModel?.en.showGoogleSignin else { return false }
            return showSocialLogin == Constants.true
        }
    }
    
    var googleClientID: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.googleClientID
        default:
            return dataModel?.en.googleClientID
        }
    }
    
    var showGender: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showGender = dataModel?.fr.registration.showGender else { return false }
            return showGender == Constants.true
        default:
            guard let showGender = dataModel?.en.registration.showGender else { return false }
            return showGender == Constants.true
        }
    }
    
    var showDateOfBirth: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showDOB = dataModel?.fr.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        default:
            guard let showDOB = dataModel?.en.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        }
    }
    
    var failedLoginText: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        default:
            return dataModel?.en.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        }
    }
    
    var failedLoginTitle: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        default:
            return dataModel?.en.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        }
    }
    
    var healthPermissionsTitle: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
        default:
            return dataModel?.en.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
        }
    }
    
    var healthPermissionsText: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
        default:
            return dataModel?.en.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
        }
    }
    
    var useCareKit: Bool {
        switch defaultLanguage {
        case "fr":
            guard let useCareKit = dataModel?.fr.useCareKit else { return false }
            return useCareKit == Constants.true
        default:
            guard let useCareKit = dataModel?.en.useCareKit else { return false }
            return useCareKit == Constants.true
        }
    }
    
    var showCheckupScreen: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showCheckupScreen = dataModel?.fr.showCheckupScreen else { return false }
            return showCheckupScreen == Constants.true
        default:
            guard let showCheckupScreen = dataModel?.en.showCheckupScreen else { return false }
            return showCheckupScreen == Constants.true
        }
    }
    
    var showStaticUIScreen: Bool {
        switch defaultLanguage {
        case "fr":
            guard let showStaticUIScreen = dataModel?.fr.showStaticUIScreen else { return false }
            return showStaticUIScreen == Constants.true
        default:
            guard let showStaticUIScreen = dataModel?.en.showStaticUIScreen else { return false }
            return showStaticUIScreen == Constants.true
        }
    }
    
    var backgroundReadFrequency: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.healthKitData.backgroundReadFrequency ?? "immediate"
        default:
            return dataModel?.en.healthKitData.backgroundReadFrequency ?? "immediate"
        }
    }
    
    var healthRecords: HealthRecords? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.healthRecords
        default:
            return dataModel?.en.healthRecords
        }
    }
    
    var consent: Consent? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.consent
        default:
            return dataModel?.en.consent
        }
    }
    
    var withdrawl: Withdrawal? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.withdrawal
        default:
            return dataModel?.en.withdrawal
        }
    }
    
    var healthKitDataToRead: [HealthKitTypes] {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
        default:
            return dataModel?.en.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
        }
    }
    
    var completionStepTitle: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        default:
            return dataModel?.en.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        }
    }
    
    var completionStepText: String? {
        switch defaultLanguage {
        case "fr":
            return dataModel?.fr.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        default:
            return dataModel?.en.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        }
    }
}
