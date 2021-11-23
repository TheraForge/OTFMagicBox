//
//  LoginExistingUserViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import Foundation
import SwiftUI
import UIKit
import OTFResearchKit

enum AuthMethod: String, CaseIterable, Codable {
    case email, apple
    
    var signinTitle: String {
        switch self {
        case .email:
            return "Sign in with email"
            
        case .apple:
            return "Sign in with Apple ID"
        }
    }
    
    var signupTitle: String {
        switch self {
        case .email:
            return "Sign up with email"
            
        case .apple:
            return "Sign up with Apple ID"
        }
    }
}

struct LoginExistingUserViewController: UIViewControllerRepresentable {
    
    let authMethod: AuthMethod
    
    func makeCoordinator() -> OnboardingTaskCoordinator {
        OnboardingTaskCoordinator(authMethod: authMethod, authType: .signin)
    }
    
    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
        let loginSteps: LoginSteps = authMethod == .apple ? AppleLoginSteps() : EmailLoginSteps()
        // create a task with each step
        let orderedTask = ORKOrderedTask(identifier: "StudyLoginTask", steps: loginSteps.steps)
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator // enables `ORKTaskViewControllerDelegate` below
        
        // & present the VC!
        return taskViewController
    }
    
}

