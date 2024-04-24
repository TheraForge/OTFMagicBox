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

import Foundation
import SwiftUI
import UIKit
import OTFResearchKit

enum AuthMethod: String, CaseIterable, Codable {
    case email, apple
    
    var signinTitle: String {
        switch self {
        case .email:
            return Constants.CustomiseStrings.signinWithEmail
            
        case .apple:
            return Constants.CustomiseStrings.signinWithApple
        }
    }
    
    var signupTitle: String {
        switch self {
        case .email:
            return Constants.CustomiseStrings.signUpWithEmail
            
        case .apple:
            return Constants.CustomiseStrings.signUpWithApple
        }
    }
}

struct LoginExistingUserViewController: UIViewControllerRepresentable {
    
    func makeCoordinator() -> OnboardingTaskCoordinator {
        OnboardingTaskCoordinator(authType: .login)
    }
    
    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
        var loginSteps: [ORKStep]
        let signInButtons = OnboardingOptionsStep(identifier: "SignInButtons")
        let loginUserPassword = ORKLoginStep(identifier: "LoginExistingStep", title: Constants.CustomiseStrings.login, text: Constants.Login.Text, loginViewControllerClass: LoginViewController.self)
        loginSteps = [signInButtons, loginUserPassword]
        
        //add consent if user dont have consent in cloud
        let config = ModuleAppYmlReader()
        let consentDocument = ConsentDocument()
        /* **************************************************************
        **************************************************************/
        // use the `ORKConsentReviewStep` from ResearchKit
        let signature = consentDocument.signatures?.first
        let reviewConsentStep = ORKConsentReviewStep(identifier: "ConsentReviewStep", signature: signature, in: consentDocument)
        reviewConsentStep.text = YmlReader().teamWebsite
        reviewConsentStep.reasonForConsent = config.reasonForConsentText
        
        // create a task with each step
        if !UserDefaultsManager.isConsentDocumentViewed {
            UserDefaultsManager.setIsConsentDocumentViewed(true)
            loginSteps += [reviewConsentStep]
        }
        
        
        // use the `ORKPasscodeStep` from ResearchKit.
        if config.isPasscodeEnabled {
            let passcodeStep = ORKPasscodeStep(identifier: "Passcode")
            passcodeStep.text = Constants.CustomiseStrings.enterPasscode

            let type = ModuleAppYmlReader().passcodeType
            if type == Constants.Passcode.lengthSix {
                passcodeStep.passcodeType = .type6Digit
            } else {
                passcodeStep.passcodeType = .type4Digit
            }
            
            loginSteps += [passcodeStep]
        }
        
        // set completion step
        let completionStep = ORKCompletionStep(identifier: Constants.Identifier.CompletionStep)
        completionStep.title = ModuleAppYmlReader().completionStepTitle
        completionStep.text = ModuleAppYmlReader().completionStepText
        loginSteps += [completionStep]
        
        let navigableTask = ORKNavigableOrderedTask(identifier: "StudyLoginTask", steps: loginSteps)
        let resultSelector = ORKResultSelector(resultIdentifier: "SignInButtons")
        let booleanAnswerType = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [booleanAnswerType],
                                                           destinationStepIdentifiers: ["LoginExistingStep"],
                                                           defaultStepIdentifier: "ConsentReviewStep",
                                                           validateArrays: true)
        navigableTask.setNavigationRule(predicateRule, forTriggerStepIdentifier: "SignInButtons")
        
        // ADD New navigation Rule (if has or not consentDocument)
        // Consent Rule
        let resultConsent = ORKResultSelector(resultIdentifier: "ConsentReview")
        let booleanAnswerConsent = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultConsent, expectedAnswer: true)
        let predicateRuleConsent = ORKPredicateStepNavigationRule(resultPredicates: [booleanAnswerConsent],
                                                           destinationStepIdentifiers: ["HealthKit"],
                                                           defaultStepIdentifier: "ConsentReviewStep",
                                                           validateArrays: true)
        navigableTask.setNavigationRule(predicateRuleConsent, forTriggerStepIdentifier: "ConsentReview")
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: navigableTask, taskRun: nil)
        taskViewController.delegate = context.coordinator // enables `ORKTaskViewControllerDelegate` below
        
        // & present the VC!
        return taskViewController
    }
    
}

