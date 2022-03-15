//
//  TaskView.swift
//  OTFCardioBox
//
//  Created by Asad Nawaz on 24/02/2022.
//

import Foundation
import SwiftUI
import OTFResearchKit

struct TaskViewControllerRepresentable: UIViewControllerRepresentable {
    let task: ORKTask
    
    var waitStepViewController: ORKWaitStepViewController?
    var waitStepUpdateTimer: Timer?
    var waitStepProgress: CGFloat = 0.0
    
    var taskResultFinishedCompletionHandler: ((ORKResult) -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    
    typealias UIViewControllerType = ORKTaskViewController
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        
        taskViewController.delegate = context.coordinator
        taskViewController.outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
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

            //taskViewController.dismiss(animated: true, completion: nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
            // Example data processing for the wait step.
            if stepViewController.step?.identifier == "WaitStepIndeterminate" ||
                stepViewController.step?.identifier == "WaitStep" ||
                stepViewController.step?.identifier == "LoginWaitStep" {
                delay(5.0, closure: { () -> Void in
                    if let stepViewController = stepViewController as? ORKWaitStepViewController {
                        stepViewController.goForward()
                    }
                })
            } else if stepViewController.step?.identifier == "WaitStepDeterminate" {
                delay(1.0, closure: { () -> Void in
                    if let stepViewController = stepViewController as? ORKWaitStepViewController {
                        self.parent.waitStepViewController = stepViewController
                        self.parent.waitStepProgress = 0.0
                        self.parent.waitStepUpdateTimer = Timer(timeInterval: 0.1, target: self, selector: #selector(TaskListViewController.updateProgressOfWaitStepViewController), userInfo: nil, repeats: true)
                        RunLoop.main.add(self.parent.waitStepUpdateTimer!, forMode: RunLoop.Mode.common)
                    }
                })
            }
        }
        
        func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreButtonPressedWith learnMoreStep: ORKLearnMoreInstructionStep, for stepViewController: ORKStepViewController) {
            //        FIXME: Temporary fix. This method should not be called if it is only used to present the learnMoreStepViewController, the stepViewController should present the learnMoreStepViewController.
            stepViewController.present(UINavigationController(rootViewController: ORKLearnMoreStepViewController(step: learnMoreStep)), animated: true) {
                
            }
        }
        
        
        func delay(_ delay: Double, closure: @escaping () -> Void ) {
            let delayTime = DispatchTime.now() + delay
            let dispatchWorkItem = DispatchWorkItem(block: closure)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: dispatchWorkItem)
        }
        
        @objc
        func updateProgressOfWaitStepViewController() {
            if let waitStepViewController = parent.waitStepViewController {
                parent.waitStepProgress += 0.01
                DispatchQueue.main.async(execute: { () -> Void in
                    waitStepViewController.setProgress(self.parent.waitStepProgress, animated: true)
                })
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
