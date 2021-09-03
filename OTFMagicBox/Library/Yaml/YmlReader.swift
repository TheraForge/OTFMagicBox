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
                guard let data = try? YAMLDecoder().decode([String : DataModel].self, from: dataSet) else {
                    return
                }
                if data["DataModel"] != nil {
                    dataModel = data["DataModel"]
                }
            }
        }
    }
    
    // Returns primary color.
    func primaryColor() -> UIColor {
        let valueSet = (dataModel?.designConfig ?? []) as Array
        
        for value in valueSet {
            if value.name == "label" {
                return UIColor().getColor(colorValue: value.textValue)
            }
        }
        return UIColor()
    }
    
    
    // Returns tint color.
    func tintColor() -> UIColor {
        let valueSet = (dataModel?.designConfig ?? []) as Array
        
        for value in valueSet {
            if value.name == "tintColor" {
                return UIColor().getColor(colorValue: value.textValue)
            }
        }
        return UIColor()
    }
    
    func loginPasswordless() -> String {
        return dataModel?.loginPasswordless ?? "true"
    }
    
    func loginStepTitle() -> String {
        return dataModel?.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
    }
    
    func loginStepText() -> String {
        return dataModel?.loginStepText ?? Constants.YamlDefaults.LoginStepText
    }
    
    func onboardingData() -> [Onboarding]? {
        return dataModel?.onboarding
    }
    
    func registration() -> Registration? {
        return dataModel?.registration
    }
    
    func studyTitle() -> String {
        if let title = dataModel?.studyTitle {
            return title
        }
        return Constants.YamlDefaults.TeamName
    }
    
    func teamName() -> String {
        return dataModel?.teamName ?? Constants.YamlDefaults.TeamName
    }
    
    func teamEmail() -> String {
        return dataModel?.teamEmail ?? Constants.YamlDefaults.TeamEmail
    }
    
    func teamPhone() -> String {
        return dataModel?.teamPhone ?? Constants.YamlDefaults.TeamPhone
    }
    
    func teamCopyright() -> String {
        return dataModel?.copyright ?? Constants.YamlDefaults.TeamCopyright
    }
    
    func teamWebsite() -> String {
        return dataModel?.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
    }
    
    func reviewConsentStepText() -> String {
        return dataModel?.reviewConsentStepText ?? Constants.YamlDefaults.ReasonForConsentText
    }
    
    func reasonForConsentText() -> String {
        return dataModel?.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
    }
    
    func consentFileName() -> String {
        return dataModel?.consentFileName ?? Constants.YamlDefaults.ConsentFileName
    }
    
    func passcodeText() -> String {
        return dataModel?.passcodeText ?? Constants.YamlDefaults.PasscodeText
    }
    
    func passcodeOnReturnText() -> String {
        return dataModel?.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
    }
    
    func passcodeType() -> String {
        return dataModel?.passcodeType ?? "4"
    }
    
    func completionStepTitle() -> String? {
        return dataModel?.completionStepTitle ?? Constants.YamlDefaults.CompletionStepTitle
    }
    
    func completionStepText() -> String? {
        return dataModel?.completionStepText ?? Constants.YamlDefaults.CompletionStepText
    }
    
    func failedLoginText() -> String? {
        return dataModel?.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
    }
    
    func failedLoginTitle() -> String? {
        return dataModel?.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
    }
    
    func healthPermissionsTitle() -> String? {
        return dataModel?.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
    }
    
    func healthPermissionsText() -> String? {
        return dataModel?.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
    }
    
    func consentTitle() -> String? {
        return dataModel?.consentTitle ?? Constants.YamlDefaults.ConsentTitle
    }
    
    func useCareKit() -> String? {
        return dataModel?.useCareKit ?? "true"
    }
    
    func backgroundReadFrequency() -> String? {
        return dataModel?.backgroundReadFrequency ?? "immediate"
    }
    
    func healthRecords() -> HealthRecords? {
        return dataModel?.healthRecords
    }
    
    func consent() -> [Consent] {
        return dataModel?.consent ?? []
    }
    
    func withdrawl() -> Withdrawl? {
        return dataModel?.withdrawl
    }
    
    func healthKitDataToRead() -> [HealthKitDataToRead] {
        return dataModel?.healthKitDataToRead ?? []
    }
}
