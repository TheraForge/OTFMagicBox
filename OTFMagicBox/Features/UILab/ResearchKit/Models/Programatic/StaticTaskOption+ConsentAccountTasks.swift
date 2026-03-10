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
 specific prior written permission. No license is granted to the trademarks of the
 copyright holders even if such marks are included in this software.

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
    /// A task demonstrating how the ResearchKit framework can be used to obtain informed consent.
    var consentTask: ORKTask {
        // Visual consent (animated sequence)
        let visualConsentStep = ORKVisualConsentStep(
            identifier: "visualConsentStep",
            document: consentDocument
        )

        // Optional data sharing agreement
        let sharingConsentStep = ORKConsentSharingStep(
            identifier: "consentSharingStep",
            investigatorShortDescription: "Institution",
            investigatorLongDescription: "Institution and its partners",
            localizedLearnMoreHTMLContent: "Your sharing learn more content here."
        )

        // Consent review (reads the consent document and collects participant signature)
        let signature = consentDocument.signatures!.first
        let reviewConsentStep = ORKConsentReviewStep(
            identifier: "consentReviewStep",
            signature: signature,
            in: consentDocument
        )
        reviewConsentStep.requiresScrollToBottom = true
        reviewConsentStep.title = "Consent Document"
        reviewConsentStep.text = loremIpsumText
        reviewConsentStep.reasonForConsent = loremIpsumText

        return ORKOrderedTask(
            identifier: "consentTask",
            steps: [visualConsentStep, sharingConsentStep, reviewConsentStep]
        )
    }

    /// This task presents the Account Creation process.
    var accountCreationTask: ORKTask {
        // Registration
        let passcodeValidationRegexPattern = "^(?=.*\\d).{4,8}$"
        let passcodeValidationRegularExpression = try? NSRegularExpression(pattern: passcodeValidationRegexPattern)
        let registrationOptions: ORKRegistrationStepOption = [
            .includeGivenName, .includeFamilyName, .includeGender, .includeDOB, .includePhoneNumber
        ]
        let registrationStep = ORKRegistrationStep(
            identifier: "registrationStep",
            title: "Registration",
            text: exampleDetailText,
            passcodeValidationRegularExpression: passcodeValidationRegularExpression,
            passcodeInvalidMessage: "A valid password must be 4 to 8 characters long and include at least one numeric character.",
            options: registrationOptions
        )
        registrationStep.phoneNumberValidationRegularExpression = try? NSRegularExpression(
            pattern: "^[+]{1,1}[1]{1,1}\\s{1,1}[(]{1,1}[1-9]{3,3}[)]{1,1}\\s{1,1}[1-9]{3,3}\\s{1,1}[1-9]{4,4}$"
        )
        registrationStep.phoneNumberInvalidMessage = "Expected format +1 (555) 5555 5555"

        // Wait (server-side work)
        let waitStep = ORKWaitStep(identifier: "waitStep")
        waitStep.title = "Creating account"
        waitStep.text = "Please wait while we upload your data"

        // Verification VC
        class VerificationViewController: ORKVerificationStepViewController {
            override func resendEmailButtonTapped() {
                let alert = UIAlertController(
                    title: "Resend Verification Email",
                    message: "Button tapped",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        let verificationStep = ORKVerificationStep(
            identifier: "verificationStep",
            text: exampleDetailText,
            verificationViewControllerClass: VerificationViewController.self
        )
        return ORKOrderedTask(
            identifier: "accountCreationTask",
            steps: [registrationStep, waitStep, verificationStep]
        )
    }

    /// This tasks presents the login step.
    var loginTask: ORKTask {
        class LoginViewController: ORKLoginStepViewController {
            override func forgotPasswordButtonTapped() {
                let alert = UIAlertController(
                    title: "Forgot password?",
                    message: "Button tapped",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }

        let loginStep = ORKLoginStep(
            identifier: "loginStep",
            title: "Login",
            text: exampleDetailText,
            loginViewControllerClass: LoginViewController.self
        )

        let waitStep = ORKWaitStep(identifier: "loginWaitStep")
        waitStep.title = "Logging in"
        waitStep.text = "Please wait while we validate your credentials"

        return ORKOrderedTask(
            identifier: "loginTask",
            steps: [loginStep, waitStep]
        )
    }

    /// This task demonstrates the Passcode creation process.
    var passcodeTask: ORKTask {
        let passcodeConsentStep = ORKPasscodeStep(identifier: "passcodeStep")
        passcodeConsentStep.title = "Passcode"
        return ORKOrderedTask(
            identifier: "passcodeTask",
            steps: [passcodeConsentStep]
        )
    }

    var eligibilityTask: ORKTask {
        // Intro step
        let introStep = ORKInstructionStep(identifier: "eligibilityIntroStep")
        introStep.title = "Eligibility Task"
        introStep.text = exampleDescription
        introStep.detailText =
            "Please use this space to provide instructions for participants. Please make sure to provide enough information so that users can progress through the survey and complete with ease."

        // Form step
        let formStep = ORKFormStep(identifier: "eligibilityFormStep")
        formStep.title = "Eligibility"
        formStep.isOptional = false

        // Form items
        let textChoices: [ORKTextChoice] = [
            ORKTextChoice(text: "Yes", value: "Yes" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "No", value: "No" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "N/A", value: "N/A" as NSCoding & NSCopying & NSObjectProtocol)
        ]
        let answerFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: textChoices)

        let formItem01 = ORKFormItem(
            identifier: "eligibilityFormItem01",
            text: "Your question goes here.",
            answerFormat: answerFormat
        )
        formItem01.isOptional = false

        let formItem02 = ORKFormItem(
            identifier: "eligibilityFormItem02",
            text: "Your question goes here.",
            answerFormat: answerFormat
        )
        formItem02.isOptional = false

        let formItem03 = ORKFormItem(
            identifier: "eligibilityFormItem03",
            text: "Your question goes here.",
            answerFormat: answerFormat
        )
        formItem03.isOptional = false

        formStep.formItems = [formItem01, formItem02, formItem03]

        // Ineligible step
        let ineligibleStep = ORKInstructionStep(identifier: "eligibilityIneligibleStep")
        ineligibleStep.title = "Eligibility Result"
        ineligibleStep.detailText = "You are ineligible to join the study"

        // Eligible step
        let eligibleStep = ORKCompletionStep(identifier: "eligibilityEligibleStep")
        eligibleStep.title = "Eligibility Result"
        eligibleStep.detailText = "You are eligible to join the study"

        // Create the task
        let eligibilityTask = ORKNavigableOrderedTask(
            identifier: "eligibilityTask",
            steps: [introStep, formStep, ineligibleStep, eligibleStep]
        )

        let predicateEligible = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                ORKResultPredicate.predicateForChoiceQuestionResult(
                    with: ORKResultSelector(
                        stepIdentifier: "eligibilityFormStep",
                        resultIdentifier: "eligibilityFormItem01"
                    ),
                    expectedAnswerValue: "Yes" as NSCoding & NSCopying & NSObjectProtocol
                ),
                ORKResultPredicate.predicateForChoiceQuestionResult(
                    with: ORKResultSelector(
                        stepIdentifier: "eligibilityFormStep",
                        resultIdentifier: "eligibilityFormItem02"
                    ),
                    expectedAnswerValue: "Yes" as NSCoding & NSCopying & NSObjectProtocol
                ),
                ORKResultPredicate.predicateForChoiceQuestionResult(
                    with: ORKResultSelector(
                        stepIdentifier: "eligibilityFormStep",
                        resultIdentifier: "eligibilityFormItem03"
                    ),
                    expectedAnswerValue: "No" as NSCoding & NSCopying & NSObjectProtocol
                )
            ]
        )
        let predicateRule = ORKPredicateStepNavigationRule(
            resultPredicatesAndDestinationStepIdentifiers: [(predicateEligible, "eligibilityEligibleStep")]
        )
        eligibilityTask.setNavigationRule(predicateRule, forTriggerStepIdentifier: "eligibilityFormStep")
        // Add end direct rules to skip unneeded steps
        eligibilityTask.setNavigationRule(ORKDirectStepNavigationRule(destinationStepIdentifier: ORKNullStepIdentifier), forTriggerStepIdentifier: "eligibilityIneligibleStep")

        return eligibilityTask
    }

    /**
     A consent document provides the content for the visual consent and consent
     review steps. This helper sets up a consent document with some dummy content.
     */
    var consentDocument: ORKConsentDocument {
        let consentDocument = ORKConsentDocument()
        consentDocument.title = "Example Consent"
        consentDocument.signaturePageTitle = "Consent"
        consentDocument.signaturePageContent = "I agree to participate in this research study."

        // Participant signature (collected during review)
        let participantSignature = ORKConsentSignature(
            forPersonWithTitle: "Participant",
            dateFormatString: nil,
            identifier: "consentDocumentParticipantSignature"
        )
        consentDocument.addSignature(participantSignature)

        // Investigator signature (appears in generated PDF only)
        let signatureImage = UIImage(named: "signature")!
        let investigatorSignature = ORKConsentSignature(
            forPersonWithTitle: "Investigator",
            dateFormatString: nil,
            identifier: "consentDocumentInvestigatorSignature",
            givenName: "Jonny",
            familyName: "Appleseed",
            signatureImage: signatureImage,
            dateString: "3/10/15"
        )
        consentDocument.addSignature(investigatorSignature)

        let htmlContentString = "<ul><li>Lorem</li><li>ipsum</li><li>dolor</li></ul><p>\(loremIpsumLongText)</p><p>\(loremIpsumMediumText)</p>"

        let consentSectionTypes: [ORKConsentSectionType] = [
            .overview,
            .dataGathering,
            .privacy,
            .dataUse,
            .timeCommitment,
            .studySurvey,
            .studyTasks,
            .withdrawing
        ]

        var consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
            let consentSection = ORKConsentSection(type: contentSectionType)
            consentSection.summary = loremIpsumShortText
            if contentSectionType == .overview {
                consentSection.htmlContent = htmlContentString
            } else {
                consentSection.content = loremIpsumLongText
            }
            return consentSection
        }

        // Section only in the review document/PDF
        let onlyInDocSection = ORKConsentSection(type: .onlyInDocument)
        onlyInDocSection.summary = ".OnlyInDocument Scene Summary"
        onlyInDocSection.title = ".OnlyInDocument Scene"
        onlyInDocSection.content = loremIpsumLongText
        consentSections += [onlyInDocSection]

        consentDocument.sections = consentSections
        return consentDocument
    }
}
