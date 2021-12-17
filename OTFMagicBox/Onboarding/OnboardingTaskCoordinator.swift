//
//  OnboardingTaskCoordinator.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import OTFResearchKit

final class OnboardingTaskCoordinator: NSObject {
    
    let authMethod: AuthMethod
    let authType: AuthType
    
    /// Change this value to true when registration step completes successfully
    private var registrationCompleted = false
    private var navigationDirection = ORKStepViewControllerNavigationDirection.forward
    
    init(authMethod: AuthMethod, authType: AuthType) {
        self.authType = authType
        self.authMethod = authMethod
    }
}

extension OnboardingTaskCoordinator: ORKTaskViewControllerDelegate {
    public func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        if authType == .signup, step.identifier == Constants.Identifier.HealthKitDataStep, navigationDirection == .forward, !registrationCompleted {
            let alert = UIAlertController(title: nil, message: "Creating account...",
                                          preferredStyle: .alert)
            
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5,
                                                                         width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()
            
            alert.view.addSubview(loadingIndicator)
            taskViewController.present(alert, animated: true, completion: nil)
            
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
            
            OTFTheraforgeNetwork.shared.signUpRequest(firstName: givenName?.textAnswer ?? Constants.patientFirstName,
                                                      lastName: familyName?.textAnswer ?? Constants.patientLastName,
                                                      type: Constants.userType, email: email, password: pass,
                                                      dob: dob, gender: gender) { results in
                DispatchQueue.main.async {
                    switch results {
                    case .failure(let error):
                        print(error.localizedDescription)
                        alert.dismiss(animated: true) {
                            let alert = UIAlertController(title: "Error", message: error.error.message, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                            taskViewController.present(alert, animated: true)
                        }
                        
                    case .success(let result):
                        print(result)
                        alert.dismiss(animated: true, completion: nil)
                        self.registrationCompleted = true
                        taskViewController.goForward()
                    }
                }
            }
            
            return false
        }
        
        return true
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
                    docURL = docURL?.appendingPathComponent("\(YmlReader().consentFileName).pdf") as NSURL?
                    
                    do {
                        let url = docURL! as URL
                        try data?.write(to: url)
                        UserDefaults.standard.set(url.path, forKey: Constants.UserDefaults.ConsentDocumentURL)
                        
                    } catch let error {
                        
                        print(error.localizedDescription)
                    }
                }
            }
            fallthrough
            
        default:
            // Dismiss onboarding without proceeding.
            DispatchQueue.main.async {
                taskViewController.dismiss(animated: true, completion: nil)
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
        case is SignInWithAppleStep:
            return SignInWithAppleStepViewController(authType: authType, step: step)
        default:
            return nil
        }
    }
    
}
