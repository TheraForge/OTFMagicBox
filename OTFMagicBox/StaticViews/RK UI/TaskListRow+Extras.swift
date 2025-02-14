/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.
 
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

import OTFResearchKit

extension TaskListRow {
    class TaskListRowSection {
        var title: String
        var rows: [TaskListRow]
        init(title: String, rows: [TaskListRow]) {
            self.title = title
            self.rows = rows
        }
    }
    
    /// Returns an array of all the task list row enum cases.
    static var sections: [ TaskListRowSection ] {
        return [
            TaskListRowSection(title: "Surveys", rows: [.form, .groupedForm, .survey]),
            TaskListRowSection(title: "Survey Questions",
                               rows: [ .booleanQuestion, .customBooleanQuestion,
                                       .dateQuestion, .dateTimeQuestion,
                                       // .heightQuestion,
                                       // .weightQuestion,
                                .imageChoiceQuestion, .locationQuestion,
                                       .numericQuestion, .scaleQuestion,
                                       .textQuestion, .textChoiceQuestion,
                                       .timeIntervalQuestion, .timeOfDayQuestion,
                                       .valuePickerChoiceQuestion, .validatedTextQuestion,
                                       .imageCapture, .videoCapture, .frontFacingCamera,
                                       .wait, .PDFViewer
                                       // .requestPermissions
                               ]),
            TaskListRowSection(
                title: "Onboarding",
                rows: [.eligibilityTask, .consent, .accountCreation, .login, .passcode]
            ),
            TaskListRowSection(title: "Active Tasks", rows:
                                [ .audio, .amslerGrid, .fitness, .holePegTest, .psat,
                                  .reactionTime, .shortWalk, .spatialSpanMemory,
                                  .speechRecognition, .speechInNoise, .stroop, .swiftStroop,
                                  .timedWalkWithTurnAround, .toneAudiometry, .dBHLToneAudiometry,
                                  .splMeter, .towerOfHanoi, .tremorTest, .twoFingerTappingInterval,
                                  .walkBackAndForth, .kneeRangeOfMotion, .shoulderRangeOfMotion,
                                  .trailMaking, .visualAcuityLandoltC, .contrastSensitivityPeakLandoltC
                                ]),
            TaskListRowSection(title: "Miscellaneous", rows:
                                [ .videoInstruction, .webView ])
        ]
    }
}

extension TaskListRow {
    // MARK: Types
    /**
     Every step and task in the ResearchKit framework has to have an identifier.
     Within a task, the step identifiers should be unique.

     Here we use an enum to ensure that the identifiers are kept unique. Since
     the enum has a raw underlying type of a `String`, the compiler can determine
     the uniqueness of the case values at compile time.

     In a real application, the identifiers for your tasks and steps might
     come from a database, or in a smaller application, might have some
     human-readable meaning.
     */
    enum Identifier {
        // Task with a form, where multiple items appear on one page.
        case formTask
        case groupedFormTask
        case formStep
        case groupedFormStep
        case formItem01
        case formItem02
        case formItem03
        case formItem04
        // Survey task specific identifiers.
        case surveyTask
        case introStep
        case questionStep
        case birthdayQuestion
        case summaryStep
        // Task with a Boolean question.
        case booleanQuestionTask
        case booleanQuestionStep
        // Task with an example of date entry.
        case dateQuestionTask
        case dateQuestionStep
        // Task with an example of date and time entry.
        case dateTimeQuestionTask
        case dateTimeQuestionStep
        // Task with an example of height entry.
        // case heightQuestionTask
        case heightQuestionStep1
        case heightQuestionStep2
        case heightQuestionStep3
        case heightQuestionStep4
        // Task with an example of weight entry.
        // case weightQuestionTask
        case weightQuestionStep1
        case weightQuestionStep2
        case weightQuestionStep3
        case weightQuestionStep4
        case weightQuestionStep5
        case weightQuestionStep6
        case weightQuestionStep7
        // Task with an image choice question.
        case imageChoiceQuestionTask
        case imageChoiceQuestionStep1
        case imageChoiceQuestionStep2
        // Task with a location entry.
        case locationQuestionTask
        case locationQuestionStep
        // Task with examples of numeric questions.
        case numericQuestionTask
        case numericQuestionStep
        case numericNoUnitQuestionStep
        // Task with examples of questions with sliding scales.
        case scaleQuestionTask
        case discreteScaleQuestionStep
        case continuousScaleQuestionStep
        case discreteVerticalScaleQuestionStep
        case continuousVerticalScaleQuestionStep
        case textScaleQuestionStep
        case textVerticalScaleQuestionStep
        // Task with an example of free text entry.
        case textQuestionTask
        case textQuestionStep
        // Task with an example of a multiple choice question.
        case textChoiceQuestionTask
        case textChoiceQuestionStep
        // Task with an example of time of day entry.
        case timeOfDayQuestionTask
        case timeOfDayQuestionStep
        // Task with an example of time interval entry.
        case timeIntervalQuestionTask
        case timeIntervalQuestionStep
        // Task with a value picker.
        case valuePickerChoiceQuestionTask
        case valuePickerChoiceQuestionStep
        // Task with an example of validated text entry.
        case validatedTextQuestionTask
        case validatedTextQuestionStepEmail
        case validatedTextQuestionStepDomain
        // Image capture task specific identifiers.
        case imageCaptureTask
        case imageCaptureStep
        // Video capture task specific identifiers.
        case videoCaptureTask
        case videoCaptureStep
        case frontFacingCameraStep
        // Task with an example of waiting.
        case waitTask
        case waitStepDeterminate
        case waitStepIndeterminate
        case pdfViewerStep
        case pdfViewerTask
        // case requestPermissionsStep
        // Eligibility task specific indentifiers.
        case eligibilityTask
        case eligibilityIntroStep
        case eligibilityFormStep
        case eligibilityFormItem01
        case eligibilityFormItem02
        case eligibilityFormItem03
        case eligibilityIneligibleStep
        case eligibilityEligibleStep
        // Consent task specific identifiers.
        case consentTask
        case visualConsentStep
        case consentSharingStep
        case consentReviewStep
        case consentDocumentParticipantSignature
        case consentDocumentInvestigatorSignature
        // Account creation task specific identifiers.
        case accountCreationTask
        case registrationStep
        case waitStep
        case verificationStep
        // Login task specific identifiers.
        case loginTask
        case loginStep
        case loginWaitStep
        // Passcode task specific identifiers.
        case passcodeTask
        case passcodeStep
        // Active tasks.
        case audioTask
        case amslerGridTask
        case fitnessTask
        case holePegTestTask
        case psatTask
        case reactionTime
        case shortWalkTask
        case spatialSpanMemoryTask
        case speechRecognitionTask
        case speechInNoiseTask
        case stroopTask
        case swiftStroopTask
        case timedWalkWithTurnAroundTask
        case toneAudiometryTask
        case dBHLToneAudiometryTask
        case splMeterTask
        case splMeterStep
        case towerOfHanoi
        case tremorTestTask
        case twoFingerTappingIntervalTask
        case walkBackAndForthTask
        case kneeRangeOfMotion
        case shoulderRangeOfMotion
        case trailMaking
        case visualAcuityLandoltC
        case contrastSensitivityPeakLandoltC
        // Video instruction tasks.
        case videoInstructionTask
        case videoInstructionStep
        // Web view tasks.
        case webViewTask
        case webViewStep
    }
}

extension TaskListRow {
    // MARK: CustomStringConvertible
    var description: String {
        switch self {
        case .form: return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.formSurveyExample ?? "Form Survey Example", comment: "")
        case .groupedForm: return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.groupedFormSurveyExample ?? "Grouped Form Survey Example", comment: "")
        case .survey:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.simpleSurveyExample ?? "Simple Survey Example", comment: "")
        case .booleanQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.booleanQuestion ?? "Boolean Question", comment: "")
        case .customBooleanQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.customBooleanQuestion ?? "Custom Boolean Question", comment: "")
        case .dateQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.dateQuestion ?? "Date Question", comment: "")
        case .dateTimeQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.dateAndTimeQuestion ?? "Date and Time Question", comment: "")
        case .imageChoiceQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.imageChoiceQuestion ?? "Image Choice Question", comment: "")
        case .locationQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.locationQuestion ?? "Location Question", comment: "")
        case .numericQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.numericQuestion ?? "Numeric Question", comment: "")
        case .scaleQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.scaleQuestion ?? "Scale Question", comment: "")
        case .textQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.textQuestion ?? "Text Question", comment: "")
        case .textChoiceQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.textChoiceQuestion ?? "Text Choice Question", comment: "")
        case .timeIntervalQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.timeIntervalQuestion ?? "Time Interval Question", comment: "")
        case .timeOfDayQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.timeOfDayQuestion ?? "Time of Day Question", comment: "")
        case .valuePickerChoiceQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.valuePickerChoiceQuestion ?? "Value Picker Choice Question", comment: "")
        case .validatedTextQuestion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.validatedTextQuestion ?? "Validated Text Question", comment: "")
        case .imageCapture:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.imageCaptureStep ?? "Image Capture Step", comment: "")
        case .videoCapture:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.videoCaptureStep ?? "Video Capture Step", comment: "")
        case .frontFacingCamera:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.frontFacingCameraStep ?? "Front Facing Camera Step", comment: "")
        case .wait:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.waitStep ?? "Wait Step", comment: "")
        case .PDFViewer:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.pdfViewerStep ?? "PDF Viewer Step", comment: "")
        case .eligibilityTask:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.eligibilityTaskExample ?? "Eligibility Task Example", comment: "")
        case .consent:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.consentObtainingExample ?? "Consent-Obtaining Example", comment: "")
        case .accountCreation:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.accountCreation ?? "Account Creation", comment: "")
        case .login:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.login ?? "Login", comment: "")
        case .passcode:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.passcodeCreation ?? "Passcode Creation", comment: "")
        case .audio:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.audio ?? "Audio", comment: "")

        case .amslerGrid:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.amslerGrid ?? "Amsler Grid", comment: "")
        case .fitness:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.fitnessCheck ?? "Fitness Check", comment: "")

        case .holePegTest:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.holePegTest ?? "Hole Peg Test", comment: "")
        case .psat:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.psat ?? "PSAT", comment: "")
        case .reactionTime:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.reactionTime ?? "Reaction Time", comment: "")
        case .shortWalk:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.shortWalk ?? "Short Walk", comment: "")
        case .spatialSpanMemory:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.spatialSpanMemory ?? "Spatial Span Memory", comment: "")
        case .speechRecognition:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.speechRecognition ?? "Speech Recognition", comment: "")

        case .speechInNoise:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.speechInNoise ?? "Speech in Noise", comment: "")
        case .stroop:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.stroop ?? "Stroop", comment: "")
        case .swiftStroop:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.swiftStroop ?? "Swift Stroop", comment: "")
        case .timedWalkWithTurnAround:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.timedWalkWithTurnAround ?? "Timed Walk with Turn Around", comment: "")
        case .toneAudiometry:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.toneAudiometry ?? "Tone Audiometry", comment: "")
        case .dBHLToneAudiometry:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.dBHLToneAudiometry ?? "dBHL Tone Audiometry", comment: "")
        case .splMeter:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.environmentSPLMeter ?? "Environment SPL Meter", comment: "")
        case .towerOfHanoi:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.towerOfHanoi ?? "Tower of Hanoi", comment: "")
        case .twoFingerTappingInterval:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.twoFingerTappingInterval ?? "Two Finger Tapping Interval", comment: "")
        case .walkBackAndForth:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.walkBackAndForth ?? "Walk Back and Forth", comment: "")
        case .tremorTest:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.tremorTest ?? "Tremor Test", comment: "")
        case .videoInstruction:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.videoInstructionTask ?? "Video Instruction Task", comment: "")
        case .kneeRangeOfMotion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.kneeRangeOfMotion ?? "Knee Range of Motion", comment: "")
        case .shoulderRangeOfMotion:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.shoulderRangeOfMotion ?? "Shoulder Range of Motion", comment: "")
        case .trailMaking:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.trailMakingTest ?? "Trail Making Test", comment: "")
        case .visualAcuityLandoltC:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.visualAcuityLandoltC ?? "Visual Acuity Landolt C", comment: "")
        case .contrastSensitivityPeakLandoltC:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.contrastSensitivityPeak ?? "Contrast Sensitivity Peak", comment: "")
        case .webView:
            return NSLocalizedString(ModuleAppYmlReader().researchKitModel?.webView ?? "Web View", comment: "")
        }
    }
}
