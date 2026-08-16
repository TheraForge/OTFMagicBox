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

import OTFResearchKit
import Testing
@testable import OTFMagicBox

@Suite("Social signup selection")
struct SocialSignupSelectionTests {
    @Test("Provider selection is recovered without storing an identity token")
    func providerSelectionIsRecovered() {
        let providerResult = ORKTextQuestionResult(identifier: Constants.Auth.socialSignupProvider)
        providerResult.textAnswer = SocialType.apple.rawValue
        let stepResult = ORKStepResult(
            stepIdentifier: Constants.Auth.signInButtons,
            results: [providerResult]
        )

        #expect(SocialSignupSelection.provider(from: stepResult) == .apple)
        #expect(stepResult.results?.contains { $0.identifier.lowercased().contains("token") } == false)
    }

    @Test("Missing or unknown provider selections are rejected")
    func missingOrUnknownProviderSelectionsAreRejected() {
        let unknown = ORKTextQuestionResult(identifier: Constants.Auth.socialSignupProvider)
        unknown.textAnswer = "unsupported"
        let stepResult = ORKStepResult(
            stepIdentifier: Constants.Auth.signInButtons,
            results: [unknown]
        )

        #expect(SocialSignupSelection.provider(from: nil) == nil)
        #expect(SocialSignupSelection.provider(from: stepResult) == nil)
    }
}

@Suite("Social signup navigation")
struct SocialSignupNavigationTests {
    @Test("Enabled profile details precede social authentication regardless of passcode state")
    func enabledProfileDetailsRemainTheSocialSignupDestination() throws {
        let profileDetailsStep = try #require(SignupProfileDetailsStepFactory(
            auth: .fallback,
            appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: true)
        ).makeStep())

        for includesPasscodeStep in [false, true] {
            #expect(AuthTaskNavigation.signInOptionsDefaultDestination(
                mode: .signup,
                profileDetailsStepId: profileDetailsStep.identifier,
                shouldShowConsent: false,
                includesPasscodeStep: includesPasscodeStep
            ) == Constants.Auth.registrationProfileDetailsStep)
        }
    }

    @Test("Disabled profile details preserve passcode setup before social authentication")
    func disabledProfileDetailsRouteToPasscodeOrHealthData() {
        let profileDetailsStep = SignupProfileDetailsStepFactory(
            auth: .fallback,
            appConfiguration: makeAppConfiguration(enableLocation: false, enableConditions: false)
        ).makeStep()

        #expect(profileDetailsStep == nil)
        #expect(AuthTaskNavigation.signInOptionsDefaultDestination(
            mode: .signup,
            profileDetailsStepId: profileDetailsStep?.identifier,
            shouldShowConsent: false,
            includesPasscodeStep: false
        ) == Constants.Auth.healthKitDataStep)
        #expect(AuthTaskNavigation.signInOptionsDefaultDestination(
            mode: .signup,
            profileDetailsStepId: profileDetailsStep?.identifier,
            shouldShowConsent: false,
            includesPasscodeStep: true
        ) == Constants.Auth.passcodeStep)
    }

    @Test("Health Data starts social authentication regardless of passcode configuration")
    func healthDataIsAlwaysASocialAuthenticationTrigger() {
        for passcodeEnabled in [false, true] {
            #expect(SignupAuthenticationTrigger.isAuthenticationTrigger(
                stepIdentifier: Constants.Auth.healthKitDataStep,
                isSocialSignup: true,
                passcodeEnabled: passcodeEnabled
            ))
        }
    }

    @Test("Completed social signup cannot navigate back across the authentication boundary")
    func completedSocialSignupBlocksReverseNavigationToPreAuthenticationSteps() {
        let preAuthenticationStepIdentifiers = [
            Constants.Auth.signInButtons,
            Constants.Auth.registrationStep,
            Constants.Auth.registrationProfileDetailsStep
        ]

        for stepIdentifier in preAuthenticationStepIdentifiers {
            #expect(!SignupAuthenticationBoundary.shouldPresent(
                stepIdentifier: stepIdentifier,
                navigationDirection: .reverse,
                registrationCompleted: true,
                isSocialSignup: true
            ))
        }
    }

    @Test("Completed social signup keeps post-authentication navigation available")
    func completedSocialSignupAllowsPostAuthenticationNavigation() {
        let postAuthenticationStepIdentifiers = [
            Constants.Auth.passcodeStep,
            Constants.Auth.healthKitDataStep,
            Constants.Auth.healthRecordsStep,
            Constants.Auth.completionStep
        ]

        for stepIdentifier in postAuthenticationStepIdentifiers {
            #expect(SignupAuthenticationBoundary.shouldPresent(
                stepIdentifier: stepIdentifier,
                navigationDirection: .reverse,
                registrationCompleted: true,
                isSocialSignup: true
            ))
        }
    }

    @Test("Authentication boundary does not affect forward or email navigation")
    func authenticationBoundaryLeavesOtherNavigationUnchanged() {
        #expect(SignupAuthenticationBoundary.shouldPresent(
            stepIdentifier: Constants.Auth.registrationProfileDetailsStep,
            navigationDirection: .forward,
            registrationCompleted: true,
            isSocialSignup: true
        ))
        #expect(SignupAuthenticationBoundary.shouldPresent(
            stepIdentifier: Constants.Auth.registrationProfileDetailsStep,
            navigationDirection: .reverse,
            registrationCompleted: true,
            isSocialSignup: false
        ))
        #expect(SignupAuthenticationBoundary.shouldPresent(
            stepIdentifier: Constants.Auth.registrationProfileDetailsStep,
            navigationDirection: .reverse,
            registrationCompleted: false,
            isSocialSignup: true
        ))
    }
}

@Suite("Login credential extraction")
struct LoginCredentialExtractorTests {
    @Test("Credential extractor returns nil for missing or incomplete login results")
    func credentialExtractorReturnsNilForMissingOrIncompleteLoginResults() {
        let emailOnly = makeLoginStepResult(email: "patient@example.com", password: nil)
        let passwordOnly = makeLoginStepResult(email: nil, password: "secret-password")

        #expect(LoginCredentialExtractor.credentials(from: nil) == nil)
        #expect(LoginCredentialExtractor.credentials(from: ORKStepResult(stepIdentifier: "login", results: nil)) == nil)
        #expect(LoginCredentialExtractor.credentials(from: emailOnly) == nil)
        #expect(LoginCredentialExtractor.credentials(from: passwordOnly) == nil)
    }

    @Test("Credential extractor returns email and password from valid login result")
    func credentialExtractorReturnsEmailAndPasswordFromValidLoginResult() {
        let credentials = LoginCredentialExtractor.credentials(
            from: makeLoginStepResult(email: "patient@example.com", password: "secret-password")
        )

        #expect(credentials == LoginCredentials(email: "patient@example.com", password: "secret-password"))
    }
}

@Suite("Auth task coordinator")
@MainActor
struct AuthTaskCoordinatorTests {
    @Test("Login flows present steps without signup validation")
    func loginFlowsPresentStepsWithoutSignupValidation() {
        let coordinator = AuthTaskCoordinator(authType: .login)
        let taskViewController = makeAuthTaskViewController()
        let completionStep = ORKCompletionStep(identifier: Constants.Auth.completionStep)

        let shouldPresent = coordinator.taskViewController(taskViewController, shouldPresent: completionStep)

        #expect(shouldPresent)
    }

    @Test("Signup flow blocks completion when registration result is unavailable")
    func signupFlowBlocksCompletionWhenRegistrationResultIsUnavailable() {
        let coordinator = AuthTaskCoordinator(authType: .signup)
        let taskViewController = makeAuthTaskViewController()
        let completionStep = ORKCompletionStep(identifier: Constants.Auth.completionStep)

        let shouldPresent = coordinator.taskViewController(taskViewController, shouldPresent: completionStep)

        #expect(!shouldPresent)
    }

    @Test("Signup flow honors backward navigation without validating registration")
    func signupFlowHonorsBackwardNavigationWithoutValidatingRegistration() {
        let coordinator = AuthTaskCoordinator(authType: .signup)
        let taskViewController = makeAuthTaskViewController()
        let currentStep = ORKInstructionStep(identifier: "previous")
        let stepViewController = ORKStepViewController(step: currentStep)
        let completionStep = ORKCompletionStep(identifier: Constants.Auth.completionStep)

        coordinator.taskViewController(
            taskViewController,
            stepViewControllerWillDisappear: stepViewController,
            navigationDirection: .reverse
        )
        let shouldPresent = coordinator.taskViewController(taskViewController, shouldPresent: completionStep)

        #expect(shouldPresent)
    }

    @Test("Coordinator returns custom view controllers for auth helper steps")
    func coordinatorReturnsCustomViewControllersForAuthHelperSteps() throws {
        let coordinator = AuthTaskCoordinator(authType: .signup)
        let taskViewController = makeAuthTaskViewController()

        let healthDataController = coordinator.taskViewController(
            taskViewController,
            viewControllerFor: HealthDataStep(identifier: Constants.Auth.healthKitDataStep)
        )
        let healthRecordsController = coordinator.taskViewController(
            taskViewController,
            viewControllerFor: HealthRecordsStep(identifier: Constants.Auth.healthRecordsStep)
        )
        let signInOptionsController = coordinator.taskViewController(
            taskViewController,
            viewControllerFor: SignInOptionsStep(identifier: Constants.Auth.signInButtons)
        )
        let defaultController = coordinator.taskViewController(
            taskViewController,
            viewControllerFor: ORKInstructionStep(identifier: "ordinary")
        )

        #expect(try #require(healthDataController) is HealthDataStepViewController)
        #expect(try #require(healthRecordsController) is HealthRecordsStepViewController)
        #expect(try #require(signInOptionsController) is SignInOptionsViewController)
        #expect(defaultController == nil)
    }
}

private func makeLoginStepResult(email: String?, password: String?) -> ORKStepResult {
    var results: [ORKResult] = []
    if let email {
        let emailResult = ORKTextQuestionResult(identifier: "email")
        emailResult.textAnswer = email
        results.append(emailResult)
    }
    if let password {
        let passwordResult = ORKTextQuestionResult(identifier: "password")
        passwordResult.textAnswer = password
        results.append(passwordResult)
    }
    return ORKStepResult(stepIdentifier: Constants.Auth.loginExistingStep, results: results)
}

@MainActor
private func makeAuthTaskViewController() -> ORKTaskViewController {
    let task = ORKOrderedTask(identifier: "auth-test-task", steps: [])
    return ORKTaskViewController(task: task, taskRun: nil)
}
