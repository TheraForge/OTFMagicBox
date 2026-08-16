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

import OTFResearchKit
import OTFUtilities
import Combine
import Sodium
import OTFCloudClientAPI
import AuthenticationServices
import GoogleSignIn
import UIKit

enum SignupAuthenticationTrigger {

    static func isAuthenticationTrigger(
        stepIdentifier: String,
        isSocialSignup: Bool,
        passcodeEnabled: Bool
    ) -> Bool {
        (passcodeEnabled && stepIdentifier == Constants.Auth.passcodeStep) ||
            stepIdentifier == Constants.Auth.completionStep ||
            (isSocialSignup && stepIdentifier == Constants.Auth.healthKitDataStep)
    }
}

enum SignupAuthenticationBoundary {
    private static let preAuthenticationStepIdentifiers: Set<String> = [
        Constants.Auth.signInButtons,
        Constants.Auth.registrationStep,
        Constants.Auth.registrationProfileDetailsStep
    ]

    static func shouldPresent(
        stepIdentifier: String,
        navigationDirection: ORKStepViewControllerNavigationDirection,
        registrationCompleted: Bool,
        isSocialSignup: Bool
    ) -> Bool {
        guard isSocialSignup,
              registrationCompleted,
              navigationDirection == .reverse else {
            return true
        }
        return !preAuthenticationStepIdentifiers.contains(stepIdentifier)
    }
}

protocol SignupCryptoProviding {
    func generateMasterKey(password: String, email: String) throws -> Bytes
    func keyPair(seed: Bytes) -> Box.KeyPair?
    func encryptSealedBox(bytes: Bytes, recipientPublicKey: Bytes) throws -> Bytes
    func defaultStorageKey(from masterKey: Bytes) throws -> Bytes
    func confidentialStorageKey(from masterKey: Bytes) throws -> Bytes
}

extension SwiftSodium: SignupCryptoProviding {
    func keyPair(seed: Bytes) -> Box.KeyPair? {
        sodium.box.keyPair(seed: seed)
    }
}

struct SignupRequestData {
    let signupRequest: OTFCloudClientAPI.Request.SignUp
    let masterKey: Bytes
    let keyPair: Box.KeyPair
    let defaultStorageKey: Bytes
    let confidentialStorageKey: Bytes
}

struct SignupProfileRequestValues: Equatable {
    let location: OTFCloudClientAPI.Request.SignUpLocation?
    let conditions: [OTFCloudClientAPI.Request.SignUpCondition]?

    init(profileData: SignupProfileData?) throws {
        let payload = try profileData?.signupPayload()
        location = payload?.location.map { location in
            .init(
                displayName: location.country,
                addressLine1: location.addressLine1,
                addressLine2: location.addressLine2,
                city: location.city,
                region: location.region,
                postalCode: location.postalCode,
                countryCode: location.countryCode
            )
        }
        conditions = payload?.conditions.map { conditions in
            conditions.map { condition in
                .init(code: condition.code, name: condition.name)
            }
        }
    }
}

struct SocialSignupRequestFactory {
    func createRequest(
        socialType: SocialType,
        identityToken: String,
        profileData: SignupProfileData?
    ) throws -> OTFCloudClientAPI.Request.SocialLogin {
        let profileValues = try SignupProfileRequestValues(profileData: profileData)
        return OTFCloudClientAPI.Request.SocialLogin(
            userType: .patient,
            socialType: socialType,
            authType: .signup,
            identityToken: identityToken,
            location: profileValues.location,
            conditions: profileValues.conditions
        )
    }
}

struct SignupRequestFactory {
    private enum FileConstants {
        static let patientFirstName = "patientFirstName"
        static let patientLastName = "patientLastName"
    }

    let crypto: SignupCryptoProviding

    static let live = SignupRequestFactory(crypto: SwiftSodium())

    func createSignupRequest(
        from stepResult: ORKStepResult,
        profileData: SignupProfileData? = nil
    ) -> SignupRequestData? {
        guard
            let email = textAnswer(for: ORKRegistrationFormItemIdentifierEmail, in: stepResult),
            let pass = textAnswer(for: ORKRegistrationFormItemIdentifierPassword, in: stepResult),
            let gender = choiceAnswer(for: ORKRegistrationFormItemIdentifierGender, in: stepResult),
            let dob = dateAnswer(for: ORKRegistrationFormItemIdentifierDOB, in: stepResult)?.toString(format: .iso8601)
        else {
            OTFLogger.logger().error("createSignupRequest: missing required fields from step result.")
            return nil
        }

        let givenName = textAnswer(
            for: ORKRegistrationFormItemIdentifierGivenName,
            in: stepResult
        ) ?? FileConstants.patientFirstName
        let familyName = textAnswer(
            for: ORKRegistrationFormItemIdentifierFamilyName,
            in: stepResult
        ) ?? FileConstants.patientLastName

        do {
            let profileValues = try SignupProfileRequestValues(profileData: profileData)
            let masterKey = try crypto.generateMasterKey(password: pass, email: email)

            guard let keyPair = crypto.keyPair(seed: masterKey) else {
                OTFLogger.logger().error("createSignupRequest: failed to derive key pair from master key.")
                return nil
            }

            let encryptedMasterKey = try crypto.encryptSealedBox(bytes: masterKey, recipientPublicKey: keyPair.publicKey)
            let defaultStorageKey = try crypto.defaultStorageKey(from: masterKey)
            let confidentialStorageKey = try crypto.confidentialStorageKey(from: masterKey)

            let encryptedDefaultStorageKeyHex = try crypto
                .encryptSealedBox(bytes: defaultStorageKey, recipientPublicKey: keyPair.publicKey)
                .bytesToHex(spacing: "").lowercased()

            let encryptedConfidentialStorageKeyHex = try crypto
                .encryptSealedBox(bytes: confidentialStorageKey, recipientPublicKey: keyPair.publicKey)
                .bytesToHex(spacing: "").lowercased()

            let signupRequest = OTFCloudClientAPI.Request.SignUp(
                email: email,
                password: pass,
                first_name: givenName,
                last_name: familyName,
                type: .patient,
                dob: dob,
                gender: gender,
                phoneNo: "",
                encryptedMasterKey: encryptedMasterKey.bytesToHex(spacing: "").lowercased(),
                publicKey: keyPair.publicKey.bytesToHex(spacing: "").lowercased(),
                encryptedDefaultStorageKey: encryptedDefaultStorageKeyHex,
                encryptedConfidentialStorageKey: encryptedConfidentialStorageKeyHex,
                location: profileValues.location,
                conditions: profileValues.conditions
            )

            return SignupRequestData(
                signupRequest: signupRequest,
                masterKey: masterKey,
                keyPair: keyPair,
                defaultStorageKey: defaultStorageKey,
                confidentialStorageKey: confidentialStorageKey
            )
        } catch {
            OTFLogger.logger().error("createSignupRequest failed before signup request creation.")
            return nil
        }
    }

    private func textAnswer(for identifier: String, in stepResult: ORKStepResult) -> String? {
        (stepResult.results?.first { $0.identifier == identifier } as? ORKTextQuestionResult)?.textAnswer
    }

    private func choiceAnswer(for identifier: String, in stepResult: ORKStepResult) -> String? {
        (stepResult.results?.first { $0.identifier == identifier } as? ORKChoiceQuestionResult)?
            .choiceAnswers?
            .first as? String
    }

    private func dateAnswer(for identifier: String, in stepResult: ORKStepResult) -> Date? {
        (stepResult.results?.first { $0.identifier == identifier } as? ORKDateQuestionResult)?.dateAnswer
    }
}

final class AuthTaskCoordinator: NSObject, ORKTaskViewControllerDelegate, ASAuthorizationControllerDelegate {
    let authType: AuthType
    private let documentManager = UploadDocumentManager()
    private let swiftSodium = SwiftSodium()
    private let signupRequestFactory: SignupRequestFactory
    private let socialSignupRequestFactory: SocialSignupRequestFactory
    private var disposables: AnyCancellable?
    private var registrationCompleted = false
    private var socialSignupInFlight = false
    private var currentNonce: String?
    private var pendingSocialProfileData: SignupProfileData?
    private weak var pendingSocialTaskViewController: ORKTaskViewController?
    private var navigationDirection = ORKStepViewControllerNavigationDirection.forward
    private let auth = AuthConfigurationLoader.auth
    private let appConfiguration: AppConfiguration
    private let logger = OTFLogger.logger()

    init(
        authType: AuthType,
        signupRequestFactory: SignupRequestFactory = .live,
        socialSignupRequestFactory: SocialSignupRequestFactory = .init(),
        appConfiguration: AppConfiguration = AppConfigurationLoader.config
    ) {
        self.authType = authType
        self.signupRequestFactory = signupRequestFactory
        self.socialSignupRequestFactory = socialSignupRequestFactory
        self.appConfiguration = appConfiguration
    }

    func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        guard authType == .signup else { return true }

        let optionsResult = taskViewController.result.stepResult(
            forStepIdentifier: Constants.Auth.signInButtons
        )
        let socialProvider = SocialSignupSelection.provider(from: optionsResult)

        guard SignupAuthenticationBoundary.shouldPresent(
            stepIdentifier: step.identifier,
            navigationDirection: navigationDirection,
            registrationCompleted: registrationCompleted,
            isSocialSignup: socialProvider != nil
        ) else {
            return false
        }

        if shouldCheckRegistration(step: step, isSocialSignup: socialProvider != nil) {
            let profileData: SignupProfileData?
            switch validateSignupProfileDetails(in: taskViewController) {
            case .notShown:
                profileData = nil
            case let .valid(validatedProfileData):
                profileData = validatedProfileData
            case .invalid:
                return false
            }

            if let socialProvider {
                beginSocialSignup(
                    provider: socialProvider,
                    profileData: profileData,
                    taskViewController: taskViewController
                )
                return false
            }

            guard let stepResult = taskViewController.result.stepResult(forStepIdentifier: Constants.Auth.registrationStep),
                  let signupRequestData = signupRequestFactory.createSignupRequest(
                      from: stepResult,
                      profileData: profileData
                  ) else { return false }

            presentSignupLoadingAlert(on: taskViewController)

            executeSignup(
                signupRequestData.signupRequest,
                masterKey: signupRequestData.masterKey,
                keyPair: signupRequestData.keyPair,
                defaultStorageKey: signupRequestData.defaultStorageKey,
                confidentialStorageKey: signupRequestData.confidentialStorageKey,
                taskViewController: taskViewController
            )
            return false
        }

        return true
    }

    private func shouldCheckRegistration(step: ORKStep, isSocialSignup: Bool) -> Bool {
        let isPostRegistrationStep = SignupAuthenticationTrigger.isAuthenticationTrigger(
            stepIdentifier: step.identifier,
            isSocialSignup: isSocialSignup,
            passcodeEnabled: auth.passcodeEnabled
        )
        return isPostRegistrationStep && navigationDirection == .forward && !registrationCompleted
    }

    private func validateSignupProfileDetails(
        in taskViewController: ORKTaskViewController
    ) -> SignupProfileDetailsValidation {
        guard appConfiguration.enableLocation || appConfiguration.enableConditions else {
            return .notShown
        }
        guard let stepResult = taskViewController.result.stepResult(
            forStepIdentifier: Constants.Auth.registrationProfileDetailsStep
        ) else {
            presentSignupProfileDetailsValidationError(.detailsUnavailable, on: taskViewController)
            return .invalid
        }

        do {
            return .valid(try SignupProfileData.make(
                from: stepResult,
                auth: auth,
                appConfiguration: appConfiguration
            ))
        } catch let error as SignupProfileDataValidationError {
            presentSignupProfileDetailsValidationError(error, on: taskViewController)
            return .invalid
        } catch {
            presentSignupProfileDetailsValidationError(.detailsUnavailable, on: taskViewController)
            return .invalid
        }
    }

    private func presentSignupProfileDetailsValidationError(
        _ error: SignupProfileDataValidationError,
        on taskViewController: ORKTaskViewController
    ) {
        taskViewController.alertWithAction(
            title: auth.signupErrorTitle.localized,
            message: error.localizedMessage(using: auth)
        ) { _ in }
    }

    private enum SignupProfileDetailsValidation: Equatable {
        case notShown
        case valid(SignupProfileData)
        case invalid
    }

    private func beginSocialSignup(
        provider: SocialType,
        profileData: SignupProfileData?,
        taskViewController: ORKTaskViewController
    ) {
        guard !socialSignupInFlight else { return }
        socialSignupInFlight = true
        pendingSocialProfileData = profileData
        pendingSocialTaskViewController = taskViewController

        switch provider {
        case .apple:
            currentNonce = .makeRandomNonce()
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email]
            request.nonce = currentNonce?.sha256
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        case .gmail:
            beginGoogleSocialSignup(presenting: taskViewController)
        }
    }

    private func beginGoogleSocialSignup(presenting taskViewController: ORKTaskViewController) {
        GIDSignIn.sharedInstance.signIn(withPresenting: taskViewController) { [weak self] user, error in
            guard let self else { return }
            guard error == nil, let idToken = user?.user.idToken?.tokenString else {
                self.handleSocialAuthorizationFailure()
                return
            }
            self.executeSocialSignup(provider: .gmail, identityToken: idToken)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            handleSocialAuthorizationFailure()
            return
        }
        executeSocialSignup(provider: .apple, identityToken: identityToken)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        handleSocialAuthorizationFailure()
    }

    private func executeSocialSignup(provider: SocialType, identityToken: String) {
        guard let taskViewController = pendingSocialTaskViewController else {
            resetSocialSignupState()
            return
        }

        let request: OTFCloudClientAPI.Request.SocialLogin
        do {
            request = try socialSignupRequestFactory.createRequest(
                socialType: provider,
                identityToken: identityToken,
                profileData: pendingSocialProfileData
            )
        } catch {
            handleSocialAuthorizationFailure()
            return
        }

        presentSignupLoadingAlert(on: taskViewController)
        disposables = OTFTheraforgeNetwork.shared.socialLoginRequest(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self, weak taskViewController] completion in
                    guard let self, let taskViewController else { return }
                    if case .failure = completion {
                        self.handleSocialSignupFailure(taskViewController: taskViewController)
                    }
                },
                receiveValue: { [weak self, weak taskViewController] _ in
                    guard let self, let taskViewController else { return }
                    self.registrationCompleted = true
                    self.resetSocialSignupState()
                    taskViewController.dismiss(animated: true) {
                        taskViewController.goForward()
                    }
                }
            )
    }

    private func handleSocialAuthorizationFailure() {
        logger.error("Social signup authorization failed.")
        guard let taskViewController = pendingSocialTaskViewController else {
            resetSocialSignupState()
            return
        }
        resetSocialSignupState()
        presentGenericSignupError(on: taskViewController)
    }

    private func handleSocialSignupFailure(taskViewController: ORKTaskViewController) {
        logger.error("Social signup request failed.")
        resetSocialSignupState()
        taskViewController.dismiss(animated: false) { [weak self, weak taskViewController] in
            guard let self, let taskViewController else { return }
            self.presentGenericSignupError(on: taskViewController)
        }
    }

    private func presentGenericSignupError(on taskViewController: ORKTaskViewController) {
        taskViewController.alertWithAction(
            title: auth.signupErrorTitle.localized,
            message: auth.signupFailureMessage.localized
        ) { _ in }
    }

    private func resetSocialSignupState() {
        socialSignupInFlight = false
        currentNonce = nil
        pendingSocialProfileData = nil
        pendingSocialTaskViewController = nil
    }

    private func presentSignupLoadingAlert(on taskViewController: ORKTaskViewController) {
        let alert = UIAlertController(title: nil, message: auth.creatingAccountMessage.localized, preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        spinner.hidesWhenStopped = true
        spinner.style = .medium
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        taskViewController.present(alert, animated: false)
    }

    private func executeSignup(_ signup: OTFCloudClientAPI.Request.SignUp,
                               masterKey: Bytes,
                               keyPair: Box.KeyPair,
                               defaultStorageKey: Bytes,
                               confidentialStorageKey: Bytes,
                               taskViewController: ORKTaskViewController) {
        disposables = OTFTheraforgeNetwork.shared.signUpRequest(signupRequest: signup)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] response in
                    guard let self else { return }
                    if case let .failure(error) = response {
                        self.handleSignupError(error, taskViewController: taskViewController)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.handleSignupSuccess(
                        email: signup.email,
                        masterKey: masterKey,
                        keyPair: keyPair,
                        defaultStorageKey: defaultStorageKey,
                        confidentialStorageKey: confidentialStorageKey,
                        taskViewController: taskViewController
                    )
                })
    }

    private func handleSignupError(_: ForgeError, taskViewController: ORKTaskViewController) {
        logger.error("Signup request failed.")
        taskViewController.dismiss(animated: false) {
            let alert = UIAlertController(
                title: self.auth.signupErrorTitle.localized,
                message: self.auth.signupFailureMessage.localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: self.auth.okayActionTitle.localized, style: .cancel))
            taskViewController.present(alert, animated: false)
        }
    }

    private func handleSignupSuccess(email: String,
                                     masterKey: Bytes,
                                     keyPair: Box.KeyPair,
                                     defaultStorageKey: Bytes,
                                     confidentialStorageKey: Bytes,
                                     taskViewController: ORKTaskViewController) {
        KeychainCloudManager
            .saveUserKeys(
                masterKey: masterKey,
                publicKey: keyPair.publicKey,
                secretKey: keyPair.secretKey,
                defaultStorageKey: defaultStorageKey,
                confidentialStorageKey: confidentialStorageKey
            )
        registrationCompleted = true
        executeEmailVerification(email, taskViewController: taskViewController)
    }

    private func executeEmailVerification(_ email: String, taskViewController: ORKTaskViewController) {
        disposables = OTFTheraforgeNetwork.shared.resendVerificationEmail(email: email)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] response in
                guard let self else { return }
                if case .failure = response {
                    self.logger.error("Verification email request failed.")
                    taskViewController.alertWithAction(
                        title: self.auth.signupErrorTitle.localized,
                        message: self.auth.signupFailureMessage.localized
                    ) { _ in taskViewController.dismiss(animated: true) }
                }
            }, receiveValue: { [weak self] _ in
                guard let self else { return }
                // Dismiss the "Creating account..." spinner
                taskViewController.dismiss(animated: true) {
                    // Present the Email Verification alert
                    taskViewController.showEmailVerifyAlert(
                        title: self.auth.emailVerifyConfirmationTitle.localized,
                        message: self.auth.emailVerifyMessage.localized
                    ) { _ in
                        // Dismiss the task to complete onboarding
                        taskViewController.dismiss(animated: true)
                    }
                }
            })
    }

    func generateMasterKey(email: String, password: String) -> [UInt8] {
        do {
            return try swiftSodium.generateMasterKey(password: password, email: email)
        } catch {
            logger.error("Master key generation failed.")
            return []
        }
    }

    func taskViewController(_ taskViewController: ORKTaskViewController,
                            stepViewControllerWillDisappear stepViewController: ORKStepViewController,
                            navigationDirection direction: ORKStepViewControllerNavigationDirection) {
        navigationDirection = direction
    }

    func taskViewController(_ taskViewController: ORKTaskViewController,
                            didFinishWith reason: ORKTaskViewControllerFinishReason,
                            error: Error?) {
        switch reason {
        case .completed:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .onboardingCompleted, object: true)
            }

            if let signatureResult = taskViewController.result.stepResult(forStepIdentifier: Constants.Auth.consentReviewStep)?.results?.first as? ORKConsentSignatureResult {
                UserDefaults.standard.set(true, forKey: Constants.Storage.kConsentDocumentViewed)

                let consentDocument = ConsentDocument()
                signatureResult.apply(to: consentDocument)

                consentDocument.makePDF { [self] (data, _) in
                    var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last as NSURL?
                    docURL = docURL?.appendingPathComponent("\(auth.consentFileName).pdf") as NSURL?

                    guard let data = data, let url = docURL as URL? else {
                        logger.error("Consent generation: missing PDF data or URL – aborting upload.")
                        return
                    }

                    do {
                        guard KeychainCloudManager.isKeyStored(key: KeychainKeys.defaultStorageKey),
                              KeychainCloudManager.isKeyStored(key: KeychainKeys.confidentialStorageKey) else {
                            logger.error("Consent generation: storage keys missing – aborting upload.")
                            return
                        }

                        documentManager.encryptDocument(document: data, fileName: "\(auth.consentFileName).pdf")

                        try data.write(to: url)
                        UserDefaults.standard.set(url.path, forKey: Constants.Storage.kConsentDocumentURL)
                    } catch {
                        logger.error("Consent PDF data could not be written.")
                    }
                }
            }
            fallthrough

        default:
            DispatchQueue.main.async { taskViewController.dismiss(animated: false, completion: nil) }
        }
    }

    func taskViewController(_ taskViewController: ORKTaskViewController, viewControllerFor step: ORKStep) -> ORKStepViewController? {
        switch step {
        case is HealthDataStep:
            return HealthDataStepViewController(step: step)
        case is HealthRecordsStep:
            return HealthRecordsStepViewController(step: step)
        case is SignInOptionsStep:
            return SignInOptionsViewController(authType: authType, step: step)
        default:
            return nil
        }
    }
}
