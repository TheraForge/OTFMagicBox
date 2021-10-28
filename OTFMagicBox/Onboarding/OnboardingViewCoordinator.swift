//
//  OnboardingViewCoordinator.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import OTFResearchKit

class OnboardingTaskViewControllerDelegate: NSObject, ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        switch reason {
        case .completed:
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(Constants.onboardingDidComplete), object: true)
            }
            
            if let signatureResult = taskViewController.result.stepResult(forStepIdentifier: "ConsentReviewStep")?.results?.first as? ORKConsentSignatureResult {
                
                let consentDocument = ConsentDocument()
                signatureResult.apply(to: consentDocument)
                
                consentDocument.makePDF { (data, error) -> Void in
                    
                    var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last as NSURL?
                    docURL = docURL?.appendingPathComponent("\(YmlReader().teamName).pdf") as NSURL?
                    
                    do {
                        let url = docURL! as URL
                        try data?.write(to: url)
                        
                        UserDefaults.standard.set(url.path, forKey: "consentFormURL")
                        
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
    
    func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        
        if stepViewController.step?.identifier == Constants.Login.Identifier {
            
            let alert = UIAlertController(title: nil, message: "Creating account...", preferredStyle: .alert)
            
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()
            
            alert.view.addSubview(loadingIndicator)
            taskViewController.present(alert, animated: true, completion: nil)
            
            let stepResult = taskViewController.result.stepResult(forStepIdentifier: Constants.Registration.Identifier)
            
            let emailRes = stepResult?.results?.first as? ORKTextQuestionResult
            guard let email = emailRes?.textAnswer else {
                return
            }
            
            let passwordRes = stepResult?.results?[1] as? ORKTextQuestionResult
            guard let pass = passwordRes?.textAnswer else {
                return
            }
            let givenName = stepResult?.results?[3] as? ORKTextQuestionResult
            let familyName = stepResult?.results?[4] as? ORKTextQuestionResult
            let gender = stepResult?.results?[5] as? ORKTextQuestionResult
            let dob = stepResult?.results?[6] as? ORKTextQuestionResult
            
            OTFTheraforgeNetwork.shared.signUpRequest(firstName: givenName?.textAnswer ?? "",
                                                      lastName: familyName?.textAnswer ?? "",
                                                      type: "patient", email: email, password: pass,
                                                      dob: dob?.textAnswer ?? "",
                                                      gender: gender?.textAnswer ?? "") { results in
                switch results {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true) {
                            let alert = UIAlertController(title: "Login Error!", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                            taskViewController.present(alert, animated: true)
                        }
                    }
                    
                case .success(let result):
                    print(result)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                    }
                }
                
            }
            
        }
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController, viewControllerFor step: ORKStep) -> ORKStepViewController? {
        switch step {
        case is HealthDataStep:
            return HealthDataStepViewController(step: step)
        case is HealthRecordsStep:
            return HealthRecordsStepViewController(step: step)
        default:
            return nil
        }
    }
    
}
