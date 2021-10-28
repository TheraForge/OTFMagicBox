//
//  YmlReader.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

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
        return UIColor()
    }
    
    
    // Returns tint color.
    var tintColor: UIColor {
        let valueSet = (dataModel?.designConfig ?? [])
        
        for value in valueSet where value.name == "tintColor" {
            return value.textValue.color ?? UIColor.black
        }
        return UIColor()
    }
    
    var apiKey: String {
        guard let apiKey = dataModel?.apiKey else {
            return Constants.YamlDefaults.APIKey
        }
        return apiKey
    }
    
    var loginPasswordless: Bool {
        guard let passwordless = dataModel?.login.loginPasswordless else { return false }
        return passwordless == "true"
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
    
    var isPasscodeEnabled: Bool {
        guard let passcode = dataModel?.passcode.enable else { return true }
        return passcode != "false"
    }
    
    var passcodeOnReturnText: String {
        return dataModel?.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
    }
    
    var passcodeType: String {
        return dataModel?.passcode.passcodeType ?? Constants.Passcode.lengthFour
    }
    
    var showGender: Bool {
        guard let showGender = dataModel?.registration.showGender else { return false }
        return showGender == "true"
    }
    
    var showDateOfBirth: Bool {
        guard let showDOB = dataModel?.registration.showDateOfBirth else { return false }
        return showDOB == "true"
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
        return useCareKit == "true"
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
