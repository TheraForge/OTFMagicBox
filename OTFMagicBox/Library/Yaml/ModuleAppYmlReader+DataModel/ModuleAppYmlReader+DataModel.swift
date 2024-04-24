//
//  ModuleAppYmlReader+DataModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 17/05/2022.
//

import Foundation
import UIKit
import SwiftUI
import Yams
import OTFUtilities

public class ModuleAppYmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.moduleAppFileName
    
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
    
    
    func getPreferredLocale() -> Locale {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferredIdentifier)
    }
    
    var onboardingData: [Onboarding]? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.onboarding
        default:
            return onBoardingDataModel?.en.onboarding
        }
    }
    
    var primaryColor: UIColor {
        switch getPreferredLocale().languageCode {
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
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        default:
            return onBoardingDataModel?.en.consent.reasonForConsentText ?? Constants.YamlDefaults.TeamWebsite
        }
    }
    
    var consentFileName: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        default:
            return onBoardingDataModel?.en.consent.fileName ?? Constants.YamlDefaults.ConsentFileName
        }
    }
    
    var consentTitle: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.consent.title ?? Constants.YamlDefaults.ConsentTitle
        default:
            return onBoardingDataModel?.en.consent.title ?? Constants.YamlDefaults.ConsentTitle
        }
    }
    
    var consent: Consent? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.consent
        default:
            return onBoardingDataModel?.en.consent
        }
    }
    
    var registration: Registration? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.registration
        default:
            return onBoardingDataModel?.en.registration
        }
    }
    
    
    var showGender: Bool {
        switch getPreferredLocale().languageCode {
        case "fr":
            guard let showGender = onBoardingDataModel?.fr.registration.showGender else { return false }
            return showGender == Constants.true
        default:
            guard let showGender = onBoardingDataModel?.en.registration.showGender else { return false }
            return showGender == Constants.true
        }
    }
    
    var showDateOfBirth: Bool {
        switch getPreferredLocale().languageCode {
        case "fr":
            guard let showDOB = onBoardingDataModel?.fr.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        default:
            guard let showDOB = onBoardingDataModel?.en.registration.showDateOfBirth else { return false }
            return showDOB == Constants.true
        }
    }
    
    var completionStepTitle: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        default:
            return onBoardingDataModel?.en.completionStep.title ?? Constants.YamlDefaults.CompletionStepTitle
        }
    }
    
    var completionStepText: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        default:
            return onBoardingDataModel?.en.completionStep.text ?? Constants.YamlDefaults.CompletionStepText
        }
    }
    
    var isPasscodeEnabled: Bool {
        switch getPreferredLocale().languageCode {
        case "fr":
            guard let passcode = onBoardingDataModel?.fr.passcode.enable else { return true }
            return passcode != Constants.false
        default:
            guard let passcode = onBoardingDataModel?.en.passcode.enable else { return true }
            return passcode != Constants.false
        }
    }
    
    var failedLoginText: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        default:
            return onBoardingDataModel?.en.login.failedLoginText ?? Constants.YamlDefaults.FailedLoginText
        }
    }
    
    var failedLoginTitle: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        default:
            return onBoardingDataModel?.en.login.failedLoginTitle ?? Constants.YamlDefaults.FailedLoginTitle
        }
    }
    
    
    var passcodeOnReturnText: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        default:
            return onBoardingDataModel?.en.passcode.passcodeOnReturnText ?? Constants.YamlDefaults.PasscodeOnReturnText
        }
    }
    
    var passcodeType: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeType ?? Constants.Passcode.lengthFour
        default:
            return onBoardingDataModel?.en.passcode.passcodeType ?? Constants.Passcode.lengthFour
        }
    }
    
    
    var loginPasswordless: Bool {
        switch getPreferredLocale().languageCode {
        case "fr":
            guard let passwordless = onBoardingDataModel?.fr.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        default:
            guard let passwordless = onBoardingDataModel?.en.login.loginPasswordless else { return false }
            return passwordless == Constants.true
        }
    }
    
    var loginStepTitle: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        default:
            return onBoardingDataModel?.en.login.loginStepTitle ?? Constants.YamlDefaults.LoginStepTitle
        }
    }
    
    var loginStepText: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        default:
            return onBoardingDataModel?.en.login.loginStepText ?? Constants.YamlDefaults.LoginStepText
        }
    }
    
    var passcodeText: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        default:
            return onBoardingDataModel?.en.passcode.passcodeText ?? Constants.YamlDefaults.PasscodeText
        }
    }
    var loginOptionsText: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        default:
            return onBoardingDataModel?.en.loginOptionsInfo.text ?? Constants.YamlDefaults.LoginOptionsText
        }
    }
    
    var loginOptionsIcon: String {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        default:
            return onBoardingDataModel?.en.loginOptionsInfo.icon ?? Constants.YamlDefaults.LoginOptionsIcon
        }
    }
    
    var profileData: ProfileModel? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.profileDataModel
        default:
            return onBoardingDataModel?.en.profileDataModel
        }
    }
    
    var backgroundColor: UIColor {
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        
        switch langStr {
        case "fr":
            return onBoardingDataModel?.fr.profileDataModel.backgroundColor.color ?? UIColor.black
        default:
            return onBoardingDataModel?.en.profileDataModel.backgroundColor.color ?? UIColor.black
        }
    }
    
    var researchKitModel: ResearchKitModel? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.researchKitView
        default:
            return onBoardingDataModel?.en.researchKitView
        }
    }
    
    var surverysTaskModel: SurverysTask? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.surverysTask
        default:
            return onBoardingDataModel?.en.surverysTask
        }
    }
    
    var careKitModel: CarekitModel? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.carekitView
        default:
            return onBoardingDataModel?.en.carekitView
        }
    }
    
    var healthRecords: HealthRecords? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.healthRecords
        default:
            return onBoardingDataModel?.en.healthRecords
        }
    }
    
    var healthPermissionsTitle: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
        default:
            return onBoardingDataModel?.en.healthKitData.healthPermissionsTitle ?? Constants.YamlDefaults.HealthPermissionsTitle
        }
    }
    
    var healthPermissionsText: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
        default:
            return onBoardingDataModel?.en.healthKitData.healthPermissionsText ?? Constants.YamlDefaults.HealthPermissionsText
        }
    }
    
    
    var backgroundReadFrequency: String? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.healthKitData.backgroundReadFrequency ?? "immediate"
        default:
            return onBoardingDataModel?.en.healthKitData.backgroundReadFrequency ?? "immediate"
        }
    }
    
    var healthKitDataToRead: [HealthKitTypes] {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
        default:
            return onBoardingDataModel?.en.healthKitData.healthKitTypes ?? [HealthKitTypes(type: "stepCount"), HealthKitTypes(type: "distanceSwimming")]
        }
    }
    
    var withdrawl: Withdrawal? {
        switch getPreferredLocale().languageCode {
        case "fr":
            return onBoardingDataModel?.fr.withdrawal
        default:
            return onBoardingDataModel?.en.withdrawal
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
    let title: String
    let image: String
}

struct Onboarding: Codable, Equatable {
    let image: String
    let icon: String
    let title: String?
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
    let profileDataModel: ProfileModel
    let researchKitView: ResearchKitModel
    let surverysTask: SurverysTask
    let carekitView: CarekitModel
    let healthRecords: HealthRecords
    let healthKitData: HealthKitData
    let withdrawal: Withdrawal
}

struct HealthRecords: Codable {
    let enabled: String
    let permissionsText: String
    let permissionsTitle: String
}

struct Withdrawal: Codable {
    let withdrawTitle: String
    let withdrawText: String
    let withdrawalInstructionTitle: String
    let withdrawalInstructionText: String
}

struct HealthKitData: Codable {
    let healthPermissionsTitle: String
    let healthPermissionsText: String
    let backgroundReadFrequency: String
    let healthKitTypes: [HealthKitTypes]
}

struct HealthKitTypes: Codable, Equatable  {
    let type: String
}

struct ProfileModel: Codable{
    let title: String
    let profileImage: String
    let help: String
    let resetPasswordText: String
    let reportProblemText: String
    let supportText: String
    let consentText: String
    let WithdrawStudyText: String
    let profileInfoHeader: String
    let firstName: String
    let lastName: String
    let reportProblemHeader: String
    let otherInfo: String
    let oldPassword: String
    let newPassword: String
    let resetPassword: String
    let backgroundColor: String
}

struct ResearchKitModel: Codable{
    let surveysHeaderTitle: String
    let formSurveyExample: String
    let groupedFormSurveyExample: String
    let simpleSurveyExample: String
    let surveyQuestionHeaderTitle: String
    let booleanQuestion: String
    let customBooleanQuestion: String
    let dateQuestion: String
    let dateAndTimeQuestion: String
    let heightQuestion: String
    let weightQuestion: String
    let imageChoiceQuestion: String
    let locationQuestion: String
    let numericQuestion: String
    let scaleQuestion: String
    let textQuestion: String
    let textChoiceQuestion: String
    let timeIntervalQuestion: String
    let timeOfDayQuestion: String
    let valuePickerChoiceQuestion: String
    let validatedTextQuestion: String
    let imageCaptureStep: String
    let videoCaptureStep: String
    let frontFacingCameraStep: String
    let waitStep: String
    let pdfViewerStep: String
    let onBoardingHeaderTitle: String
    let eligibilityTaskExample: String
    let consentObtainingExample: String
    let accountCreation: String
    let login: String
    let passcodeCreation: String
    let activeTasksHeaderTitle: String
    let audio: String
    let amslerGrid: String
    let fitnessCheck: String
    let holePegTest: String
    let psat: String
    let reactionTime: String
    let shortWalk: String
    let spatialSpanMemory: String
    let speechRecognition: String
    let speechInNoise: String
    let stroop: String
    let swiftStroop: String
    let timedWalkWithTurnAround: String
    let toneAudiometry: String
    let dBHLToneAudiometry: String
    let environmentSPLMeter: String
    let towerOfHanoi: String
    let twoFingerTappingInterval: String
    let walkBackAndForth: String
    let tremorTest: String
    let videoInstructionTask: String
    let kneeRangeOfMotion: String
    let shoulderRangeOfMotion: String
    let trailMakingTest: String
    let visualAcuityLandoltC: String
    let contrastSensitivityPeak: String
    let miscellaneousHeaderTitle: String
    let webView: String
    let researchKit: String
    
}


struct SurverysTask: Codable{
    let title: String
    let additionalText: String
    let itemQuestion: String
    let grannySmith: String
    let honeycrisp: String
    let fuji: String
    let mcIntosh: String
    let kanzi: String
    let questionText: String
    let groupServeyTitle: String
    let sectionTitle: String
    let sectionDetailText: String
    let placeholder: String
    let socioeconomicLadder: String
    let questionnaire: String
    let newsletter: String
    let learnMoreTitle: String
    let learnMoreText: String
    let birthdayText: String
    
}

struct CarekitModel: Codable{
    let simple: String
    let instruction: String
    let buttonLog: String
    let grid: String
    let checklist: String
    let labeledValue: String
    let numericProgress: String
    let contactHeader: String
    let taskHeader: String
    let detailed: String
    let careKit: String
}

