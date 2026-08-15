/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFResearchKit
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("ResearchKit task construction")
struct ResearchKitTaskConstructionTests {
    @Test("YAML task configurations decode and build ORK tasks")
    func yamlTaskConfigurationsDecodeAndBuildORKTasks() throws {
        let cases: [(key: String, identifier: String, title: String, extraValues: [String: Any])] = [
            ("audioTask", "audio-custom", "Audio", [
                "speechInstruction": researchKitLocalized("Say Aaaah for the duration of the recording."),
                "shortSpeechInstruction": researchKitLocalized("Say Aaaah"),
                "duration": 20,
                "checkAudioLevel": true
            ]),
            ("fitnessCheck", "fitness-custom", "Fitness", [
                "walkDuration": 20,
                "restDuration": 20
            ]),
            ("holePegTest", "hole-peg-custom", "Hole Peg", [
                "dominantHand": "right",
                "numberOfPegs": 9,
                "threshold": 0.2,
                "rotated": false,
                "timeLimit": 300
            ]),
            ("psat", "psat-custom", "PSAT", [
                "presentationMode": 2,
                "interStimulusInterval": 3,
                "stimulusDuration": 1,
                "seriesLength": 60
            ]),
            ("reactionTime", "reaction-custom", "Reaction", [
                "maximumStimulusInterval": 10,
                "minimumStimulusInterval": 4,
                "thresholdAcceleration": 0.5,
                "numberOfAttempts": 3,
                "timeout": 3,
                "successSoundResourceName": "tap",
                "successSoundResourceExtension": "aif",
                "timeoutSoundID": 0,
                "failureSoundID": 0
            ]),
            ("shortWalk", "short-walk-custom", "Short Walk", [
                "numberOfStepsPerLeg": 20,
                "restDuration": 20
            ]),
            ("spatialSpanMemory", "spatial-custom", "Spatial", [
                "initialSpan": 3,
                "minimumSpan": 2,
                "maximumSpan": 15,
                "playSpeed": 1,
                "maximumTests": 5,
                "maximumConsecutiveFailures": 3,
                "requireReversal": false
            ]),
            ("speechRecognition", "speech-recognition-custom", "Speech Recognition", [
                "speechRecognizerLocale": "en-US",
                "speechRecognitionText": researchKitLocalized("A quick brown fox jumps over the lazy dog."),
                "shouldHideTranscript": false,
                "allowsEdittingTranscript": true
            ]),
            ("speechInNoise", "speech-noise-custom", "Speech Noise", [:]),
            ("stroop", "stroop-custom", "Stroop", ["numberOfAttempts": 10]),
            ("timedWalk", "timed-walk-custom", "Timed Walk", [
                "distanceInMeters": 100,
                "timeLimit": 180,
                "turnAroundTimeLimit": 60,
                "includeAssistiveDeviceForm": true
            ]),
            ("toneAudiometry", "tone-custom", "Tone", ["toneDuration": 20]),
            ("dBHLToneAudiometry", "dbhl-tone-custom", "DBHL Tone", [:]),
            ("amslerGrid", "amsler-custom", "Amsler", [:]),
            ("towerOfHanoi", "hanoi-custom", "Hanoi", ["numberOfDisks": 5]),
            ("twoFingerTappingInterval", "tapping-custom", "Two Finger Tapping", [
                "duration": 10,
                "handOption": "both"
            ]),
            ("walkBackAndForth", "walk-back-custom", "Walk Back", [
                "walkDuration": 30,
                "restDuration": 30
            ]),
            (
                "tremorTest",
                "tremor-custom",
                "Tremor",
                [
                    "activeStepDuration": 10,
                    "exclusions": ["handInLap", "queenWave"],
                    "handOption": "left"
                ]
            ),
            ("kneeRangeOfMotion", "knee-custom", "Knee", ["limb": "left"]),
            ("shoulderRangeOfMotion", "shoulder-custom", "Shoulder", ["limb": "right"]),
            ("trailMaking", "trail-custom", "Trail", ["trailType": "B"]),
            ("landoltCVisualAcuity", "visual-acuity-custom", "Visual Acuity", [:]),
            ("landoltCContrastSensitivity", "contrast-custom", "Contrast", [:]),
            ("navigableOrderedTask", "nav-custom", "Navigable", [
                "steps": [
                    [
                        "instruction": [
                            "identifier": "nav-intro",
                            "title": researchKitLocalized("Intro"),
                            "text": researchKitLocalized("Start"),
                            "detailText": researchKitLocalized("Details")
                        ]
                    ],
                    [
                        "completion": [
                            "identifier": "nav-done",
                            "title": researchKitLocalized("Done"),
                            "detailText": researchKitLocalized("Finished")
                        ]
                    ]
                ],
                "skipRules": [
                    [
                        "stepIdentifier": "nav-intro",
                        "resultSelector": "nav-intro",
                        "predicate": "TRUEPREDICATE",
                        "destinationStepIdentifier": "nav-done"
                    ]
                ]
            ])
        ]

        for testCase in cases {
            var payload = testCase.extraValues
            payload["identifier"] = testCase.identifier
            payload["title"] = researchKitLocalized(testCase.title)

            let taskType = try researchKitDecodeJSON(ResearchKitTaskType.self, from: [
                testCase.key: payload
            ])
            let task = taskType.task

            #expect(task.identifier == testCase.identifier)
        }
    }

    @Test("Static task options expose stable ids and descriptions")
    func staticTaskOptionsExposeStableIdsAndDescriptions() {
        let cases: [(StaticTaskOption, String, String)] = [
            (.form, "form", "Form Survey Example"),
            (.groupedForm, "groupedForm", "Grouped Form Survey Example"),
            (.survey, "survey", "Simple Survey Example"),
            (.booleanQuestion, "booleanQuestion", "Boolean Question"),
            (.customBooleanQuestion, "customBooleanQuestion", "Custom Boolean Question"),
            (.dateQuestion, "dateQuestion", "Date Question"),
            (.dateTimeQuestion, "dateTimeQuestion", "Date and Time Question"),
            (.imageChoiceQuestion, "imageChoiceQuestion", "Image Choice Question"),
            (.locationQuestion, "locationQuestion", "Location Question"),
            (.numericQuestion, "numericQuestion", "Numeric Question"),
            (.scaleQuestion, "scaleQuestion", "Scale Question"),
            (.textQuestion, "textQuestion", "Text Question"),
            (.textChoiceQuestion, "textChoiceQuestion", "Text Choice Question"),
            (.timeIntervalQuestion, "timeIntervalQuestion", "Time Interval Question"),
            (.timeOfDayQuestion, "timeOfDayQuestion", "Time of Day Question"),
            (.valuePickerChoiceQuestion, "valuePickerChoiceQuestion", "Value Picker Choice Question"),
            (.validatedTextQuestion, "validatedTextQuestion", "Validated Text Question"),
            (.imageCapture, "imageCapture", "Image Capture Step"),
            (.videoCapture, "videoCapture", "Video Capture Step"),
            (.frontFacingCamera, "frontFacingCamera", "Front Facing Camera Step"),
            (.wait, "wait", "Wait Step"),
            (.PDFViewer, "PDFViewer", "PDF Viewer Step"),
            (.eligibilityTask, "eligibilityTask", "Eligibility Task Example"),
            (.consent, "consent", "Consent-Obtaining Example"),
            (.accountCreation, "accountCreation", "Account Creation"),
            (.login, "login", "Login"),
            (.passcode, "passcode", "Passcode Creation"),
            (.audio, "audio", "Audio"),
            (.amslerGrid, "amslerGrid", "Amsler Grid"),
            (.fitness, "fitness", "Fitness Check"),
            (.holePegTest, "holePegTest", "Hole Peg Test"),
            (.psat, "psat", "PSAT"),
            (.reactionTime, "reactionTime", "Reaction Time"),
            (.shortWalk, "shortWalk", "Short Walk"),
            (.spatialSpanMemory, "spatialSpanMemory", "Spatial Span Memory"),
            (.speechRecognition, "speechRecognition", "Speech Recognition"),
            (.speechInNoise, "speechInNoise", "Speech in Noise"),
            (.stroop, "stroop", "Stroop"),
            (.swiftStroop, "swiftStroop", "Swift Stroop"),
            (.timedWalkWithTurnAround, "timedWalkWithTurnAround", "Timed Walk with Turn Around"),
            (.toneAudiometry, "toneAudiometry", "Tone Audiometry"),
            (.dBHLToneAudiometry, "dBHLToneAudiometry", "dBHL Tone Audiometry"),
            (.splMeter, "splMeter", "Environment SPL Meter"),
            (.towerOfHanoi, "towerOfHanoi", "Tower of Hanoi"),
            (.twoFingerTappingInterval, "twoFingerTappingInterval", "Two Finger Tapping Interval"),
            (.walkBackAndForth, "walkBackAndForth", "Walk Back and Forth"),
            (.kneeRangeOfMotion, "kneeRangeOfMotion", "Knee Range of Motion"),
            (.shoulderRangeOfMotion, "shoulderRangeOfMotion", "Shoulder Range of Motion"),
            (.trailMaking, "trailMaking", "Trail Making Test"),
            (.visualAcuityLandoltC, "visualAcuityLandoltC", "Visual Acuity Landolt C"),
            (.contrastSensitivityPeakLandoltC, "contrastSensitivityPeakLandoltC", "Contrast Sensitivity Peak"),
            (.videoInstruction, "videoInstruction", "Video Instruction Task"),
            (.webView, "webView", "Web View")
        ]

        for (option, id, description) in cases {
            #expect(option.id == id)
            #expect(option.rawValue == id)
            #expect(option.description == description)
        }
    }

    @Test("Static form and question options build expected ordered tasks")
    func staticFormAndQuestionOptionsBuildExpectedOrderedTasks() throws {
        let cases: [(option: StaticTaskOption, taskID: String, stepIDs: [String])] = [
            (.form, "formTask", ["formStep", "CompletionStep"]),
            (.groupedForm, "groupedFormTask", ["groupedFormStep", "questionStep", "birthdayQuestion", "appleFormStepIdentifier"]),
            (.survey, "surveyTask", ["introStep", "questionStep", "birthdayQuestion", "summaryStep"]),
            (.booleanQuestion, "booleanQuestionTask", ["booleanQuestionStep"]),
            (.customBooleanQuestion, "booleanQuestionTask", ["booleanQuestionStep"]),
            (.dateQuestion, "dateQuestionTask", ["dateQuestionStep"]),
            (.dateTimeQuestion, "dateTimeQuestionTask", ["dateTimeQuestionStep"]),
            (.locationQuestion, "locationQuestionTask", ["locationQuestionStep"]),
            (.numericQuestion, "numericQuestionTask", ["numericQuestionStep", "numericNoUnitQuestionStep"]),
            (.scaleQuestion, "scaleQuestionTask", [
                "discreteScaleQuestionStep",
                "continuousScaleQuestionStep",
                "discreteVerticalScaleQuestionStep",
                "continuousVerticalScaleQuestionStep",
                "textScaleQuestionStep",
                "textVerticalScaleQuestionStep"
            ]),
            (.textQuestion, "textQuestionTask", ["textQuestionStep"]),
            (.textChoiceQuestion, "textChoiceQuestionTask", ["textChoiceQuestionStep"]),
            (.timeIntervalQuestion, "timeIntervalQuestionTask", ["timeIntervalQuestionStep"]),
            (.timeOfDayQuestion, "timeOfDayQuestionTask", ["timeOfDayQuestionStep"]),
            (.valuePickerChoiceQuestion, "valuePickerChoiceQuestionTask", ["valuePickerChoiceQuestionStep"]),
            (.validatedTextQuestion, "validatedTextQuestionTask", ["validatedTextQuestionStepEmail", "validatedTextQuestionStepDomain"])
        ]

        for testCase in cases {
            let task = try #require(testCase.option.representedTask as? ORKOrderedTask)
            #expect(task.identifier == testCase.taskID)
            #expect(task.steps.map(\.identifier) == testCase.stepIDs)
        }
    }

    @Test("Static form task preserves expected form item structure")
    func staticFormTaskPreservesExpectedFormItemStructure() throws {
        let task = try #require(StaticTaskOption.form.representedTask as? ORKOrderedTask)
        let formStep = try #require(task.steps.first as? ORKFormStep)
        let formItems = try #require(formStep.formItems)

        #expect(formItems.map(\.identifier) == [
            "appleFormItemIdentifier",
            "formItem03",
            "formItem04",
            "formItem01",
            "formItem02"
        ])
        #expect(formItems.first?.text == "Which is your favorite apple?")
        #expect(formItems.last?.placeholder == "Your placeholder here")
    }

    @Test("Static account and eligibility options build expected ordered tasks")
    func staticAccountAndEligibilityOptionsBuildExpectedOrderedTasks() throws {
        let cases: [(option: StaticTaskOption, taskID: String, stepIDs: [String])] = [
            (.eligibilityTask, "eligibilityTask", [
                "eligibilityIntroStep",
                "eligibilityFormStep",
                "eligibilityIneligibleStep",
                "eligibilityEligibleStep"
            ]),
            (.accountCreation, "accountCreationTask", ["registrationStep", "waitStep", "verificationStep"]),
            (.login, "loginTask", ["loginStep", "loginWaitStep"]),
            (.passcode, "passcodeTask", ["passcodeStep"])
        ]

        for testCase in cases {
            let task = try #require(testCase.option.representedTask as? ORKOrderedTask)
            #expect(task.identifier == testCase.taskID)
            #expect(task.steps.map(\.identifier) == testCase.stepIDs)
        }
    }

    @Test("Static eligibility task preserves required form items")
    func staticEligibilityTaskPreservesRequiredFormItems() throws {
        let task = try #require(StaticTaskOption.eligibilityTask.representedTask as? ORKOrderedTask)
        let formStep = try #require(task.steps.first { $0.identifier == "eligibilityFormStep" } as? ORKFormStep)
        let formItems = try #require(formStep.formItems)

        #expect(formStep.isOptional == false)
        #expect(formItems.map(\.identifier) == [
            "eligibilityFormItem01",
            "eligibilityFormItem02",
            "eligibilityFormItem03"
        ])
        #expect(formItems.allSatisfy { $0.isOptional == false })
    }

    @Test("Static image and video capture options build expected ordered tasks")
    func staticImageAndVideoCaptureOptionsBuildExpectedOrderedTasks() throws {
        let imageTask = try #require(StaticTaskOption.imageCapture.representedTask as? ORKOrderedTask)
        let imageIntroStep = try #require(imageTask.steps.first as? ORKInstructionStep)
        let imageCaptureStep = try #require(imageTask.steps.last as? ORKImageCaptureStep)

        #expect(imageTask.identifier == "imageCaptureTask")
        #expect(imageTask.steps.map(\.identifier) == ["introStep", "imageCaptureStep"])
        #expect(imageIntroStep.title == "Image Capture Survey")
        #expect(imageIntroStep.image != nil)
        #expect(imageCaptureStep.title == "Image Capture")
        #expect(imageCaptureStep.isOptional == false)
        #expect(imageCaptureStep.templateImageInsets == UIEdgeInsets(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05))
        #expect(imageCaptureStep.accessibilityInstructions == "Your instructions for capturing the image")
        #expect(imageCaptureStep.accessibilityHint == "Captures the image visible in the preview")

        let videoTask = try #require(StaticTaskOption.videoCapture.representedTask as? ORKOrderedTask)
        let videoIntroStep = try #require(videoTask.steps.first as? ORKInstructionStep)
        let videoCaptureStep = try #require(videoTask.steps.last as? ORKVideoCaptureStep)

        #expect(videoTask.identifier == "videoCaptureTask")
        #expect(videoTask.steps.map(\.identifier) == ["introStep", "videoCaptureStep"])
        #expect(videoIntroStep.title == "Video Capture Survey")
        #expect(videoIntroStep.image != nil)
        #expect(videoCaptureStep.title == "Video Capture")
        #expect(videoCaptureStep.duration == 30.0)
        #expect(videoCaptureStep.templateImageInsets == UIEdgeInsets(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05))
        #expect(videoCaptureStep.accessibilityInstructions == "Your instructions for capturing the video")
        #expect(videoCaptureStep.accessibilityHint == "Captures the video visible in the preview")
    }

    @Test("Static image choice task preserves image choice answer formats")
    func staticImageChoiceTaskPreservesImageChoiceAnswerFormats() throws {
        let task = try #require(StaticTaskOption.imageChoiceQuestion.representedTask as? ORKOrderedTask)
        let firstStep = try #require(task.steps.first as? ORKQuestionStep)
        let secondStep = try #require(task.steps.last as? ORKQuestionStep)
        let firstFormat = try #require(firstStep.answerFormat as? ORKImageChoiceAnswerFormat)
        let secondFormat = try #require(secondStep.answerFormat as? ORKImageChoiceAnswerFormat)

        #expect(task.identifier == "imageChoiceQuestionTask")
        #expect(task.steps.map(\.identifier) == ["imageChoiceQuestionStep1", "imageChoiceQuestionStep2"])
        #expect(firstStep.title == "Image Choice")
        #expect(firstFormat.imageChoices.map(\.text) == ["Round Shape", "Square Shape"])
        #expect(firstFormat.style == .singleChoice)
        #expect(firstFormat.isVertical == false)
        #expect(secondFormat.imageChoices.map(\.text) == ["Round Shape", "Square Shape"])
        #expect(secondFormat.style == .singleChoice)
        #expect(secondFormat.isVertical)
    }

    @Test("Static camera and video instruction tasks preserve configured step metadata")
    func staticCameraAndVideoInstructionTasksPreserveConfiguredStepMetadata() throws {
        let cameraTask = try #require(StaticTaskOption.frontFacingCamera.representedTask as? ORKOrderedTask)
        let cameraStep = try #require(cameraTask.steps.first as? ORKFrontFacingCameraStep)

        #expect(cameraTask.identifier == "videoInstructionTask")
        #expect(cameraTask.steps.map(\.identifier) == ["frontFacingCameraStep"])
        #expect(cameraStep.title == "Front Facing Camera Step")
        #expect(cameraStep.text == "Your text goes here.")
        #expect(cameraStep.maximumRecordingLimit == 30.0)
        #expect(cameraStep.allowsRetry)
        #expect(cameraStep.allowsReview)

        let videoInstructionTask = try #require(StaticTaskOption.videoInstruction.representedTask as? ORKOrderedTask)
        let videoInstructionStep = try #require(videoInstructionTask.steps.first as? ORKVideoInstructionStep)

        #expect(videoInstructionTask.identifier == "videoInstructionTask")
        #expect(videoInstructionTask.steps.map(\.identifier) == ["videoInstructionStep"])
        #expect(videoInstructionStep.title == "Video Instruction Step")
        #expect(videoInstructionStep.thumbnailTime == 2)
        #expect(videoInstructionStep.videoURL?.absoluteString == "https://www.apple.com/media/us/researchkit/2016/a63aa7d4_e6fd_483f_a59d_d962016c8093/films/carekit/researchkit-carekit-cc-us-20160321_r848-9dwc.mov")
    }

    @Test("Static miscellaneous tasks preserve wait PDF and web view structure")
    func staticMiscellaneousTasksPreserveWaitPDFAndWebViewStructure() throws {
        let waitTask = try #require(StaticTaskOption.wait.representedTask as? ORKOrderedTask)
        let waitSteps = waitTask.steps.compactMap { $0 as? ORKWaitStep }

        #expect(waitTask.identifier == "waitTask")
        #expect(waitTask.steps.map(\.identifier) == ["waitStepIndeterminate", "waitStepDeterminate"])
        #expect(waitSteps.map(\.indicatorType) == [.indeterminate, .progressBar])
        #expect(waitSteps.allSatisfy { $0.title == "Wait Step" })

        let pdfTask = try #require(StaticTaskOption.PDFViewer.representedTask as? ORKOrderedTask)
        let pdfStep = try #require(pdfTask.steps.first as? ORKPDFViewerStep)

        #expect(pdfTask.identifier == "pdfViewerTask")
        #expect(pdfTask.steps.map(\.identifier) == ["pdfViewerStep"])
        #expect(pdfStep.title == "PDF Step")

        let webTask = try #require(StaticTaskOption.webView.representedTask as? ORKOrderedTask)
        let webStep = try #require(webTask.steps.first as? ORKWebViewStep)

        #expect(webTask.identifier == "webViewTask")
        #expect(webTask.steps.map(\.identifier) == ["webViewStep"])
        #expect(webStep.title == "Web View")
        #expect(webStep.showSignatureAfterContent)
    }
}
