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

import SwiftUI
import OTFResearchKit

enum AuthTaskNavigation {

    static func signInOptionsDefaultDestination(
        mode: AuthType,
        profileDetailsStepId: String?,
        shouldShowConsent: Bool,
        includesPasscodeStep: Bool
    ) -> String {
        if mode == .signup {
            // Social signup must arrive at either the optional profile-details step
            // or an authentication trigger. Preserve passcode setup when it exists.
            return profileDetailsStepId ?? (
                includesPasscodeStep ? Constants.Auth.passcodeStep : Constants.Auth.healthKitDataStep
            )
        }
        if shouldShowConsent {
            return Constants.Auth.visualConsentStep
        }
        return includesPasscodeStep ? Constants.Auth.passcodeStep : Constants.Auth.completionStep
    }
}

/// Use: AuthTaskRepresentable(mode: .signup) or .login
struct AuthTaskRepresentable: UIViewControllerRepresentable {

    let mode: AuthType
    private let userDefaults: UserDefaults = .standard
    private let config = AppConfigurationLoader.config
    private let auth = AuthConfigurationLoader.auth

    private var shouldShowConsent: Bool {
        mode == .login && !userDefaults.bool(forKey: Constants.Storage.kConsentDocumentViewed)
    }

    func makeCoordinator() -> AuthTaskCoordinator {
        AuthTaskCoordinator(authType: mode, appConfiguration: config)
    }

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        var steps: [ORKStep] = []

        // (A) Shared Sign-in Options (first screen)
        let options = SignInOptionsStep(identifier: Constants.Auth.signInButtons)
        steps.append(options) // handled by SignInOptionsViewController

        // (B) Email step differs by mode
        let emailStepId: String
        var profileDetailsStepId: String?
        switch mode {
        case .signup:
            let regexp = try? NSRegularExpression(pattern: "^.{10,}$")
            var flags = ORKRegistrationStepOption()
            if auth.includeDOB { flags.insert(.includeDOB) }
            if auth.includeGender { flags.insert(.includeGender) }
            flags.insert([.includeGivenName, .includeFamilyName])

            let register = ORKRegistrationStep(
                identifier: Constants.Auth.registrationStep,
                title: auth.registrationTitle.localized,
                text: auth.registrationText.localized,
                passcodeValidationRegularExpression: regexp,
                passcodeInvalidMessage: auth.passwordInvalidMessage.localized,
                options: flags
            )
            insertRegistrationHeaderAndPlaceholders(register)
            steps.append(register)
            if let profileDetails = SignupProfileDetailsStepFactory(
                auth: auth,
                appConfiguration: config
            ).makeStep() {
                steps.append(profileDetails)
                profileDetailsStepId = profileDetails.identifier
            }
            emailStepId = Constants.Auth.registrationStep

        case .login:
            let login = ORKLoginStep(
                identifier: Constants.Auth.loginExistingStep,
                title: auth.loginTitle.localized,
                text: auth.loginText.localized,
                loginViewControllerClass: LoginViewController.self
            )
            login.formItems?.first?.placeholder = auth.loginEmailPlaceholder.localized
            login.formItems?.last?.placeholder  = auth.loginPasswordPlaceholder.localized
            let header = ORKFormItem(sectionTitle: auth.loginSectionHeader.localized)
            login.formItems?.insert(header, at: 0)
            steps.append(login)
            emailStepId = Constants.Auth.loginExistingStep
        }

        // (C) Consent (AFTER email step and only if not yet accepted)
        if shouldShowConsent {
            let consentDocument = ConsentDocument()
            let visual = ORKVisualConsentStep(identifier: Constants.Auth.visualConsentStep, document: consentDocument)
            let signature = consentDocument.signatures?.first
            let review = ORKConsentReviewStep(identifier: Constants.Auth.consentReviewStep, signature: signature, in: consentDocument)
            review.text = config.teamWebsite
            review.reasonForConsent = auth.consentReason.localized
            steps += [visual, review]
        }

        // (D) Passcode (optional)
        let includesPasscodeStep = auth.passcodeEnabled && !ORKPasscodeViewController.isPasscodeStoredInKeychain()
        if includesPasscodeStep {
            let pass = ORKPasscodeStep(identifier: Constants.Auth.passcodeStep)
            pass.text = auth.passcodePrompt.localized
            pass.passcodeType = auth.passcodeType == "6" ? .type6Digit : .type4Digit
            steps.append(pass)
        }

        // (E) Health (signup only)
        if mode == .signup {
            steps += [HealthDataStep(identifier: Constants.Auth.healthKitDataStep),
                      HealthRecordsStep(identifier: Constants.Auth.healthRecordsStep)]
        }

        // (F) Completion
        let completion = ORKCompletionStep(identifier: Constants.Auth.completionStep)
        completion.title = auth.completionTitle.localized
        completion.text = auth.completionText.localized
        steps.append(completion)

        // Build task
        let task = ORKNavigableOrderedTask(identifier: Constants.Auth.studyAuthTask, steps: steps)

        // Navigation from Sign-in Options
        let sel  = ORKResultSelector(resultIdentifier: Constants.Auth.signInButtons)
        let pred = ORKResultPredicate.predicateForBooleanQuestionResult(with: sel, expectedAnswer: true)

        // Email continues to its credential step. Social signup routes through an
        // authentication trigger even when profile details and passcode are absent.
        let defaultId = AuthTaskNavigation.signInOptionsDefaultDestination(
            mode: mode,
            profileDetailsStepId: profileDetailsStepId,
            shouldShowConsent: shouldShowConsent,
            includesPasscodeStep: includesPasscodeStep
        )

        let rule = ORKPredicateStepNavigationRule(
            resultPredicates: [pred],
            destinationStepIdentifiers: [emailStepId],
            defaultStepIdentifier: defaultId,
            validateArrays: true
        )
        task.setNavigationRule(rule, forTriggerStepIdentifier: Constants.Auth.signInButtons)

        let controller = ORKTaskViewController(task: task, taskRun: nil)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ vc: ORKTaskViewController, context: Context) {}

    // MARK: helpers

    private func insertRegistrationHeaderAndPlaceholders(_ step: ORKRegistrationStep) {
        let header = ORKFormItem(sectionTitle: auth.registrationSectionHeader.localized)
        step.formItems?.insert(header, at: 0)
    }
}
