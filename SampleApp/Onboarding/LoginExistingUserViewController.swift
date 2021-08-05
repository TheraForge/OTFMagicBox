//
//  LoginExistingUserViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import Foundation
import SwiftUI
import UIKit
import ResearchKit

struct LoginExistingUserViewController: UIViewControllerRepresentable {
    
    func makeCoordinator() -> OnboardingTaskViewControllerDelegate {
        OnboardingTaskViewControllerDelegate()
    }

    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
        var loginSteps: [ORKStep]
        
        let loginStep = ORKLoginStep(identifier: "LoginExistingStep", title: "Login", text: "Log into this study.", loginViewControllerClass:        LoginViewController.self)
            
        loginSteps = [loginStep]
        
        // use the `ORKPasscodeStep` from ResearchKit.
        let passcodeStep = ORKPasscodeStep(identifier: "Passcode") //NOTE: requires NSFaceIDUsageDescription in info.plist
            passcodeStep.passcodeType = .type6Digit
        
        passcodeStep.text = "Enter your 6 digit passcode"
        
        loginSteps += [passcodeStep]
        
        // create a task with each step
        let orderedTask = ORKOrderedTask(identifier: "StudyLoginTask", steps: loginSteps)
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator // enables `ORKTaskViewControllerDelegate` below
        
        // & present the VC!
        return taskViewController
    }
    
}

