/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import Foundation
import OTFResearchKit
import Testing
@testable import OTFMagicBox

@Suite("ResearchKit YAML step construction")
struct ResearchKitYMLStepConstructionTests {
    @Test("YAML step configurations decode and build ORK steps")
    func yamlStepConfigurationsDecodeAndBuildORKSteps() throws {
        let cases: [(key: String, identifier: String, expectedStepType: ORKStep.Type, extraValues: [String: Any])] = [
            ("question", "question-custom", ORKQuestionStep.self, [
                "title": localized("Question"),
                "question": localized("Continue?"),
                "text": localized("Choose one."),
                "answer": [
                    "boolean": [
                        "yesString": localized("Yes"),
                        "noString": localized("No")
                    ]
                ]
            ]),
            ("instruction", "instruction-custom", ORKInstructionStep.self, [
                "title": localized("Instruction"),
                "text": localized("Read first."),
                "detailText": localized("More detail.")
            ]),
            ("form", "form-custom", ORKFormStep.self, [
                "title": localized("Form"),
                "text": localized("Answer these."),
                "items": [
                    [
                        "identifier": "form-item",
                        "text": localized("How many?"),
                        "answer": ["integer": ["unit": localized("steps")]]
                    ]
                ]
            ]),
            ("completion", "completion-custom", ORKCompletionStep.self, [
                "title": localized("Complete"),
                "detailText": localized("All done.")
            ]),
            ("registration", "registration-custom", ORKRegistrationStep.self, [
                "title": localized("Register"),
                "text": localized("Create account."),
                "passcodeValidationRegex": "^[0-9]{4}$",
                "passcodeInvalidMessage": localized("Use four digits."),
                "phoneValidationRegex": "^\\+[0-9]+$",
                "phoneInvalidMessage": localized("Use international format."),
                "options": ["givenName", "familyName", "phoneNumber"]
            ]),
            ("wait", "wait-custom", ORKWaitStep.self, [
                "title": localized("Wait"),
                "text": localized("Syncing."),
                "indicator": "progressBar"
            ]),
            ("imageCapture", "image-custom", ORKImageCaptureStep.self, [
                "title": localized("Image"),
                "isOptional": true,
                "accessibilityInstructions": localized("Align."),
                "accessibilityHint": localized("Capture.")
            ]),
            ("videoCapture", "video-custom", ORKVideoCaptureStep.self, [
                "title": localized("Video"),
                "isOptional": true,
                "accessibilityInstructions": localized("Hold steady."),
                "accessibilityHint": localized("Record."),
                "duration": 12,
                "audioMute": true,
                "torchMode": "off",
                "devicePosition": "front"
            ]),
            ("frontFacingCamera", "front-custom", ORKFrontFacingCameraStep.self, [
                "title": localized("Front Camera"),
                "text": localized("Read aloud."),
                "maximumRecordingLimit": 8,
                "allowsRetry": false,
                "allowsReview": false
            ]),
            ("videoInstruction", "video-instruction-custom", ORKVideoInstructionStep.self, [
                "title": localized("Watch"),
                "videoURLString": "https://example.com/guide.mov",
                "thumbnailTime": 4
            ]),
            ("verification", "verification-custom", ORKVerificationStep.self, [
                "title": localized("Verify"),
                "text": localized("Check email.")
            ]),
            ("login", "login-custom", ORKLoginStep.self, [
                "title": localized("Login"),
                "text": localized("Sign in.")
            ]),
            ("pdfViewer", "pdf-custom", ORKPDFViewerStep.self, [
                "title": localized("PDF"),
                "pdfURLString": "https://example.com/consent.pdf"
            ]),
            ("webView", "web-custom", ORKWebViewStep.self, [
                "title": localized("Web"),
                "html": "<p>Hello</p>",
                "customCSS": "p { font-weight: bold; }",
                "showSignatureAfterContent": false
            ]),
            ("passcode", "passcode-custom", ORKPasscodeStep.self, [
                "title": localized("Passcode"),
                "text": localized("Create passcode."),
                "flow": "authenticate",
                "type": "fourDigit",
                "useBiometrics": false
            ]),
            ("consentSharing", "sharing-custom", ORKConsentSharingStep.self, [
                "investigatorShortDescription": localized("Clinic"),
                "investigatorLongDescription": localized("Clinic and partners"),
                "learnMoreHTML": localized("<p>Learn more</p>")
            ]),
            ("visualConsent", "visual-consent-custom", ORKVisualConsentStep.self, [
                "documentTitle": localized("Consent"),
                "signaturePageTitle": localized("Signature"),
                "signaturePageContent": localized("Please sign."),
                "sectionTitle": localized("Overview"),
                "sectionSummary": localized("Study summary."),
                "sectionHTMLContent": localized("<p>Summary</p>")
            ]),
            ("consentReview", "review-custom", ORKConsentReviewStep.self, [
                "title": localized("Review"),
                "text": localized("Review terms."),
                "reasonForConsent": localized("I agree."),
                "requiresScrollToBottom": false,
                "documentTitle": localized("Document"),
                "signaturePageTitle": localized("Signature"),
                "signaturePageContent": localized("Sign here."),
                "participantTitle": localized("Participant"),
                "participantSignatureIdentifier": "participant-signature"
            ]),
            ("swiftStroop", "stroop-step-custom", ORKSwiftStroopStep.self, [
                "title": localized("Stroop"),
                "text": localized("Pick the color."),
                "spokenInstruction": localized("Pick the color."),
                "numberOfAttempts": 6
            ]),
            ("environmentSPLMeter", "spl-custom", ORKEnvironmentSPLMeterStep.self, [
                "title": localized("Noise"),
                "text": localized("Find a quiet space."),
                "thresholdValue": 55,
                "samplingInterval": 1.5,
                "requiredContiguousSamples": 4
            ])
        ]

        for testCase in cases {
            var payload = testCase.extraValues
            payload["identifier"] = testCase.identifier

            let stepType = try decodeStepJSON(ResearchKitStep.self, from: [
                testCase.key: payload
            ])
            let step = stepType.step

            #expect(step.identifier == testCase.identifier)
            #expect(type(of: step) == testCase.expectedStepType)
        }
    }

    @Test("Consent and passcode configurations preserve important ORK properties")
    func consentAndPasscodeConfigurationsPreserveImportantORKProperties() {
        let sharing = ConsentSharingStepConfiguration(
            identifier: "sharing",
            investigatorShortDescription: "Clinic",
            investigatorLongDescription: "Clinic research team",
            learnMoreHTML: "<p>Data sharing</p>"
        ).step
        let visual = VisualConsentStepConfiguration(
            identifier: "visual",
            documentTitle: "Consent Document",
            signaturePageTitle: "Signature",
            signaturePageContent: "Please sign.",
            sectionTitle: "Overview",
            sectionSummary: "Study summary.",
            sectionHTMLContent: "<p>Summary</p>"
        ).step
        let review = ConsentReviewStepConfiguration(
            identifier: "review",
            title: "Review",
            text: "Read before signing.",
            reasonForConsent: "I agree.",
            requiresScrollToBottom: false,
            documentTitle: "Review Document",
            signaturePageTitle: "Review Signature",
            signaturePageContent: "Signature copy.",
            participantTitle: "Participant",
            participantSignatureIdentifier: "signature-id"
        ).step
        let passcode = PasscodeStepConfiguration(
            identifier: "passcode",
            title: "Passcode",
            text: "Authenticate.",
            flow: .authenticate,
            type: .fourDigit,
            useBiometrics: false
        ).step

        #expect(sharing.identifier == "sharing")
        #expect(visual.identifier == "visual")
        #expect(review.identifier == "review")
        #expect(review.title == "Review")
        #expect(review.text == "Read before signing.")
        #expect(review.reasonForConsent == "I agree.")
        #expect(review.requiresScrollToBottom == false)
        #expect(passcode.identifier == "passcode")
        #expect(passcode.title == "Passcode")
        #expect(passcode.text == "Authenticate.")
        #expect(passcode.passcodeFlow == .authenticate)
        #expect(passcode.passcodeType == .type4Digit)
        #expect(passcode.useBiometrics == false)
        #expect(PasscodeFlow.allCases.map(\.ork) == [.create, .authenticate, .edit])
        #expect(PasscodeType.allCases.map(\.ork) == [.type4Digit, .type6Digit])
    }
}

private func decodeStepJSON<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

private func localized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}
