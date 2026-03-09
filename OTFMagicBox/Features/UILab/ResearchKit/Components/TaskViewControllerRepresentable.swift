/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFResearchKit

struct TaskViewControllerRepresentable: UIViewControllerRepresentable {

    let task: ORKTask

    var waitStepViewController: ORKWaitStepViewController?
    var waitStepUpdateTimer: Timer?
    var waitStepProgress: CGFloat = 0.0

    var taskResultFinishedCompletionHandler: ((ORKResult) -> Void)?
    
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)

        taskViewController.delegate = context.coordinator
        if let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            taskViewController.outputDirectory = outputDirectory
        }

        return taskViewController
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ORKTaskViewControllerDelegate {

        var parent: TaskViewControllerRepresentable

        init(_ parent: TaskViewControllerRepresentable) {
            self.parent = parent
        }

        func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
            /*
             The `reason` passed to this method indicates why the task view
             controller finished: Did the user cancel, save, or actually complete
             the task; or was there an error?

             The actual result of the task is on the `result` property of the task
             view controller.
             */
            parent.taskResultFinishedCompletionHandler?(taskViewController.result)
            parent.dismiss()
        }

        func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {

            stepViewController.navigationController?.navigationBar.backgroundColor = .clear
            guard let stepId = stepViewController.step?.identifier else { return }

            switch TaskStepType(rawValue: stepId) {
            case .waitIndeterminate, .waitStep, .loginWaitStep:
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    (stepViewController as? ORKWaitStepViewController)?.goForward()
                }
            case .waitDeterminate:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let stepViewController = stepViewController as? ORKWaitStepViewController,
                       let stepUpdateTimer = self.parent.waitStepUpdateTimer {

                        self.parent.waitStepViewController = stepViewController
                        self.parent.waitStepProgress = 0.0
                        self.parent.waitStepUpdateTimer = Timer(
                            timeInterval: 0.1,
                            target: self,
                            selector: #selector(self.updateProgressOfWaitStepViewController),
                            userInfo: nil,
                            repeats: true
                        )
                        RunLoop.main.add(stepUpdateTimer, forMode: RunLoop.Mode.common)
                    }
                }
            case .none:
                break
            }
        }

        func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreButtonPressedWith learnMoreStep: ORKLearnMoreInstructionStep, for stepViewController: ORKStepViewController) {
            stepViewController.present(UINavigationController(rootViewController: ORKLearnMoreStepViewController(step: learnMoreStep)), animated: true) {
            }
        }

        @objc
        func updateProgressOfWaitStepViewController() {
            if let waitStepViewController = parent.waitStepViewController {
                parent.waitStepProgress += 0.01
                DispatchQueue.main.async {
                    waitStepViewController.setProgress(self.parent.waitStepProgress, animated: true)
                }
                if parent.waitStepProgress < 1.0 {
                    return
                } else {
                    parent.waitStepUpdateTimer?.invalidate()
                    waitStepViewController.goForward()
                    parent.waitStepViewController = nil
                }
            } else {
                parent.waitStepUpdateTimer?.invalidate()
            }
        }
    }
}

private enum TaskStepType: String {
    case waitIndeterminate = "WaitStepIndeterminate"
    case waitStep = "WaitStep"
    case loginWaitStep = "LoginWaitStep"
    case waitDeterminate = "WaitStepDeterminate"
}
