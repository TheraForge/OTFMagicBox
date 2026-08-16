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

import AVFoundation
import Foundation
import OTFResearchKit
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("ResearchKit step construction")
struct ResearchKitStepConstructionTests {
    @Test("Media step configurations build ORK capture and instruction steps")
    func mediaStepConfigurationsBuildORKCaptureAndInstructionSteps() {
        let insets = EdgeInsetsFraction(top: 0.1, left: 0.2, bottom: 0.3, right: 0.4)
        let imageConfiguration = ImageCaptureStepConfiguration(
            identifier: "customImage",
            title: "Custom Image",
            isOptional: true,
            accessibilityInstructions: "Align the hand",
            accessibilityHint: "Tap capture",
            templateImageName: "hand_outline_big",
            templateImageInsets: insets
        )
        let videoConfiguration = VideoCaptureStepConfiguration(
            identifier: "customVideo",
            title: "Custom Video",
            isOptional: true,
            accessibilityInstructions: "Hold steady",
            accessibilityHint: "Tap record",
            templateImageName: "hand_outline_big",
            templateImageInsets: insets,
            duration: 42.5,
            audioMute: true,
            torchMode: .on,
            devicePosition: .front
        )
        let frontCameraConfiguration = FrontFacingCameraStepConfiguration(
            identifier: "frontCamera",
            title: "Face Recording",
            text: "Read the prompt.",
            maximumRecordingLimit: 12.0,
            allowsRetry: false,
            allowsReview: false
        )
        let videoInstructionConfiguration = VideoInstructionStepConfiguration(
            identifier: "videoInstruction",
            title: "Watch First",
            videoURLString: "https://example.com/instruction.mov",
            thumbnailTime: 7.8
        )

        let imageStep = imageConfiguration.step
        let videoStep = videoConfiguration.step
        let frontCameraStep = frontCameraConfiguration.step
        let videoInstructionStep = videoInstructionConfiguration.step

        #expect(insets.uiEdgeInsets == UIEdgeInsets(top: 0.1, left: 0.2, bottom: 0.3, right: 0.4))
        #expect(imageStep.identifier == "customImage")
        #expect(imageStep.title == "Custom Image")
        #expect(imageStep.isOptional)
        #expect(imageStep.accessibilityInstructions == "Align the hand")
        #expect(imageStep.accessibilityHint == "Tap capture")
        #expect(imageStep.templateImageInsets == insets.uiEdgeInsets)

        #expect(videoStep.identifier == "customVideo")
        #expect(videoStep.title == "Custom Video")
        #expect(videoStep.isOptional)
        #expect(videoStep.accessibilityInstructions == "Hold steady")
        #expect(videoStep.accessibilityHint == "Tap record")
        #expect(videoStep.templateImageInsets == insets.uiEdgeInsets)
        #expect(videoStep.duration.doubleValue == 42.5)
        #expect(videoStep.isAudioMute)
        #expect(videoStep.torchMode == .on)
        #expect(videoStep.devicePosition == .front)

        #expect(frontCameraStep.identifier == "frontCamera")
        #expect(frontCameraStep.title == "Face Recording")
        #expect(frontCameraStep.text == "Read the prompt.")
        #expect(frontCameraStep.maximumRecordingLimit == 12.0)
        #expect(frontCameraStep.allowsRetry == false)
        #expect(frontCameraStep.allowsReview == false)

        #expect(videoInstructionStep.identifier == "videoInstruction")
        #expect(videoInstructionStep.title == "Watch First")
        #expect(videoInstructionStep.videoURL?.absoluteString == "https://example.com/instruction.mov")
        #expect(videoInstructionStep.thumbnailTime == 7)
    }

    @Test("Video capture enum bridges map to AVFoundation values")
    func videoCaptureEnumBridgesMapToAVFoundationValues() {
        #expect(VideoCaptureStepConfiguration.TorchMode.off.avTorchMode == .off)
        #expect(VideoCaptureStepConfiguration.TorchMode.on.avTorchMode == .on)
        #expect(VideoCaptureStepConfiguration.TorchMode.auto.avTorchMode == .auto)
        #expect(VideoCaptureStepConfiguration.DevicePosition.back.avPosition == .back)
        #expect(VideoCaptureStepConfiguration.DevicePosition.front.avPosition == .front)
        #expect(VideoCaptureStepConfiguration.DevicePosition.unspecified.avPosition == .unspecified)
    }

    @Test("Miscellaneous step configurations build wait PDF and web steps")
    func miscellaneousStepConfigurationsBuildWaitPDFAndWebSteps() {
        let waitConfiguration = WaitStepConfiguration(
            identifier: "waitForSync",
            title: "Syncing",
            text: "Almost there.",
            indicator: .indeterminate
        )
        let pdfConfiguration = PDFViewerStepConfiguration(
            identifier: "terms",
            title: "Terms",
            pdfURLString: "https://example.com/terms.pdf"
        )
        let webConfiguration = WebViewStepConfiguration(
            identifier: "webConsent",
            title: "Consent",
            html: "<html><body>Consent</body></html>",
            customCSS: "body { color: red; }",
            showSignatureAfterContent: false
        )

        let waitStep = waitConfiguration.step
        let pdfStep = pdfConfiguration.step
        let webStep = webConfiguration.step

        #expect(waitStep.identifier == "waitForSync")
        #expect(waitStep.title == "Syncing")
        #expect(waitStep.text == "Almost there.")
        #expect(waitStep.indicatorType == .indeterminate)
        #expect(ProgressIndicatorConfiguration.progressBar.orkType == .progressBar)

        #expect(pdfStep.identifier == "terms")
        #expect(pdfStep.title == "Terms")
        #expect(pdfStep.pdfURL?.absoluteString == "https://example.com/terms.pdf")

        #expect(webStep.identifier == "webConsent")
        #expect(webStep.title == "Consent")
        #expect(webStep.html == "<html><body>Consent</body></html>")
        #expect(webStep.customCSS == "body { color: red; }")
        #expect(webStep.showSignatureAfterContent == false)
    }

    @Test("YAML visual and cognitive task configurations build ordered tasks")
    func yamlVisualAndCognitiveTaskConfigurationsBuildOrderedTasks() throws {
        let cases: [(task: ORKTask, identifier: String)] = [
            (
                AmslerGridTaskConfiguration(
                    identifier: "customAmsler",
                    title: "Amsler Grid"
                ).task,
                "customAmsler"
            ),
            (
                TrailMakingTaskConfiguration(
                    identifier: "customTrail",
                    title: "Trail Making",
                    trailmakingInstruction: "Connect the circles.",
                    trailType: .A
                ).task,
                "customTrail"
            ),
            (
                LandoltCVisualAcuityTaskConfiguration(
                    identifier: "customAcuity",
                    title: "Acuity"
                ).task,
                "customAcuity"
            ),
            (
                LandoltCContrastSensitivityTaskConfiguration(
                    identifier: "customContrast",
                    title: "Contrast"
                ).task,
                "customContrast"
            )
        ]

        #expect(TrailMakingType.A.ork == ORKTrailMakingTypeIdentifier.A)
        #expect(TrailMakingType.B.ork == ORKTrailMakingTypeIdentifier.B)

        for testCase in cases {
            let orderedTask = try #require(testCase.task as? ORKOrderedTask)
            #expect(orderedTask.identifier == testCase.identifier)
            #expect(orderedTask.steps.isEmpty == false)
        }
    }

    @Test("Instruction step configuration builds ORK instruction step")
    func instructionStepConfigurationBuildsORKInstructionStep() {
        let configuration = InstructionStepConfiguration(
            identifier: "intro",
            title: "Welcome",
            text: "Before we begin",
            detailText: "Find a quiet place."
        )

        let step = configuration.step

        #expect(step.identifier == "intro")
        #expect(step.title == "Welcome")
        #expect(step.text == "Before we begin")
        #expect(step.detailText == "Find a quiet place.")
    }

    @Test("Question step configuration builds ORK question step with answer and learn more")
    func questionStepConfigurationBuildsORKQuestionStep() throws {
        let configuration = QuestionStepConfiguration(
            identifier: "newsletter",
            title: "Newsletter",
            question: "Subscribe?",
            text: "We send monthly updates.",
            answer: .boolean(BooleanAnswerFormatConfiguration(
                yesString: "Yes please",
                noString: "No thanks"
            )),
            learnMore: LearnMoreItemConfiguration(
                learnMoreIdentifier: "newsletter-info",
                learnMoreTitle: "About updates",
                learnMoreText: "You can unsubscribe anytime.",
                text: "Learn more"
            )
        )

        let step = configuration.step
        let answer = try #require(step.answerFormat as? ORKBooleanAnswerFormat)
        let learnMore = try #require(step.learnMoreItem)

        #expect(step.identifier == "newsletter")
        #expect(step.title == "Newsletter")
        #expect(step.question == "Subscribe?")
        #expect(step.text == "We send monthly updates.")
        #expect(answer.yes == "Yes please")
        #expect(answer.no == "No thanks")
        #expect(learnMore.text == "Learn more")
        #expect(learnMore.learnMoreInstructionStep.identifier == "newsletter-info")
        #expect(learnMore.learnMoreInstructionStep.title == "About updates")
        #expect(learnMore.learnMoreInstructionStep.text == "You can unsubscribe anytime.")
    }

    @Test("Ordered task configuration builds ORK ordered task with configured steps")
    func orderedTaskConfigurationBuildsORKOrderedTask() throws {
        let intro = ResearchKitStep.instruction(InstructionStepConfiguration(
            identifier: "intro",
            title: "Intro",
            text: "Start here",
            detailText: "Read carefully."
        ))
        let done = ResearchKitStep.completion(CompletionStepConfiguration(
            identifier: "done",
            title: "Done",
            detailText: "All set."
        ))
        let configuration = OrderedTaskConfiguration(identifier: "survey", steps: [intro, done])

        let task = try #require(configuration.task as? ORKOrderedTask)

        #expect(task.identifier == "survey")
        #expect(task.steps.map { $0.identifier } == ["intro", "done"])
        #expect(task.steps.first is ORKInstructionStep)
        #expect(task.steps.last is ORKCompletionStep)
    }
}
