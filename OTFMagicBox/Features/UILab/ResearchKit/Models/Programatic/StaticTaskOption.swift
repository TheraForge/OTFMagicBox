/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Macro Yau.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import OTFResearchKit
import HealthKit
import UIKit
import SwiftUI

/**
 An enum that corresponds to a row displayed in a `TaskListViewController`.
 
 Each of the tasks is composed of one or more steps giving examples of the
 types of functionality supported by the ResearchKit framework.
 */
enum StaticTaskOption: String, Identifiable {

    var id: String { rawValue }

    case form
    case groupedForm
    case survey
    case booleanQuestion
    case customBooleanQuestion
    case dateQuestion
    case dateTimeQuestion
    case imageChoiceQuestion
    case locationQuestion
    case numericQuestion
    case scaleQuestion
    case textQuestion
    case textChoiceQuestion
    case timeIntervalQuestion
    case timeOfDayQuestion
    case valuePickerChoiceQuestion
    case validatedTextQuestion
    case imageCapture
    case videoCapture
    case frontFacingCamera
    case wait
    case PDFViewer
    case eligibilityTask
    case consent
    case accountCreation
    case login
    case passcode
    case audio
    case amslerGrid
    case fitness
    case holePegTest
    case psat
    case reactionTime
    case shortWalk
    case spatialSpanMemory
    case speechRecognition
    case speechInNoise
    case stroop
    case swiftStroop
    case timedWalkWithTurnAround
    case toneAudiometry
    case dBHLToneAudiometry
    case splMeter
    case towerOfHanoi
    case tremorTest
    case twoFingerTappingInterval
    case walkBackAndForth
    case kneeRangeOfMotion
    case shoulderRangeOfMotion
    case trailMaking
    case visualAcuityLandoltC
    case contrastSensitivityPeakLandoltC
    case videoInstruction
    case webView
    
    var representedTask: ORKTask {
        switch self {
        case .form: return formTask
        case .groupedForm: return groupedFormTask
        case .survey: return surveyTask
        case .booleanQuestion: return booleanQuestionTask
        case .customBooleanQuestion: return customBooleanQuestionTask
        case .dateQuestion: return dateQuestionTask
        case .dateTimeQuestion: return dateTimeQuestionTask
        case .imageChoiceQuestion: return imageChoiceQuestionTask
        case .locationQuestion: return locationQuestionTask
        case .numericQuestion: return numericQuestionTask
        case .scaleQuestion: return scaleQuestionTask
        case .textQuestion: return textQuestionTask
        case .textChoiceQuestion: return textChoiceQuestionTask
        case .timeIntervalQuestion: return timeIntervalQuestionTask
        case .timeOfDayQuestion: return timeOfDayQuestionTask
        case .valuePickerChoiceQuestion: return valuePickerChoiceQuestionTask
        case .validatedTextQuestion: return validatedTextQuestionTask
        case .imageCapture: return imageCaptureTask
        case .videoCapture: return videoCaptureTask
        case .frontFacingCamera: return frontFacingCameraStep
        case .wait: return waitTask
        case .PDFViewer: return PDFViewerTask
        case .eligibilityTask: return eligibilityTask
        case .consent: return consentTask
        case .accountCreation: return accountCreationTask
        case .login: return loginTask
        case .passcode: return passcodeTask
        case .audio: return audioTask
        case .amslerGrid: return amslerGridTask
        case .fitness: return fitnessTask
        case .holePegTest: return holePegTestTask
        case .psat: return PSATTask
        case .reactionTime: return reactionTimeTask
        case .shortWalk: return shortWalkTask
        case .spatialSpanMemory: return spatialSpanMemoryTask
        case .speechRecognition: return speechRecognitionTask
        case .speechInNoise: return speechInNoiseTask
        case .stroop: return stroopTask
        case .swiftStroop: return swiftStroopTask
        case .timedWalkWithTurnAround: return timedWalkWithTurnAroundTask
        case .toneAudiometry: return toneAudiometryTask
        case .dBHLToneAudiometry: return dBHLToneAudiometryTask
        case .splMeter: return splMeterTask
        case .towerOfHanoi: return towerOfHanoiTask
        case .twoFingerTappingInterval: return twoFingerTappingIntervalTask
        case .walkBackAndForth: return walkBackAndForthTask
        case .tremorTest: return tremorTestTask
        case .kneeRangeOfMotion: return kneeRangeOfMotion
        case .shoulderRangeOfMotion: return shoulderRangeOfMotion
        case .trailMaking: return trailMaking
        case .visualAcuityLandoltC: return visualAcuityLandoltC
        case .contrastSensitivityPeakLandoltC: return contrastSensitivityPeakLandoltC
        case .videoInstruction: return videoInstruction
        case .webView: return webView
        }
    }

    var description: String {
        switch self {
        case .form: return "Form Survey Example"
        case .groupedForm: return "Grouped Form Survey Example"
        case .survey: return "Simple Survey Example"
        case .booleanQuestion: return "Boolean Question"
        case .customBooleanQuestion: return "Custom Boolean Question"
        case .dateQuestion: return "Date Question"
        case .dateTimeQuestion: return "Date and Time Question"
        case .imageChoiceQuestion: return "Image Choice Question"
        case .locationQuestion: return "Location Question"
        case .numericQuestion: return "Numeric Question"
        case .scaleQuestion: return "Scale Question"
        case .textQuestion: return "Text Question"
        case .textChoiceQuestion: return "Text Choice Question"
        case .timeIntervalQuestion: return "Time Interval Question"
        case .timeOfDayQuestion: return "Time of Day Question"
        case .valuePickerChoiceQuestion: return "Value Picker Choice Question"
        case .validatedTextQuestion: return "Validated Text Question"
        case .imageCapture: return "Image Capture Step"
        case .videoCapture: return "Video Capture Step"
        case .frontFacingCamera: return "Front Facing Camera Step"
        case .wait: return "Wait Step"
        case .PDFViewer: return "PDF Viewer Step"
        case .eligibilityTask: return "Eligibility Task Example"
        case .consent: return "Consent-Obtaining Example"
        case .accountCreation: return "Account Creation"
        case .login: return "Login"
        case .passcode: return "Passcode Creation"
        case .audio: return "Audio"
        case .amslerGrid: return "Amsler Grid"
        case .fitness: return "Fitness Check"
        case .holePegTest: return "Hole Peg Test"
        case .psat: return "PSAT"
        case .reactionTime: return "Reaction Time"
        case .shortWalk: return "Short Walk"
        case .spatialSpanMemory: return "Spatial Span Memory"
        case .speechRecognition: return "Speech Recognition"
        case .speechInNoise: return "Speech in Noise"
        case .stroop: return "Stroop"
        case .swiftStroop: return "Swift Stroop"
        case .timedWalkWithTurnAround: return "Timed Walk with Turn Around"
        case .toneAudiometry: return "Tone Audiometry"
        case .dBHLToneAudiometry: return "dBHL Tone Audiometry"
        case .splMeter: return "Environment SPL Meter"
        case .towerOfHanoi: return "Tower of Hanoi"
        case .twoFingerTappingInterval: return "Two Finger Tapping Interval"
        case .walkBackAndForth: return "Walk Back and Forth"
        case .tremorTest: return "Tremor Test"
        case .videoInstruction: return "Video Instruction Task"
        case .kneeRangeOfMotion: return "Knee Range of Motion"
        case .shoulderRangeOfMotion: return "Shoulder Range of Motion"
        case .trailMaking: return "Trail Making Test"
        case .visualAcuityLandoltC: return "Visual Acuity Landolt C"
        case .contrastSensitivityPeakLandoltC: return "Contrast Sensitivity Peak"
        case .webView: return "Web View"
        }
    }

    @ViewBuilder
    var destination: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            TaskViewControllerRepresentable(task: representedTask)
        }.navigationBarHidden(true)
    }
}

// MARK: - String

extension StaticTaskOption {
    // MARK: `ORKTask` Reused Text Convenience
    var exampleDescription: String {
        return NSLocalizedString("Your description goes here.", comment: "")
    }
    
    var exampleSpeechInstruction: String {
        return NSLocalizedString("Your more specific voice instruction goes here. For example, say 'Aaaah'.", comment: "")
    }
    
    var exampleQuestionText: String {
        return NSLocalizedString("Your question goes here.", comment: "")
    }
    
    var exampleHighValueText: String {
        return NSLocalizedString("High Value", comment: "")
    }
    
    var exampleLowValueText: String {
        return NSLocalizedString("Low Value", comment: "")
    }
    
    var exampleDetailText: String {
        return NSLocalizedString("Additional text can go here.", comment: "")
    }
    
    var exampleEmailText: String {
        return NSLocalizedString("jappleseed@example.com", comment: "")
    }
    
    var loremIpsumText: String {
        return "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    }
    
    var loremIpsumShortText: String {
        return "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    }
    
    var loremIpsumMediumText: String {
        return "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis."
    }
    
    var loremIpsumLongText: String {
        return  """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis.
            Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo? An potest, inquit ille,
            quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo?
            """
    }
    
    var exampleHtml: String {
        return """
        <!DOCTYPE html>
        <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta name="viewport" content="width=400, user-scalable=no">
            <meta charset="utf-8" />
            <style type="text/css">
            body
            {
                background: #FFF;
                font-family: Helvetica, sans-serif;
                text-align: center;
            }
        
            .container
            {
                width: 100%;
                padding: 10px;
                box-sizing: border-box;
            }
        
            .answer-box
            {
                width: 100%;
                box-sizing: border-box;
                padding: 10px;
                border: solid 1px #ddd;
                border-radius: 2px;
                -webkit-appearance: none;
            }
        
            .continue-button
            {
                width: 140px;
                text-align: center;
                padding-top: 10px;
                padding-bottom: 10px;
                font-size: 16px;
                color: #2e6e9e;
                border-radius: 2px;
                border: solid 1px #2e6e9e;
                background: #FFF;
                cursor: pointer;
                margin-top: 40px;
            }
            </style>
            <script type="text/javascript">
            function completeStep() {
                var answer = document.getElementById("answer").value;
                window.webkit.messageHandlers.ResearchKit.postMessage(answer);
            }
            </script>
        </head>
        <body>
            <div class="container">
                <input type="text" id="answer" class="answer-box" placeholder="Answer" />
                <button onclick="completeStep();" class="continue-button">Continue</button>
            </div>
        </body>
        </html>
        """
    }
}
