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

extension StaticTaskOption {
    /// This task presents the image capture step in an ordered task.
    var imageCaptureTask: ORKTask {
        // Intro step
        let instructionStep = ORKInstructionStep(identifier: "introStep")
        instructionStep.title = "Image Capture Survey"
        instructionStep.text = exampleDescription
        let handSolidImage = UIImage(named: "hand_solid")!
        instructionStep.image = handSolidImage.withRenderingMode(.alwaysTemplate)

        // Image capture step
        let imageCaptureStep = ORKImageCaptureStep(identifier: "imageCaptureStep")
        imageCaptureStep.title = "Image Capture"
        imageCaptureStep.isOptional = false
        imageCaptureStep.accessibilityInstructions = "Your instructions for capturing the image"
        imageCaptureStep.accessibilityHint = "Captures the image visible in the preview"
        imageCaptureStep.templateImage = UIImage(named: "hand_outline_big")!
        imageCaptureStep.templateImageInsets = UIEdgeInsets(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05)

        return ORKOrderedTask(
            identifier: "imageCaptureTask",
            steps: [instructionStep, imageCaptureStep]
        )
    }

    /// This task presents the video capture step in an ordered task.
    var videoCaptureTask: ORKTask {
        // Intro step
        let instructionStep = ORKInstructionStep(identifier: "introStep")
        instructionStep.title = "Video Capture Survey"
        instructionStep.text = exampleDescription
        let handSolidImage = UIImage(named: "hand_solid")!
        instructionStep.image = handSolidImage.withRenderingMode(.alwaysTemplate)

        // Video capture step
        let videoCaptureStep = ORKVideoCaptureStep(identifier: "videoCaptureStep")
        videoCaptureStep.title = "Video Capture"
        videoCaptureStep.accessibilityInstructions = "Your instructions for capturing the video"
        videoCaptureStep.accessibilityHint = "Captures the video visible in the preview"
        videoCaptureStep.templateImage = UIImage(named: "hand_outline_big")!
        videoCaptureStep.templateImageInsets = UIEdgeInsets(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05)
        videoCaptureStep.duration = 30.0 // 30 seconds

        return ORKOrderedTask(
            identifier: "videoCaptureTask",
            steps: [instructionStep, videoCaptureStep]
        )
    }

    /**
     This task demonstrates a survey question involving picking from a series of
     image choices. A more realistic application might use a range of icons
     for faces ranging from happy to sad.
     */
    var imageChoiceQuestionTask: ORKTask {
        let roundShapeImage = UIImage(named: "round_shape")!
        let squareShapeImage = UIImage(named: "square_shape")!

        let roundShapeText = "Round Shape"
        let squareShapeText = "Square Shape"

        let imageChoces = [
            ORKImageChoice(
                normalImage: roundShapeImage,
                selectedImage: nil,
                text: roundShapeText,
                value: roundShapeText as NSCoding & NSCopying & NSObjectProtocol
            ),
            ORKImageChoice(
                normalImage: squareShapeImage,
                selectedImage: nil,
                text: squareShapeText,
                value: squareShapeText as NSCoding & NSCopying & NSObjectProtocol
            )
        ]

        let answerFormat1 = ORKAnswerFormat.choiceAnswerFormat(with: imageChoces)
        let questionStep1 = ORKQuestionStep(
            identifier: "imageChoiceQuestionStep1",
            title: "Image Choice",
            question: "Your question goes here.",
            answer: answerFormat1
        )
        questionStep1.text = exampleDetailText

        let answerFormat2 = ORKAnswerFormat.choiceAnswerFormat(with: imageChoces, style: .singleChoice, vertical: true)
        let questionStep2 = ORKQuestionStep(
            identifier: "imageChoiceQuestionStep2",
            title: "Image Choice",
            question: "Your question goes here.",
            answer: answerFormat2
        )
        questionStep2.text = exampleDetailText

        return ORKOrderedTask(
            identifier: "imageChoiceQuestionTask",
            steps: [questionStep1, questionStep2]
        )
    }

    /// This task presents a video instruction step
    var frontFacingCameraStep: ORKTask {
        let frontFacingCameraStep = ORKFrontFacingCameraStep(identifier: "frontFacingCameraStep")
        frontFacingCameraStep.maximumRecordingLimit = 30.0
        frontFacingCameraStep.title = "Front Facing Camera Step"
        frontFacingCameraStep.text = "Your text goes here."
        frontFacingCameraStep.allowsRetry = true
        frontFacingCameraStep.allowsReview = true

        return ORKOrderedTask(
            identifier: "videoInstructionTask",
            steps: [frontFacingCameraStep]
        )
    }

    /// This task presents a video instruction step
    var videoInstruction: ORKTask {
        let videoInstructionStep = ORKVideoInstructionStep(identifier: "videoInstructionStep")
        videoInstructionStep.title = "Video Instruction Step"
        videoInstructionStep.videoURL = URL(string: "https://www.apple.com/media/us/researchkit/2016/a63aa7d4_e6fd_483f_a59d_d962016c8093/films/carekit/researchkit-carekit-cc-us-20160321_r848-9dwc.mov")
        videoInstructionStep.thumbnailTime = 2 // Customizable thumbnail timestamp
        return ORKOrderedTask(
            identifier: "videoInstructionTask",
            steps: [videoInstructionStep]
        )
    }
}
