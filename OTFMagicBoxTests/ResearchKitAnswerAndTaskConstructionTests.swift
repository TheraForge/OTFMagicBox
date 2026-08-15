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
@testable import OTFMagicBox

@Suite("ResearchKit answer and task construction")
struct ResearchKitAnswerAndTaskConstructionTests {
    @Test("YAML answer types build location time of day and socio economic formats")
    func yamlAnswerTypesBuildRemainingPureFormats() throws {
        let location = try decodeResearchKitJSON(ResearchKitAnswerType.self, from: [
            "location": [:]
        ])
        let timeOfDay = try decodeResearchKitJSON(ResearchKitAnswerType.self, from: [
            "timeOfDay": [
                "minuteInterval": 15
            ]
        ])
        let socioEconomic = try decodeResearchKitJSON(ResearchKitAnswerType.self, from: [
            "socioEconomic": [
                "topRungText": localizedResearchKitText("Most resources"),
                "bottomRungText": localizedResearchKitText("Fewest resources")
            ]
        ])

        let locationFormat = try #require(location.answerFormat as? ORKLocationAnswerFormat)
        let timeFormat = try #require(timeOfDay.answerFormat as? ORKTimeOfDayAnswerFormat)
        let sesFormat = try #require(socioEconomic.answerFormat as? ORKSESAnswerFormat)

        #expect(type(of: locationFormat) == ORKLocationAnswerFormat.self)
        #expect(timeFormat.minuteInterval == 15)
        #expect(sesFormat.topRungText == "Most resources")
        #expect(sesFormat.bottomRungText == "Fewest resources")
    }

    @Test("Consent visual sharing and review configurations build configured ORK steps")
    func consentConfigurationsBuildConfiguredSteps() throws {
        let visual = VisualConsentStepConfiguration(
            identifier: "visual-consent",
            documentTitle: "Study Consent",
            signaturePageTitle: "Signature",
            signaturePageContent: "I agree to join.",
            sectionTitle: "Overview",
            sectionSummary: "How your data is used.",
            sectionHTMLContent: "<p>Details</p>"
        ).step
        let sharing = ConsentSharingStepConfiguration(
            identifier: "sharing",
            investigatorShortDescription: "Clinic",
            investigatorLongDescription: "Clinic and partners",
            learnMoreHTML: "<p>Sharing details</p>"
        ).step
        let review = ConsentReviewStepConfiguration(
            identifier: "review",
            title: "Review Consent",
            text: "Please review before signing.",
            reasonForConsent: "I agree.",
            requiresScrollToBottom: false,
            documentTitle: "Review Document",
            signaturePageTitle: "Review Signature",
            signaturePageContent: "Signature content.",
            participantTitle: "Patient",
            participantSignatureIdentifier: "patient-signature"
        ).step

        let visualDocument = try #require(visual.consentDocument)
        let visualSections = try #require(visualDocument.sections)
        let visualSection = try #require(visualSections.first)
        let reviewSignature = try #require(review.signature)

        #expect(visual.identifier == "visual-consent")
        #expect(visualDocument.title == "Study Consent")
        #expect(visualDocument.signaturePageTitle == "Signature")
        #expect(visualDocument.signaturePageContent == "I agree to join.")
        #expect(visualSection.type == ORKConsentSectionType.overview)
        #expect(visualSection.title == "Overview")
        #expect(visualSection.summary == "How your data is used.")
        #expect(visualSection.htmlContent == "<p>Details</p>")

        #expect(sharing.identifier == "sharing")
        #expect(sharing.localizedLearnMoreHTMLContent == "<p>Sharing details</p>")

        #expect(review.identifier == "review")
        #expect(review.title == "Review Consent")
        #expect(review.text == "Please review before signing.")
        #expect(review.reasonForConsent == "I agree.")
        #expect(review.requiresScrollToBottom == false)
        #expect(review.consentDocument.title == "Review Document")
        #expect(reviewSignature.identifier == "patient-signature")
        #expect(reviewSignature.title == "Patient")
    }

    @Test("Registration configuration maps options and validation without presenting UI")
    func registrationConfigurationMapsOptionsAndValidation() {
        let configured = RegistrationStepConfiguration(
            identifier: "register",
            title: "Create Account",
            text: "Tell us about you.",
            passcodeValidationRegex: #"^\d{6}$"#,
            passcodeInvalidMessage: "Use six digits.",
            phoneValidationRegex: #"^\+\d+$"#,
            phoneInvalidMessage: "Use international format.",
            options: [.givenName, .phoneNumber]
        ).step
        let invalidRegex = RegistrationStepConfiguration(
            identifier: "register-invalid",
            title: "Create Account",
            text: "Tell us about you.",
            passcodeValidationRegex: "[",
            passcodeInvalidMessage: "Invalid passcode.",
            phoneValidationRegex: "",
            phoneInvalidMessage: nil,
            options: [.familyName, .gender, .dob]
        ).step

        #expect(configured.identifier == "register")
        #expect(configured.title == "Create Account")
        #expect(configured.text == "Tell us about you.")
        #expect(configured.options.contains(.includeGivenName))
        #expect(configured.options.contains(.includePhoneNumber))
        #expect(!configured.options.contains(.includeFamilyName))
        #expect(configured.passcodeValidationRegularExpression?.pattern == #"^\d{6}$"#)
        #expect(configured.passcodeInvalidMessage == "Use six digits.")
        #expect(configured.phoneNumberValidationRegularExpression?.pattern == #"^\+\d+$"#)
        #expect(configured.phoneNumberInvalidMessage == "Use international format.")

        #expect(invalidRegex.passcodeValidationRegularExpression == nil)
        #expect(invalidRegex.phoneNumberValidationRegularExpression == nil)
        #expect(invalidRegex.options.contains(.includeFamilyName))
        #expect(invalidRegex.options.contains(.includeGender))
        #expect(invalidRegex.options.contains(.includeDOB))
    }

    @Test("Login verification and passcode configurations preserve controller and passcode metadata")
    func loginVerificationAndPasscodeConfigurationsBuildSteps() {
        let login = LoginStepConfiguration(
            identifier: "login",
            title: "Sign In",
            text: "Use your study account."
        ).step
        let verification = VerificationStepConfiguration(
            identifier: "verify",
            title: "Check Email",
            text: "Open the link we sent."
        ).step
        let passcode = PasscodeStepConfiguration(
            identifier: "passcode",
            title: "Unlock",
            text: "Enter your passcode.",
            flow: .authenticate,
            type: .fourDigit,
            useBiometrics: false
        ).step

        #expect(login.identifier == "login")
        #expect(login.title == "Sign In")
        #expect(login.text == "Use your study account.")
        #expect(login.loginViewControllerClass == ORKLoginStepViewController.self)

        #expect(verification.identifier == "verify")
        #expect(verification.title == "Check Email")
        #expect(verification.text == "Open the link we sent.")
        #expect(verification.verificationViewControllerClass == ORKVerificationStepViewController.self)

        #expect(passcode.identifier == "passcode")
        #expect(passcode.title == "Unlock")
        #expect(passcode.text == "Enter your passcode.")
        #expect(passcode.passcodeFlow == .authenticate)
        #expect(passcode.passcodeType == .type4Digit)
        #expect(passcode.useBiometrics == false)
        #expect(PasscodeFlow.allCases.map(\.ork) == [.create, .authenticate, .edit])
        #expect(PasscodeType.allCases.map(\.ork) == [.type4Digit, .type6Digit])
    }

    @Test("YAML step enum builds consent account and sensor steps from one-key payloads")
    func yamlStepEnumBuildsConsentAccountAndSensorSteps() throws {
        let registration = try decodeResearchKitJSON(ResearchKitStep.self, from: [
            "registration": [
                "identifier": "registration",
                "title": localizedResearchKitText("Register"),
                "text": localizedResearchKitText("Create account"),
                "passcodeValidationRegex": #"^\d{4}$"#,
                "passcodeInvalidMessage": localizedResearchKitText("Use four digits."),
                "phoneValidationRegex": #"^\+\d+$"#,
                "phoneInvalidMessage": localizedResearchKitText("Use phone."),
                "options": ["givenName", "familyName"]
            ]
        ])
        let passcode = try decodeResearchKitJSON(ResearchKitStep.self, from: [
            "passcode": [
                "identifier": "passcode",
                "title": localizedResearchKitText("Passcode"),
                "text": localizedResearchKitText("Use it."),
                "flow": "edit",
                "type": "sixDigit",
                "useBiometrics": true
            ]
        ])
        let spl = try decodeResearchKitJSON(ResearchKitStep.self, from: [
            "environmentSPLMeter": [
                "identifier": "spl",
                "title": localizedResearchKitText("Sound"),
                "text": localizedResearchKitText("Measure sound."),
                "thresholdValue": 72.5,
                "samplingInterval": 1.5,
                "requiredContiguousSamples": 4
            ]
        ])

        let registrationStep = try #require(registration.step as? ORKRegistrationStep)
        let passcodeStep = try #require(passcode.step as? ORKPasscodeStep)
        let splStep = try #require(spl.step as? ORKEnvironmentSPLMeterStep)

        #expect(registrationStep.identifier == "registration")
        #expect(registrationStep.options.contains(.includeGivenName))
        #expect(registrationStep.options.contains(.includeFamilyName))
        #expect(passcodeStep.passcodeFlow == .edit)
        #expect(passcodeStep.passcodeType == .type6Digit)
        #expect(passcodeStep.useBiometrics)
        #expect(splStep.identifier == "spl")
        #expect(splStep.title == "Sound")
        #expect(splStep.thresholdValue == 72.5)
        #expect(splStep.samplingInterval == 1.5)
        #expect(splStep.requiredContiguousSamples == 4)
    }

    @Test("Navigable ordered task YAML preserves configured step ordering")
    func navigableOrderedTaskYAMLPreservesConfiguredStepOrdering() throws {
        let taskType = try decodeResearchKitJSON(ResearchKitTaskType.self, from: [
            "navigableOrderedTask": [
                "identifier": "navigation-survey",
                "steps": [
                    [
                        "instruction": [
                            "identifier": "intro",
                            "title": localizedResearchKitText("Intro"),
                            "text": localizedResearchKitText("Start"),
                            "detailText": localizedResearchKitText("Read first.")
                        ]
                    ],
                    [
                        "completion": [
                            "identifier": "done",
                            "title": localizedResearchKitText("Done"),
                            "detailText": localizedResearchKitText("Finished.")
                        ]
                    ]
                ]
            ]
        ])

        let task = try #require(taskType.task as? ORKNavigableOrderedTask)

        #expect(task.identifier == "navigation-survey")
        #expect(task.steps.map(\.identifier) == ["intro", "done"])
        #expect(task.steps.first is ORKInstructionStep)
        #expect(task.steps.last is ORKCompletionStep)
    }

    @Test("Static account creation task preserves registration verification and consent details")
    func staticAccountCreationTaskPreservesImportantDetails() throws {
        let accountTask = try #require(StaticTaskOption.accountCreation.representedTask as? ORKOrderedTask)
        let registration = try #require(accountTask.steps.first as? ORKRegistrationStep)
        let verification = try #require(accountTask.steps.last as? ORKVerificationStep)
        let consentTask = try #require(StaticTaskOption.consent.representedTask as? ORKOrderedTask)
        let visual = try #require(consentTask.steps.first as? ORKVisualConsentStep)
        let review = try #require(consentTask.steps.last as? ORKConsentReviewStep)

        #expect(registration.options.contains(.includeGivenName))
        #expect(registration.options.contains(.includeFamilyName))
        #expect(registration.options.contains(.includeGender))
        #expect(registration.options.contains(.includeDOB))
        #expect(registration.options.contains(.includePhoneNumber))
        #expect(registration.passcodeValidationRegularExpression?.pattern == "^(?=.*\\d).{4,8}$")
        #expect(registration.phoneNumberValidationRegularExpression?.pattern == "^[+]{1,1}[1]{1,1}\\s{1,1}[(]{1,1}[1-9]{3,3}[)]{1,1}\\s{1,1}[1-9]{3,3}\\s{1,1}[1-9]{4,4}$")
        #expect(verification.verificationViewControllerClass is ORKVerificationStepViewController.Type)

        #expect(visual.consentDocument?.title == "Example Consent")
        #expect(review.requiresScrollToBottom)
        #expect(review.title == "Consent Document")
        #expect(review.signature?.identifier == "consentDocumentParticipantSignature")
    }

    @Test("Static active task options build ordered tasks without presentation")
    func staticActiveTaskOptionsBuildOrderedTasksWithoutPresentation() throws {
        let cases: [(option: StaticTaskOption, taskID: String)] = [
            (.audio, "audioTask"),
            (.fitness, "fitnessTask"),
            (.holePegTest, "holePegTestTask"),
            (.psat, "psatTask"),
            (.reactionTime, "reactionTime"),
            (.shortWalk, "shortWalkTask"),
            (.spatialSpanMemory, "spatialSpanMemoryTask"),
            (.speechRecognition, "speechRecognitionTask"),
            (.speechInNoise, "speechInNoiseTask"),
            (.stroop, "stroopTask"),
            (.swiftStroop, "stroopTask"),
            (.timedWalkWithTurnAround, "timedWalkWithTurnAroundTask"),
            (.toneAudiometry, "toneAudiometryTask"),
            (.dBHLToneAudiometry, "dBHLToneAudiometryTask"),
            (.splMeter, "splMeterTask"),
            (.towerOfHanoi, "towerOfHanoi"),
            (.twoFingerTappingInterval, "twoFingerTappingIntervalTask"),
            (.walkBackAndForth, "walkBackAndForthTask"),
            (.tremorTest, "tremorTestTask"),
            (.kneeRangeOfMotion, "kneeRangeOfMotion"),
            (.shoulderRangeOfMotion, "shoulderRangeOfMotion"),
            (.trailMaking, "trailMaking"),
            (.visualAcuityLandoltC, "visualAcuityLandoltC"),
            (.contrastSensitivityPeakLandoltC, "contrastSensitivityPeakLandoltC")
        ]

        for testCase in cases {
            let task = try #require(testCase.option.representedTask as? ORKOrderedTask)
            #expect(task.identifier == testCase.taskID)
            #expect(!task.steps.isEmpty)
        }

        let swiftStroop = try #require(StaticTaskOption.swiftStroop.representedTask as? ORKOrderedTask)
        let stroopStep = try #require(swiftStroop.steps.first { $0.identifier == "stroopStep" } as? ORKSwiftStroopStep)
        let splTask = try #require(StaticTaskOption.splMeter.representedTask as? ORKOrderedTask)
        let splStep = try #require(splTask.steps.first as? ORKEnvironmentSPLMeterStep)

        #expect(swiftStroop.steps.map(\.identifier) == [
            "stroopInstructionStep",
            "stroopInstructionStep2",
            "stroopCountdownStep",
            "stroopStep",
            "stroopCompletionStep"
        ])
        #expect(stroopStep.numberOfAttempts == 10)
        #expect(splStep.thresholdValue == 60)
        #expect(splStep.samplingInterval == 2)
        #expect(splStep.requiredContiguousSamples == 10)
    }
}

private func decodeResearchKitJSON<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

private func localizedResearchKitText(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}
