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
import UIKit

final class AuthTaskCoordinator: NSObject, ORKTaskViewControllerDelegate {

    private enum FileConstants {
        static let patientFirstName = "patientFirstName"
        static let patientLastName = "patientLastName"
    }

    private struct SignupRequestData {
        let signupRequest: OTFCloudClientAPI.Request.SignUp
        let masterKey: Bytes
        let keyPair: Box.KeyPair
        let defaultStorageKey: Bytes
        let confidentialStorageKey: Bytes
    }

    let authType: AuthType
    private let documentManager = UploadDocumentManager()
    private let swiftSodium = SwiftSodium()
    private var disposables: AnyCancellable?
    private var registrationCompleted = false
    private var navigationDirection = ORKStepViewControllerNavigationDirection.forward
    private let auth = AuthConfigurationLoader.auth
    private let logger = OTFLogger.logger()

    init(authType: AuthType) {
        self.authType = authType
    }

    func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        guard authType == .signup else { return true }

        if shouldCheckRegistration(step: step) {
            guard let stepResult = taskViewController.result.stepResult(forStepIdentifier: Constants.Auth.registrationStep),
                  let signupRequestData = createSignupRequest(from: stepResult) else { return false }

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

    private func shouldCheckRegistration(step: ORKStep) -> Bool {
        let isPasscodeOrCompletion = (auth.passcodeEnabled && step.identifier == Constants.Auth.passcodeStep)
        || step.identifier == Constants.Auth.completionStep
        return isPasscodeOrCompletion && navigationDirection == .forward && !registrationCompleted
    }

    private func createSignupRequest(from stepResult: ORKStepResult) -> SignupRequestData? {
        guard
            let email = (stepResult.results?.first as? ORKTextQuestionResult)?.textAnswer,
            let pass = (stepResult.results?[1] as? ORKTextQuestionResult)?.textAnswer,
            let gender = (stepResult.results?[5] as? ORKChoiceQuestionResult)?.choiceAnswers?.first as? String,
            let dob = (stepResult.results?[6] as? ORKDateQuestionResult)?.dateAnswer?.toString(format: .iso8601)
        else {
            logger.error("createSignupRequest: missing required fields from step result.")
            return nil
        }

        let givenName = (stepResult.results?[3] as? ORKTextQuestionResult)?.textAnswer ?? FileConstants.patientFirstName
        let familyName = (stepResult.results?[4] as? ORKTextQuestionResult)?.textAnswer ?? FileConstants.patientLastName

        do {
            let masterKey = try swiftSodium.generateMasterKey(password: pass, email: email)

            guard let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey) else {
                logger.error("createSignupRequest: failed to derive key pair from master key.")
                return nil
            }

            let encryptedMasterKey = try swiftSodium.encryptSealedBox(bytes: masterKey, recipientPublicKey: keyPair.publicKey)
            let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
            let confidentialStorageKey = try swiftSodium.confidentialStorageKey(from: masterKey)

            // Encrypt storage keys with our key, then hex-encode (lowercase to match server)
            let encryptedDefaultStorageKeyHex = try swiftSodium
                .encryptSealedBox(bytes: defaultStorageKey, recipientPublicKey: keyPair.publicKey)
                .bytesToHex(spacing: "").lowercased()

            let encryptedConfidentialStorageKeyHex = try swiftSodium
                .encryptSealedBox(bytes: confidentialStorageKey, recipientPublicKey: keyPair.publicKey)
                .bytesToHex(spacing: "").lowercased()

            // Build request payload
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
                encryptedConfidentialStorageKey: encryptedConfidentialStorageKeyHex
            )

            return SignupRequestData(
                signupRequest: signupRequest,
                masterKey: masterKey,
                keyPair: keyPair,
                defaultStorageKey: defaultStorageKey,
                confidentialStorageKey: confidentialStorageKey
            )
        } catch {
            logger.error("createSignupRequest failed: \(error.localizedDescription)")
            return nil
        }
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

    private func handleSignupError(_ error: ForgeError, taskViewController: ORKTaskViewController) {
        taskViewController.dismiss(animated: false) {
            let alert = UIAlertController(title: self.auth.genericErrorTitle.localized, message: error.error.message, preferredStyle: .alert)
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
                if case let .failure(error) = response {
                    taskViewController.alertWithAction(
                        title: self.auth.genericErrorTitle.localized,
                        message: error.error.message
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
            logger.error("generateMasterKey failed: \(error.localizedDescription)")
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
                    } catch let error {
                        logger.error("error in writting data in pdf \(error.localizedDescription)")
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
