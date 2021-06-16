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
            
        // User consent document.
        let consentDocument = ConsentDocument()
        
        let consentStep = ORKVisualConsentStep(identifier: "VisualConsentStep", document: consentDocument)
        
        // User login activity step.
        var loginSteps: [ORKStep]
        
        let loginStep = ORKLoginStep(identifier: "LoginStep", title: "Login", text: "Enter your login credentials.", loginViewControllerClass: LoginViewController.self)
        
        loginSteps = [loginStep]
        
        // User passcode activity step.
        let passcodeStep = ORKPasscodeStep(identifier: "Passcode") //NOTE: requires NSFaceIDUsageDescription in info.plist
       
        passcodeStep.passcodeType = .type4Digit
    
        passcodeStep.text = "Enter 4 digit passcode"
        
        // User health data authorization step.
        let healthDataStep = HealthDataStep(identifier: "Healthkit")
        
        // User permission to read health records.
        let healthRecordsStep = HealthRecordsStep(identifier: "HealthRecords")
        
        // User activity completion step.
        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "You have completed your activities."
        completionStep.text = "Thank you"
        
       
        let consentActivityStep: [ORKStep] = [consentStep]
        
        let otherActivitySteps =  loginSteps + [healthDataStep, healthRecordsStep, completionStep]
        
        let activitiesSteps = consentActivityStep + otherActivitySteps
        
        let orderedTask = ORKOrderedTask(identifier: "OTFOnboardTask", steps: activitiesSteps)
        
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator
      
        return taskViewController
    }
    
}
