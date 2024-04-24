/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.
 
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

final class OnboardingTaskCoordinator: NSObject {
    
    let authType: AuthType
    var disposeables: AnyCancellable?
    let documentManager = UploadDocumentManager()
    let swiftSodium = SwiftSodium()
    
    /// Change this value to true when registration step completes successfully
    private var registrationCompleted = false
    private var navigationDirection = ORKStepViewControllerNavigationDirection.forward
    
    init(authType: AuthType) {
        self.authType = authType
    }
}

extension OnboardingTaskCoordinator: ORKTaskViewControllerDelegate {
    public func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        guard authType == .signup else {
            return true
        }
        
        let config = ModuleAppYmlReader()
        
        var checkRegistrationStatusFirst = false
        if config.isPasscodeEnabled, step.identifier == Constants.Identifier.PasscodeStep {
            checkRegistrationStatusFirst = true
        }
        else if step.identifier == Constants.Identifier.CompletionStep {
            checkRegistrationStatusFirst = true
        }
        
        if checkRegistrationStatusFirst, navigationDirection == .forward, !registrationCompleted {
            let stepResult = taskViewController.result.stepResult(forStepIdentifier: Constants.Registration.Identifier)
            
            let emailRes = stepResult?.results?.first as? ORKTextQuestionResult
            guard let email = emailRes?.textAnswer else {
                return false
            }
            
            let passwordRes = stepResult?.results?[1] as? ORKTextQuestionResult
            guard let pass = passwordRes?.textAnswer else {
                return false
            }
            let givenName = stepResult?.results?[3] as? ORKTextQuestionResult
            let familyName = stepResult?.results?[4] as? ORKTextQuestionResult
            
            let genderResult = stepResult?.results?[5] as? ORKChoiceQuestionResult
            let dobResult = stepResult?.results?[6] as? ORKDateQuestionResult
            
            guard let gender = genderResult?.choiceAnswers?.first as? String else {
                return false
            }
            
            guard let dob = dobResult?.dateAnswer?.toString else {
                return false
            }
            
            let masterKey = swiftSodium.generateMasterKey(password: pass, email: email)
            
            guard let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey) else {
                return false
            }
            
            let encryptkey : Bytes? = swiftSodium.encryptKey(bytes: masterKey, publicKey: keyPair.publicKey)
            
            guard let encryptedMasterKey = encryptkey  else {
                return false
            }
            
            let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
            let confidentialStorageKey = swiftSodium.generateConfidentialStorageKey(masterKey: masterKey)
            
            let encryptedDefaultStorageKey = swiftSodium.encryptKey(bytes: defaultStorageKey, publicKey: keyPair.publicKey)
            let encryptedconfidentialStorageKey = swiftSodium.encryptKey(bytes: confidentialStorageKey, publicKey: keyPair.publicKey)
            
            let encryptedDefaultStorageKeyHex = encryptedDefaultStorageKey.bytesToHex(spacing: "").lowercased()
            let encryptedconfidentialStorageKeyHex = encryptedconfidentialStorageKey.bytesToHex(spacing: "").lowercased()
            let encryptedMasterKeyHex = encryptedMasterKey.bytesToHex(spacing: "").lowercased()
            let publicKeyHex = keyPair.publicKey.bytesToHex(spacing: "").lowercased()
            
            let alert = UIAlertController(title: nil, message: Constants.CustomiseStrings.creatingAccount, preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()
            
            alert.view.addSubview(loadingIndicator)
            taskViewController.present(alert, animated: false, completion: nil)
            
            disposeables = OTFTheraforgeNetwork.shared.signUpRequest(firstName: givenName?.textAnswer ?? Constants.patientFirstName, lastName: familyName?.textAnswer ?? Constants.patientLastName, type: Constants.userType, email: email, password: pass, dob: dob, gender: gender, encryptedMasterKey: encryptedMasterKeyHex, publicKey: publicKeyHex, encryptedDefaultStorageKey: encryptedDefaultStorageKeyHex, encryptedConfidentialStorageKey: encryptedconfidentialStorageKeyHex)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { response in
                    switch response {
                    case .failure(let error):
                        OTFError("error in signup request", error.error.message)
                        alert.dismiss(animated: false) {
                            let alert = UIAlertController(title: Constants.CustomiseStrings.error, message: error.error.message, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: Constants.CustomiseStrings.okay, style: .cancel))
                            taskViewController.present(alert, animated: false)
                        }
                    default: break;
                    }
                }, receiveValue: { result in
                    OTFLog("Successfully revrived", result.message ?? "")
                    alert.dismiss(animated: false) {
                        KeychainCloudManager.saveValuesInKeychain(email: email, password: pass, masterKey: masterKey, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey, defaultStorageKey: defaultStorageKey, confidentialStorageKey: confidentialStorageKey)
                        self.registrationCompleted = true
                        taskViewController.goForward()
                    }
                })
            
            return false
        }
        
        return true
    }
    
    func generateMasterKey(email: String, password: String) -> Array<UInt8>  {
        let masterKey = swiftSodium.generateMasterKey(password: KeychainCloudManager.getPassword, email: KeychainCloudManager.getEmailAddress)
        return masterKey
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController,
                            stepViewControllerWillDisappear stepViewController: ORKStepViewController,
                            navigationDirection direction: ORKStepViewControllerNavigationDirection) {
        navigationDirection = direction
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController,
                                   didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        switch reason {
        case .completed:
            
            DispatchQueue.main.async {
                UserDefaultsManager.setOnboardingCompleted(true)
                NotificationCenter.default.post(name: .onboardingDidComplete, object: true)
            }
            
            if let signatureResult = taskViewController.result.stepResult(forStepIdentifier: "ConsentReviewStep")?.results?.first as? ORKConsentSignatureResult {
                
                let consentDocument = ConsentDocument()
                signatureResult.apply(to: consentDocument)
                
                consentDocument.makePDF { (data, error) -> Void in
                    
                    var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last as NSURL?
                    docURL = docURL?.appendingPathComponent("\(ModuleAppYmlReader().consentFileName).pdf") as NSURL?
                    
                    do {
                        let url = docURL! as URL
                        
                        self.documentManager.encryptDocument(document: data!, fileName: "\(ModuleAppYmlReader().consentFileName).pdf")
                        
                        try data?.write(to: url)
                        
                        UserDefaults.standard.set(url.path, forKey: Constants.UserDefaults.ConsentDocumentURL)
                        
                    } catch let error {
                        OTFError("error in writting data in pdf %{public}@", error.localizedDescription)
                    }
                }
            }
            fallthrough
            
        default:
            // Dismiss onboarding without proceeding.
            DispatchQueue.main.async {
                taskViewController.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController,
                            viewControllerFor step: ORKStep) -> ORKStepViewController? {
        switch step {
        case is HealthDataStep:
            return HealthDataStepViewController(step: step)
        case is HealthRecordsStep:
            return HealthRecordsStepViewController(step: step)
        case is OnboardingOptionsStep:
            return OnboardingOptionsViewController(authType: authType, step: step)
        default:
            return nil
        }
    }
    
}
