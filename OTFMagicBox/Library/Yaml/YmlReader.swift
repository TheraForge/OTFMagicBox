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
import OTFUtilities

/**
 YmlReader decodes the Yaml values from the given file.
 */
public class YmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.FileName
    
    var dataModel : DefaultConfig?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: DefaultConfig].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    dataModel = data["DataModel"]
                }
            }
        }
    }
    
    func getPreferredLocale() -> Locale {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferredIdentifier)
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
    
    
    var appTitle: String {
    switch getPreferredLocale().languageCode {
        case "fr":
            if let title = dataModel?.fr.appTitle {
                return title
            }
        default:
            if let title = dataModel?.en.appTitle {
                return title
            }
        }
        return Constants.YamlDefaults.TeamName
    }
    
    var teamName: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return dataModel?.fr.teamName ?? Constants.YamlDefaults.TeamName
        default:
            return dataModel?.en.teamName ?? Constants.YamlDefaults.TeamName
        }
    }
    
    var teamEmail: String {
        return dataModel?.teamEmail ?? Constants.YamlDefaults.TeamEmail
    }
    
    var teamPhone: String {
        return dataModel?.teamPhone ?? Constants.YamlDefaults.TeamPhone
    }
    
    var teamCopyright: String {
        
        switch getPreferredLocale().languageCode {
        case "fr":
            return dataModel?.fr.copyright ?? Constants.YamlDefaults.TeamCopyright
        default:
            return dataModel?.en.copyright ?? Constants.YamlDefaults.TeamCopyright
        }
    }
    
    var teamWebsite: String {
        return dataModel?.teamWebsite ?? Constants.YamlDefaults.TeamWebsite
    }
    
    var showAppleLogin: Bool {
        guard let showSocialLogin = dataModel?.showAppleSignin else { return false }
        return showSocialLogin == Constants.true
    }
    
    var showGoogleLogin: Bool {
        guard let showSocialLogin = dataModel?.showGoogleSignin else { return false }
        return showSocialLogin == Constants.true
    }
    
//    var healthPermissionsTitle: String? {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
//        default:
//            return dataModel?.en.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
//        }
//    }
//    
//    var healthPermissionsText: String? {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
//        default:
//            return dataModel?.en.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
//        }
//    }
    
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
//    
//    var backgroundReadFrequency: String? {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.healthKitData.backgroundReadFrequency ?? "immediate"
//        default:
//            return dataModel?.en.healthKitData.backgroundReadFrequency ?? "immediate"
//        }
//    }
    
//    var healthRecords: HealthRecords? {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.healthRecords
//        default:
//            return dataModel?.en.healthRecords
//        }
//    }
    
    var appTheme: ThemeCustomization? {
        return dataModel?.appTheme
    }
    
//    var withdrawl: Withdrawal? {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.withdrawal
//        default:
//            return dataModel?.en.withdrawal
//        }
//    }
    
//    var healthKitDataToRead: [HealthKitTypes] {
//        switch getPreferredLocale().languageCode {
//        case "fr":
//            return dataModel?.fr.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
//        default:
//            return dataModel?.en.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
//        }
//    }
}
