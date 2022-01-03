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

import SwiftUI
import UIKit
import OTFResearchKit
import Yams
import OTFCareKit
import OTFCareKitStore
/**
 User activities to create a Digital Health Application.
 */
struct ActivitiesViewController: UIViewControllerRepresentable {
    
    let authMethod: AuthMethod
    
    private let fileName = Constants.yamlFile
    
    func makeCoordinator() -> OnboardingTaskCoordinator {
        OnboardingTaskCoordinator(authMethod: authMethod, authType: .signup)
    }
    
    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
        /* **************************************************************
         *  STEP (1): get user consent
         **************************************************************/
        // use the `ORKVisualConsentStep` from ResearchKit
        let consentDocument = ConsentDocument()
        let consentStep = ORKVisualConsentStep(identifier: Constants.Identifier.ConsentStep, document: consentDocument)
        
        /* **************************************************************
         *  STEP (2): ask user to review and sign consent document
         **************************************************************/
        // use the `ORKConsentReviewStep` from ResearchKit
        let signature = consentDocument.signatures?.first
        let reviewConsentStep = ORKConsentReviewStep(identifier: Constants.Identifier.ConsentReviewStep, signature: signature, in: consentDocument)
        reviewConsentStep.text = YmlReader().reviewConsentStepText
        reviewConsentStep.reasonForConsent = YmlReader().reasonForConsentText
        
        // given intro steps that the user should review and consent to
        let introSteps: [ORKStep] = [consentStep, reviewConsentStep]
        
        // TODO: Add this after enabling HealthKit in Xcode
        //let healthRecordsStep = HealthRecordsStep(identifier: "HealthRecords")
        
        /* **************************************************************
         *  STEP (4): ask user to enter their email address for login
         **************************************************************/
        // the `LoginStep` collects and email address, and
        // the `LoginCustomWaitStep` waits for email verification.
        
        var loginSteps: [ORKStep]
        
        // swiftlint:disable all
        let regexp = try! NSRegularExpression(pattern: "^.{10,}$")
        
        var regOption = ORKRegistrationStepOption()
        
        if YmlReader().showDateOfBirth {
            regOption.insert(.includeDOB)
        }
        
        if YmlReader().showGender {
            regOption.insert(.includeGender)
        }
        regOption.insert( .includeGivenName)
        regOption.insert( .includeFamilyName)
        
        if authMethod == .apple {
            let signInWithAppleStep = AppleLoginSteps().steps
            loginSteps = signInWithAppleStep
        } else {
            let registerStep = ORKRegistrationStep(identifier: Constants.Registration.Identifier,
                                                   title: Constants.Registration.Title,
                                                   text: Constants.Registration.Text,
                                                   passcodeValidationRegularExpression: regexp,
                                                   passcodeInvalidMessage: Constants.Registration.PasscodeInvalidMessage,
                                                   options: regOption)
            loginSteps = [registerStep]// + EmailLoginSteps().steps
        }
        
        /* **************************************************************
         *  STEP (3): get permission to collect HealthKit data
         **************************************************************/
        // see `HealthDataStep` to configure!
        let healthDataStep = HealthDataStep(identifier: Constants.Identifier.HealthKitDataStep)
        
        /* **************************************************************
         *  STEP (3.5): get permission to collect HealthKit health records data
         **************************************************************/

        /* **************************************************************
         *  STEP (6): inform the user that they are done with sign-up!
         **************************************************************/
        // use the `ORKCompletionStep` from ResearchKit
        let completionStep = ORKCompletionStep(identifier: Constants.Identifier.CompletionStep)
        completionStep.title = YmlReader().completionStepTitle
        completionStep.text = YmlReader().completionStepText
        
        /* **************************************************************
         * finally, CREATE an array with the steps to show the user
         **************************************************************/
        
        // and steps regarding login / security
        let onboardingSteps = loginSteps + [healthDataStep, completionStep]
        
        // guide the user through ALL steps
        let fullSteps = introSteps + onboardingSteps
        
        /* **************************************************************
         * and SHOW the user these steps!
         **************************************************************/
        // create a task with each step
        let orderedTask = ORKOrderedTask(identifier: Constants.Identifier.StudyOnboardingTask, steps: fullSteps)
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator
        
        // & present the VC!
        return taskViewController
    }
    
}
