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

import RawModel
import OTFResearchKit

@RawGenerable
enum ResearchKitStep: Codable {
    case question(QuestionStepConfiguration)
    case instruction(InstructionStepConfiguration)
    case form(FormStepConfiguration)
    case completion(CompletionStepConfiguration)
    case registration(RegistrationStepConfiguration)
    case wait(WaitStepConfiguration)
    case imageCapture(ImageCaptureStepConfiguration)
    case videoCapture(VideoCaptureStepConfiguration)
    case frontFacingCamera(FrontFacingCameraStepConfiguration)
    case videoInstruction(VideoInstructionStepConfiguration)
    case verification(VerificationStepConfiguration)
    case login(LoginStepConfiguration)
    case pdfViewer(PDFViewerStepConfiguration)
    case webView(WebViewStepConfiguration)
    case passcode(PasscodeStepConfiguration)
    case consentSharing(ConsentSharingStepConfiguration)
    case visualConsent(VisualConsentStepConfiguration)
    case consentReview(ConsentReviewStepConfiguration)
    case swiftStroop(StroopStepConfiguration)
    case environmentSPLMeter(EnvironmentSPLMeterStepConfiguration)

    private enum CaseKey: String, CodingKey {
        case question
        case instruction
        case form
        case completion
        case registration
        case wait
        case imageCapture
        case videoCapture
        case frontFacingCamera
        case videoInstruction
        case verification
        case login
        case pdfViewer
        case webView
        case passcode
        case consentSharing
        case visualConsent
        case consentReview
        case swiftStroop
        case environmentSPLMeter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CaseKey.self)
        let keys = container.allKeys
        guard keys.count == 1, let key = keys.first else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: container.codingPath,
                debugDescription: "Expected exactly one StaticResearchKitStep key, found \(keys.count)"
            ))
        }
        switch key {
        case .question:
            self = .question(try container.decode(QuestionStepConfiguration.self, forKey: .question))
        case .instruction:
            self = .instruction(try container.decode(InstructionStepConfiguration.self, forKey: .instruction))
        case .form:
            self = .form(try container.decode(FormStepConfiguration.self, forKey: .form))
        case .completion:
            self = .completion(try container.decode(CompletionStepConfiguration.self, forKey: .completion))
        case .registration:
            self = .registration(try container.decode(RegistrationStepConfiguration.self, forKey: .registration))
        case .wait:
            self = .wait(try container.decode(WaitStepConfiguration.self, forKey: .wait))
        case .imageCapture:
            self = .imageCapture(try container.decode(ImageCaptureStepConfiguration.self, forKey: .imageCapture))
        case .videoCapture:
            self = .videoCapture(try container.decode(VideoCaptureStepConfiguration.self, forKey: .videoCapture))
        case .frontFacingCamera:
            self = .frontFacingCamera(try container.decode(FrontFacingCameraStepConfiguration.self, forKey: .frontFacingCamera))
        case .videoInstruction:
            self = .videoInstruction(try container.decode(VideoInstructionStepConfiguration.self, forKey: .videoInstruction))
        case .verification:
            self = .verification(try container.decode(VerificationStepConfiguration.self, forKey: .verification))
        case .login:
            self = .login(try container.decode(LoginStepConfiguration.self, forKey: .login))
        case .pdfViewer:
            self = .pdfViewer(try container.decode(PDFViewerStepConfiguration.self, forKey: .pdfViewer))
        case .webView:
            self = .webView(try container.decode(WebViewStepConfiguration.self, forKey: .webView))
        case .passcode:
            self = .passcode(try container.decode(PasscodeStepConfiguration.self, forKey: .passcode))
        case .consentSharing:
            self = .consentSharing(try container.decode(ConsentSharingStepConfiguration.self, forKey: .consentSharing))
        case .visualConsent:
            self = .visualConsent(try container.decode(VisualConsentStepConfiguration.self, forKey: .visualConsent))
        case .consentReview:
            self = .consentReview(try container.decode(ConsentReviewStepConfiguration.self, forKey: .consentReview))
        case .swiftStroop:
            self = .swiftStroop(try container.decode(StroopStepConfiguration.self, forKey: .swiftStroop))
        case .environmentSPLMeter:
            self = .environmentSPLMeter(try container.decode(EnvironmentSPLMeterStepConfiguration.self, forKey: .environmentSPLMeter))
        }
    }

    static let fallback = ResearchKitStep.question(.fallback)
}

// MARK: - Step representation
extension ResearchKitStep {

    var step: ORKStep {

        switch self {

        case .question(let configuration):
            configuration.step
        case .instruction(let configuration):
            configuration.step
        case .form(let configuration):
            configuration.step
        case .completion(let configuration):
            configuration.step
        case .registration(let configuration):
            configuration.step
        case .wait(let configuration):
            configuration.step
        case .imageCapture(let configuration):
            configuration.step
        case .videoCapture(let configuration):
            configuration.step
        case .frontFacingCamera(let configuration):
            configuration.step
        case .videoInstruction(let configuration):
            configuration.step
        case .verification(let configuration):
            configuration.step
        case .login(let configuration):
            configuration.step
        case .pdfViewer(let configuration):
            configuration.step
        case .webView(let configuration):
            configuration.step
        case .passcode(let configuration):
            configuration.step
        case .consentSharing(let configuration):
            configuration.step
        case .visualConsent(let configuration):
            configuration.step
        case .consentReview(let configuration):
            configuration.step
        case .swiftStroop(let configuration):
            configuration.step
        case .environmentSPLMeter(let configuration):
            configuration.step
        }
    }
}
