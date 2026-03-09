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
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct ImageCaptureStepConfiguration: Codable {
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
}

extension ImageCaptureStepConfiguration {

    init(from raw: RawImageCaptureStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.isOptional = raw.isOptional ?? fb.isOptional
        self.accessibilityInstructions = raw.accessibilityInstructions ?? fb.accessibilityInstructions
        self.accessibilityHint = raw.accessibilityHint ?? fb.accessibilityHint
        self.templateImageName = raw.templateImageName ?? fb.templateImageName
        self.templateImageInsets = raw.templateImageInsets ?? fb.templateImageInsets
    }

    var step: ORKImageCaptureStep {
        let step = ORKImageCaptureStep(identifier: identifier)
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

        return step
    }
}

extension ImageCaptureStepConfiguration {
    static let fallback = ImageCaptureStepConfiguration(
        identifier: "imageCaptureStep",
        title: "Image Capture",
        isOptional: false,
        accessibilityInstructions: "Your instructions for capturing the image",
        accessibilityHint: "Captures the image visible in the preview",
        templateImageName: "hand_outline_big",
        templateImageInsets: EdgeInsetsFraction(top: 0.05, left: 0.05, bottom: 0.05, right: 0.05)
    )
}

// MARK: - Codable edge insets bridge
@RawGenerable
struct EdgeInsetsFraction: Codable {
    var top: Double
    var left: Double
    var bottom: Double
    var right: Double

    var uiEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}

#Preview {
    let step = ImageCaptureStepConfiguration.fallback.step
    return TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "imageCapture", steps: [step]))
}
