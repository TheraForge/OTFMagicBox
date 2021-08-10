//
//  OnboardingViewCoordinator.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import ResearchKit

/**
  
 */
class OnboardingTaskViewControllerDelegate: NSObject, ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        switch reason {
        case .completed:
            UserDefaults.standard.set(true, forKey: Constants.onboardingDidComplete)
            
            if let signatureResult = taskViewController.result.stepResult(forStepIdentifier: "ConsentReviewStep")?.results?.first as? ORKConsentSignatureResult {
                
                let consentDocument = ConsentDocument()
                signatureResult.apply(to: consentDocument)

                consentDocument.makePDF { (data, error) -> Void in
                        
                    let docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last as NSURL?
                   
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
            taskViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {}
    
    func taskViewController(_ taskViewController: ORKTaskViewController, viewControllerFor step: ORKStep) -> ORKStepViewController? {
        return nil
    }
}

