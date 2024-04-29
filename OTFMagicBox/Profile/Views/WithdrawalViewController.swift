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

import UIKit
import SwiftUI
import OTFResearchKit

struct WithdrawalViewController: UIViewControllerRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    typealias UIViewControllerType = ORKTaskViewController

    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    func makeUIViewController(context: Context) -> ORKTaskViewController {

        let instructionStep = ORKInstructionStep(identifier: "WithdrawlInstruction")
        instructionStep.title = ModuleAppYmlReader().withdrawl?.withdrawalInstructionTitle
        instructionStep.text = ModuleAppYmlReader().withdrawl?.withdrawalInstructionText

        let completionStep = ORKCompletionStep(identifier: "Withdraw")
        completionStep.title = ModuleAppYmlReader().withdrawl?.withdrawTitle
        completionStep.text = ModuleAppYmlReader().withdrawl?.withdrawText

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
                if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
                    ORKPasscodeViewController.removePasscodeFromKeychain()
                }
                UserDefaultsManager.setOnboardingCompleted(false)
                UserDefaults.standard.set(nil, forKey: Constants.prefCareKitDataInitDate)
                UserDefaults.standard.set(nil, forKey: Constants.prefHealthRecordsLastUploaded)

                NotificationCenter.default.post(name: .onboardingDidComplete, object: false)

                try? CareKitStoreManager.shared.wipe()

                fallthrough
            default:
                // otherwise dismiss onboarding without proceeding.
                taskViewController.dismiss(animated: true, completion: nil)
            }
        }
    }
}
