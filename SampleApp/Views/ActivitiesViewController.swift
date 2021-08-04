//
//  ActivitiesViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import SwiftUI
import UIKit
import ResearchKit

/**
 User activities to create a Digital Health Application.
 */
struct ActivitiesViewController: UIViewControllerRepresentable {
    
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
           // let consentStep = ORKVisualConsentStep(identifier: "VisualConsentStep", document: consentDocument)
            
            let signature = consentDocument.signatures?.first
            let reviewConsentStep = ORKConsentReviewStep(identifier: "ConsentReviewStep", signature: signature, in: consentDocument)
            reviewConsentStep.text = "Review Consent Step Text"
            reviewConsentStep.reasonForConsent = "Reason for Consent Text"
            let regexp = try! NSRegularExpression(pattern: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[d$@$!%*?&#])[A-Za-z\\dd$@$!%*?&#]{8,}")

            let registerStep = ORKRegistrationStep(identifier: "RegistrationStep", title: "Registration", text: "Sign up for this study.", passcodeValidationRegularExpression: regexp, passcodeInvalidMessage: "Your password does not meet the following criteria: minimum 8 characters with at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character", options: [])
            
            var loginSteps: [ORKStep]
            
            let loginStep = ORKLoginStep(identifier: "LoginStep", title: "Login", text: "Log into this study.", loginViewControllerClass: LoginViewController.self)
            
            loginSteps = [registerStep, loginStep]
            
            /* **************************************************************
            *  STEP (5): ask the user to create a security passcode
            *  that will be required to use this app!
            **************************************************************/
            // use the `ORKPasscodeStep` from ResearchKit.
            let passcodeStep = ORKPasscodeStep(identifier: "Passcode") //NOTE: requires NSFaceIDUsageDescription in info.plist
           
            passcodeStep.passcodeType = .type4Digit
        
            passcodeStep.text = "Enter 4 digit passcode"
  
            let completionStep = ORKCompletionStep(identifier: "CompletionStep")
            completionStep.title = "Completion Step Title"
            completionStep.text = "Completion Step Text"
            
            // and steps regarding login / security
            let emailVerificationSteps = loginSteps + [passcodeStep]
            
            // guide the user through ALL steps
            let fullSteps =  emailVerificationSteps
            
            // unless they have already gotten as far as to enter an email address
            let stepsToUse = fullSteps
            
            /* **************************************************************
            * and SHOW the user these steps!
            **************************************************************/
            // create a task with each step
            let orderedTask = ORKOrderedTask(identifier: "StudyOnboardingTask", steps: stepsToUse)
            
            // wrap that task on a view controller
            let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
            taskViewController.delegate = context.coordinator
            
            // & present the VC!
            return taskViewController
        }
        
    }
