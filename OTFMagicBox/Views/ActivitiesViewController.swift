//
//  ActivitiesViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

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
    
    private let fileName = Constants.yamlFile
    
    func makeCoordinator() -> OnboardingTaskViewControllerDelegate {
        OnboardingTaskViewControllerDelegate()
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
        
        /* **************************************************************
         *  STEP (3): get permission to collect HealthKit data
         **************************************************************/
        // see `HealthDataStep` to configure!
        let healthDataStep = HealthDataStep(identifier: Constants.Identifier.HealthKitDataStep)
        
        /* **************************************************************
         *  STEP (3.5): get permission to collect HealthKit health records data
         **************************************************************/
        let healthRecordsStep = HealthRecordsStep(identifier: Constants.Identifier.HealthRecordsStep)
        
        /* **************************************************************
         *  STEP (4): ask user to enter their email address for login
         **************************************************************/
        // the `LoginStep` collects and email address, and
        // the `LoginCustomWaitStep` waits for email verification.
        
        var loginSteps: [ORKStep]
        
        // swiftlint:disable all
        let regexp = try! NSRegularExpression(pattern: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[d$@$!%*?&#])[A-Za-z\\dd$@$!%*?&#]{10,}")
        
        let registration = YmlReader().registration
        
        var regOption = ORKRegistrationStepOption()
        
        if registration?.showDateOfBirth == "yes" {
            regOption.insert(.includeDOB)
        }
        
        if registration?.showGender == "yes" {
            regOption.insert(.includeGender)
        }
        regOption.insert( .includeGivenName)
        regOption.insert( .includeFamilyName)
        
        let registerStep = ORKRegistrationStep(identifier: Constants.Registration.Identifier, title: Constants.Registration.Title, text: Constants.Registration.Text, passcodeValidationRegularExpression: regexp, passcodeInvalidMessage: Constants.Registration.PasscodeInvalidMessage, options: regOption)
        
        if YmlReader().loginPasswordless{
            let loginStep = PasswordlessLoginStep(identifier: PasswordlessLoginStep.identifier)
            let loginVerificationStep = LoginCustomWaitStep(identifier: LoginCustomWaitStep.identifier)
            
            loginSteps = [loginStep, loginVerificationStep]
        } else {
            let loginStep = ORKLoginStep(identifier: Constants.Login.Identifier, title: Constants.Login.Title, text: Constants.Login.Text, loginViewControllerClass: LoginViewController.self)
            
            loginSteps = []
        }
        
        /* **************************************************************
         *  STEP (5): ask the user to create a security passcode
         *  that will be required to use this app!
         **************************************************************/
        // use the `ORKPasscodeStep` from ResearchKit.
        if YmlReader().isPasscodeEnabled {
            let passcodeStep = ORKPasscodeStep(identifier: Constants.Identifier.PasscodeStep)
        
            let type = YmlReader().passcodeType
            if type == Constants.Passcode.lengthSix {
                passcodeStep.passcodeType = .type6Digit
            } else {
                passcodeStep.passcodeType = .type4Digit
            }
        
            passcodeStep.text = YmlReader().passcodeText
            
            loginSteps += [passcodeStep]
        
        }
        
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
        
        // given intro steps that the user should review and consent to
        let introSteps: [ORKStep] = [consentStep, reviewConsentStep]
        
        // and steps regarding login / security
        let emailVerificationSteps = loginSteps + [healthDataStep, completionStep]
        
        // guide the user through ALL steps
        let fullSteps = introSteps + emailVerificationSteps
        
        // unless they have already gotten as far as to enter an email address
        let stepsToUse = fullSteps
        
        
        /* **************************************************************
         * and SHOW the user these steps!
         **************************************************************/
        // create a task with each step
        let orderedTask = ORKOrderedTask(identifier: Constants.Identifier.StudyOnboardingTask, steps: stepsToUse)
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator
        
        // & present the VC!
        return taskViewController
    }
    
}

