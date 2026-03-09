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
struct RegistrationStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized
    var text: OTFStringLocalized

    // Passcode validation
    var passcodeValidationRegex: String?
    var passcodeInvalidMessage: OTFStringLocalized?

    // Phone number validation
    var phoneValidationRegex: String?
    var phoneInvalidMessage: OTFStringLocalized?

    // Registration fields to include beyond email/password
    var options: [RegistrationOption]
}

extension RegistrationStepConfiguration {

    init(from raw: RawRegistrationStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.text = raw.text ?? fb.text

        self.passcodeValidationRegex = raw.passcodeValidationRegex ?? fb.passcodeValidationRegex
        self.passcodeInvalidMessage = raw.passcodeInvalidMessage ?? fb.passcodeInvalidMessage

        self.phoneValidationRegex = raw.phoneValidationRegex ?? fb.phoneValidationRegex
        self.phoneInvalidMessage = raw.phoneInvalidMessage ?? fb.phoneInvalidMessage

        self.options = raw.options ?? fb.options
    }

    var step: ORKRegistrationStep {
        let passcodeRegex: NSRegularExpression?
        if let pattern = passcodeValidationRegex, !pattern.isEmpty {
            passcodeRegex = try? NSRegularExpression(pattern: pattern)
        } else {
            passcodeRegex = nil
        }

        let step = ORKRegistrationStep(
            identifier: identifier,
            title: title.localized,
            text: text.localized,
            passcodeValidationRegularExpression: passcodeRegex,
            passcodeInvalidMessage: passcodeInvalidMessage?.localized,
            options: options.orkOptions
        )

        if let phonePattern = phoneValidationRegex, !phonePattern.isEmpty {
            step.phoneNumberValidationRegularExpression = try? NSRegularExpression(pattern: phonePattern)
        }
        if let phoneInvalid = phoneInvalidMessage?.localized {
            step.phoneNumberInvalidMessage = phoneInvalid
        }

        return step
    }
}

extension RegistrationStepConfiguration {

    static let fallback = RegistrationStepConfiguration(
        identifier: "registrationStep",
        title: "Registration",
        text: "Create your account to continue.",
        passcodeValidationRegex: "^(?=.*\\d).{4,8}$",
        passcodeInvalidMessage: "A valid password must be 4 to 8 characters long and include at least one numeric character.",
        phoneValidationRegex: "^[+]{1,1}[1]{1,1}\\s{1,1}[(]{1,1}[1-9]{3,3}[)]{1,1}\\s{1,1}[1-9]{3,3}\\s{1,1}[1-9]{4,4}$",
        phoneInvalidMessage: "Expected format +1 (555) 5555 5555",
        options: [.givenName, .familyName, .gender, .dob, .phoneNumber]
    )
}

// MARK: - Registration options mapping

@RawGenerable
enum RegistrationOption: String, Codable, CaseIterable {
    case givenName
    case familyName
    case gender
    case dob
    case phoneNumber
}

private extension Array where Element == RegistrationOption {
    var orkOptions: ORKRegistrationStepOption {
        var opts: ORKRegistrationStepOption = []
        for option in self {
            switch option {
            case .givenName:
                opts.insert(.includeGivenName)
            case .familyName:
                opts.insert(.includeFamilyName)
            case .gender:
                opts.insert(.includeGender)
            case .dob:
                opts.insert(.includeDOB)
            case .phoneNumber:
                opts.insert(.includePhoneNumber)
            }
        }
        return opts
    }
}

#Preview {
    TaskViewControllerRepresentable(
        task: ORKOrderedTask(
            identifier: "registration",
            steps: [RegistrationStepConfiguration.fallback.step]
        )
    )
}
