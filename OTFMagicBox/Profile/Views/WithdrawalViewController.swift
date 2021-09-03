//
//  WithdrawalViewController.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 30/08/21.
//

import UIKit
import SwiftUI
import ResearchKit

struct WithdrawalViewController: UIViewControllerRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
        let instructionStep = ORKInstructionStep(identifier: "WithdrawlInstruction")
        instructionStep.title = YmlReader().withdrawl()?.withdrawalInstructionTitle
        instructionStep.text = YmlReader().withdrawl()?.withdrawalInstructionText
        
        let completionStep = ORKCompletionStep(identifier: "Withdraw")
        completionStep.title = YmlReader().withdrawl()?.withdrawTitle
        completionStep.text = YmlReader().withdrawl()?.withdrawText
        
        let withdrawTask = ORKOrderedTask(identifier: "Withdraw", steps: [instructionStep, completionStep])
        
        // wrap that task on a view controller
        let taskViewController = ORKTaskViewController(task: withdrawTask, taskRun: nil)
        
        taskViewController.delegate = context.coordinator // enables `ORKTaskViewControllerDelegate` below
        
        // & present the VC!
        return taskViewController

    }

    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
            switch reason {
            case .completed:
                
                    if (ORKPasscodeViewController.isPasscodeStoredInKeychain()) {
                        ORKPasscodeViewController.removePasscodeFromKeychain()
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name(Constants.onboardingDidComplete), object: false)

                    UserDefaults.standard.set(nil, forKey: Constants.prefCareKitDataInitDate)
                    UserDefaults.standard.set(nil, forKey: Constants.prefHealthRecordsLastUploaded)
                    UserDefaults.standard.set(false, forKey: Constants.onboardingDidComplete)
                
                fallthrough
            default:
                
                // otherwise dismiss onboarding without proceeding.
                taskViewController.dismiss(animated: true, completion: nil)
                
            }
        }
    }
    
}

