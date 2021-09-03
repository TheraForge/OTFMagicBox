//
//  HealthDataStep.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 31.05.21.
//

import ResearchKit


/**
 The Health data step of the patient.
 */
class HealthDataStep: ORKInstructionStep {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
        
        title = YmlReader().healthPermissionsTitle()
        text = YmlReader().healthPermissionsText()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/**
 This class was created to override the `goForward` functionality.
 */
class HealthDataStepViewController: ORKInstructionStepViewController {
    
    override func goForward() {
        let manager = OTFHealthKitManager.shared
        manager.getHealthAuthorization() { _,_ in
            OperationQueue.main.addOperation {
                super.goForward()
            }
        }
    }
}
