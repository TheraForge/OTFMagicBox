/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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
import AVFoundation
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct VideoCaptureStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized

    // Common step properties
    var isOptional: Bool

    // Accessibility guidance
    var accessibilityInstructions: OTFStringLocalized?
    var accessibilityHint: OTFStringLocalized?

    // Template overlay image and insets (fractions 0.0...1.0)
    var templateImageName: String?
    var templateImageInsets: EdgeInsetsFraction?

    // Video-specific
    // Duration in seconds (ResearchKit caps to 20 minutes)
    var duration: Double?
    // If true, record video without audio
    var audioMute: Bool?
    // Desired torch mode
    var torchMode: VideoCaptureStepConfiguration.TorchMode?
    // Desired camera position
    var devicePosition: VideoCaptureStepConfiguration.DevicePosition?
}

// MARK: - Codable enum bridges for AVFoundation types
extension VideoCaptureStepConfiguration {
    enum TorchMode: String, Codable {
        case off, on, auto

        var avTorchMode: AVCaptureDevice.TorchMode {
            switch self {
            case .off: return .off
            case .on: return .on
            case .auto: return .auto
            }
        }
    }

    enum DevicePosition: String, Codable {
        case back, front, unspecified

        var avPosition: AVCaptureDevice.Position {
            switch self {
            case .back: return .back
            case .front: return .front
            case .unspecified: return .unspecified
            }
        }
    }
}

// MARK: - Raw bridge
extension VideoCaptureStepConfiguration {

    init(from raw: RawVideoCaptureStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.isOptional = raw.isOptional ?? fb.isOptional
        self.accessibilityInstructions = raw.accessibilityInstructions ?? fb.accessibilityInstructions
        self.accessibilityHint = raw.accessibilityHint ?? fb.accessibilityHint
        self.templateImageName = raw.templateImageName ?? fb.templateImageName
        self.templateImageInsets = raw.templateImageInsets ?? fb.templateImageInsets
        self.duration = raw.duration ?? fb.duration
        self.audioMute = raw.audioMute ?? fb.audioMute
        self.torchMode = raw.torchMode ?? fb.torchMode
        self.devicePosition = raw.devicePosition ?? fb.devicePosition
    }

    var step: ORKVideoCaptureStep {
        let step = ORKVideoCaptureStep(identifier: identifier)
        step.title = title.localized
        step.isOptional = isOptional

        if let instructions = accessibilityInstructions?.localized {
            step.accessibilityInstructions = instructions
        }
        if let hint = accessibilityHint?.localized {
            step.accessibilityHint = hint
        }

        if let name = templateImageName, let image = UIImage(named: name) {
            step.templateImage = image
        }
        if let insets = templateImageInsets?.uiEdgeInsets {
            step.templateImageInsets = insets
        }

        if let duration {
            step.duration = NSNumber(value: duration)
        }
        if let audioMute {
            step.isAudioMute = audioMute
        }
        if let torchMode {
            step.torchMode = torchMode.avTorchMode
        }
        if let devicePosition {
            step.devicePosition = devicePosition.avPosition
        }

        return step
    }
}

// MARK: - Defaults
extension VideoCaptureStepConfiguration {
    static let fallback = VideoCaptureStepConfiguration(
        identifier: "videoCaptureStep",
        title: "Video Capture",
        isOptional: false,
        accessibilityInstructions: "Your instructions for capturing the video",
        accessibilityHint: "Captures the video visible in the preview",
        templateImageName: "hand_outline_big",
        templateImageInsets: EdgeInsetsFraction(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05),
        duration: 30.0,
        audioMute: false,
        torchMode: .auto,
        devicePosition: .back
    )
}

// MARK: - Preview
#Preview {
    TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "videoCapture", steps: [VideoCaptureStepConfiguration.fallback.step]))
}
