//
//  UIYmlReader+DataModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 27/04/2022.
//

import Foundation

import Foundation
import UIKit
import SwiftUI
import Yams

public class UIYmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.researchKitFileName
    
    var researchKitDataModel : ResearchKitScreen?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: ResearchKitScreen].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    researchKitDataModel = data["DataModel"]
                }
            }
        }
    }
    
    var defaultLanguage: String{
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        return langStr
    }
    
    var researchKitModel: ResearchKitModel? {
        switch defaultLanguage {
        case "fr":
            return researchKitDataModel?.fr.researchKitView
        default:
            return researchKitDataModel?.en.researchKitView
        }
    }
    
    var surverysTaskModel: SurverysTask? {
        switch defaultLanguage {
        case "fr":
            return researchKitDataModel?.fr.surverysTask
        default:
            return researchKitDataModel?.en.surverysTask
        }
    }
    
    var careKitModel: CarekitModel? {
        switch defaultLanguage {
        case "fr":
            return researchKitDataModel?.fr.carekitView
        default:
            return researchKitDataModel?.fr.carekitView
        }
    }
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
}

struct ResearchKitScreen: Codable{
    let en: ResearchKitDataModel
    let fr: ResearchKitDataModel
}

struct ResearchKitDataModel: Codable{
    let researchKitView: ResearchKitModel
    let surverysTask: SurverysTask
    let carekitView: CarekitModel
}

