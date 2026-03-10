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
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct StroopStepConfiguration: Codable {

    var identifier: String
    var title: OTFStringLocalized
    var text: OTFStringLocalized?
    var spokenInstruction: OTFStringLocalized?
    var numberOfAttempts: Int

}

extension StroopStepConfiguration {

    init(from raw: RawStroopStepConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.text = raw.text ?? Self.fallback.text
        self.spokenInstruction = raw.spokenInstruction ?? Self.fallback.spokenInstruction
        self.numberOfAttempts = raw.numberOfAttempts ?? Self.fallback.numberOfAttempts
    }

    var step: ORKSwiftStroopStep {
        let step = ORKSwiftStroopStep(identifier: identifier)
        step.title = title.localized
        if let text {
            step.text = text.localized
        }
        if let spokenInstruction {
            step.spokenInstruction = spokenInstruction.localized
        }
        step.numberOfAttempts = numberOfAttempts
        return step
    }
}

extension StroopStepConfiguration {

    static let fallback = StroopStepConfiguration(
        identifier: "stroopStep",
        title: "Stroop",
        text: "Select the first letter of the name of the COLOR that is shown.",
        spokenInstruction: "Select the first letter of the name of the COLOR that is shown.",
        numberOfAttempts: 10
    )
}

#Preview {
    let step = StroopStepConfiguration.fallback.step
    step.title = "Stroop Preview"
    return TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "stroopTask", steps: [step]))
}
