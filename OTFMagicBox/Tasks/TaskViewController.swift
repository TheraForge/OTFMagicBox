//
//  TaskViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 04.06.21.
//

import UIKit
import SwiftUI
import OTFResearchKit

struct TaskViewController: UIViewControllerRepresentable {
    
    let vc: ORKTaskViewController
    
    init(tasks: ORKOrderedTask) {
        self.vc = ORKTaskViewController(task: tasks, taskRun: NSUUID() as UUID)
       
    }

    typealias UIViewControllerType = ORKTaskViewController
    
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) { }
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        
       
        // & present the VC!
        return self.vc
    }
    
}
