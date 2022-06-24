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
    
    var dataModel : DataModel?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: DataModel].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    dataModel = data["DataModel"]
                }
            }
        }
    }
    
    // Returns primary color.
    var primaryColor: UIColor {
        let valueSet = (dataModel?.designConfig ?? [])
        
        for value in valueSet where value.name == "label" {
            return value.textValue.color ?? UIColor.black
        }
        return .black
    }
    
    
    // Returns tint color.
    var tintColor: UIColor {
        let valueSet = (dataModel?.designConfig ?? [])
        
        for value in valueSet where value.name == "tintColor" {
            return value.textValue.color ?? UIColor.black
        }
        return .black
    }
    
    var apiKey: String {
        guard let apiKey = dataModel?.apiKey else {
            return Constants.YamlDefaults.APIKey
        }
        return apiKey
    }
    
    var loginPasswordless: Bool {
        guard let passwordless = dataModel?.login.loginPasswordless else { return false }
        return passwordless == Constants.true
    }
    
    var loginStepTitle: String {
        return dataModel?.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
    }
    
    var loginStepText: String {
        return dataModel?.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
    }
    
    var onboardingData: [Onboarding]? {
        return dataModel?.onboarding
    }
    
    var registration: Registration? {
        return dataModel?.registration
    }
    
    var studyTitle: String {
        if let title = dataModel?.studyTitle {
            return title
        }
        return Constants.YamlDefaults.TeamName
    }
    
    var teamName: String {
        return dataModel?.teamName ?? Constants.YamlDefaults.TeamName
    }
    
    var teamEmail: String {
        return dataModel?.teamEmail ?? Constants.YamlDefaults.TeamEmail
    }
    
    var teamPhone: String {
        return dataModel?.teamPhone ?? Constants.YamlDefaults.TeamPhone
    }
    
    var teamCopyright: String {
        return dataModel?.copyright ?? Constants.YamlDefaults.TeamCopyright
    }
    
    var teamWebsite: String {
        return dataModel?.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
    }
    
    var reviewConsentStepText: String {
        return dataModel?.consent.reviewConsentStepText ?? Constants.YamlDefaults.ReasonForConsentText
    }
    
    var reasonForConsentText: String {
        return dataModel?.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
    }
    
    var consentFileName: String {
        return dataModel?.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
    }
    
    var consentTitle: String? {
        return dataModel?.consent.title ?? Constants.YamlDefaults.ConsentTitle
    }
    
    var passcodeText: String {
        return dataModel?.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
    }
    
    var loginOptionsText: String {
        return dataModel?.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
    }
    
    var loginOptionsIcon: String {
        return dataModel?.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
    }
    
    var isPasscodeEnabled: Bool {
        guard let passcode = dataModel?.passcode.enable else { return true }
        return passcode != Constants.false
    }
    
    var passcodeOnReturnText: String {
        return dataModel?.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
    }
    
    var passcodeType: String {
        return dataModel?.passcode.passcodeType ?? Constants.Passcode.lengthFour
    }
    
    var showAppleLogin: Bool {
        guard let showSocialLogin = dataModel?.showAppleSignin else { return false }
        return showSocialLogin == Constants.true
    }
    
    var showGoogleLogin: Bool {
        guard let showSocialLogin = dataModel?.showGoogleSignin else { return false }
        return showSocialLogin == Constants.true
    }
    
    var googleClientID: String? {
        return dataModel?.googleClientID
    }
    
    var showGender: Bool {
        guard let showGender = dataModel?.registration.showGender else { return false }
        return showGender == Constants.true
    }
    
    var showDateOfBirth: Bool {
        guard let showDOB = dataModel?.registration.showDateOfBirth else { return false }
        return showDOB == Constants.true
    }
    
    var failedLoginText: String? {
        return dataModel?.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
    }
    
    var failedLoginTitle: String? {
        return dataModel?.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
    }
    
    var healthPermissionsTitle: String? {
        return dataModel?.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
    }
    
    var healthPermissionsText: String? {
        return dataModel?.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
    }
    
    var useCareKit: Bool {
        guard let useCareKit = dataModel?.useCareKit else { return false }
        return useCareKit == Constants.true
    }
    
    var showCheckupScreen: Bool {
        guard let showCheckupScreen = dataModel?.showCheckupScreen else { return false }
        return showCheckupScreen == Constants.true
    }
    
    var showStaticUIScreen: Bool {
        guard let showStaticUIScreen = dataModel?.showStaticUIScreen else { return false }
        return showStaticUIScreen == Constants.true
    }
    
    var backgroundReadFrequency: String? {
        return dataModel?.healthKitData.backgroundReadFrequency ?? "immediate"
    }
    
    var healthRecords: HealthRecords? {
        return dataModel?.healthRecords
    }
    
    var consent: Consent? {
        return dataModel?.consent
    }
    
    var withdrawl: Withdrawal? {
        return dataModel?.withdrawal
    }
    
    var healthKitDataToRead: [HealthKitTypes] {
        return dataModel?.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
    }
    
    var completionStepTitle: String? {
        return dataModel?.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
    }
    
    var completionStepText: String? {
        return dataModel?.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
    }
}
