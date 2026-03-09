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
struct PasscodeStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized
    var text: OTFStringLocalized?

    var flow: PasscodeFlow
    var type: PasscodeType
    var useBiometrics: Bool
}

extension PasscodeStepConfiguration {

    init(from raw: RawPasscodeStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.text = raw.text ?? fb.text
        self.flow = raw.flow ?? fb.flow
        self.type = raw.type ?? fb.type
        self.useBiometrics = raw.useBiometrics ?? fb.useBiometrics
    }

    var step: ORKPasscodeStep {
        let step = ORKPasscodeStep(identifier: identifier)
        step.title = title.localized
        step.text = text?.localized
        step.passcodeFlow = flow.ork
        step.passcodeType = type.ork
        step.useBiometrics = useBiometrics
        return step
    }
}

extension PasscodeStepConfiguration {
    static let fallback = PasscodeStepConfiguration(
        identifier: "passcodeStep",
        title: "Passcode",
        text: "Create or enter your passcode.",
        flow: .create,
        type: .sixDigit,
        useBiometrics: true
    )
}

// MARK: - Mappings

@RawGenerable
enum PasscodeFlow: String, Codable, CaseIterable {
    case create
    case authenticate
    case edit

    var ork: ORKPasscodeFlow {
        switch self {
        case .create: return .create
        case .authenticate: return .authenticate
        case .edit: return .edit
        }
    }
}

@RawGenerable
enum PasscodeType: String, Codable, CaseIterable {
    case fourDigit
    case sixDigit

    var ork: ORKPasscodeType {
        switch self {
        case .fourDigit: return .type4Digit
        case .sixDigit: return .type6Digit
        }
    }
}

#Preview {
    TaskViewControllerRepresentable(
        task: ORKOrderedTask(identifier: "passcodeTask", steps: [PasscodeStepConfiguration.fallback.step])
    )
}
