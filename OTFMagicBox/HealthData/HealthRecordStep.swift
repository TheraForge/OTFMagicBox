//
//  HealthRecordStep.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 26/07/21.
//

import HealthKit
import OTFResearchKit

/**
 The Health Records Step will ask for a permission to collect HealthKit health records data of a patient.
 */
class HealthRecordsStep: ORKInstructionStep {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
        
        let recordsConfig = YmlReader().healthRecords
        
        title = recordsConfig?.permissionsTitle ?? Constants.YamlDefaults.HealthRecordsPermissionsTitle
        
        text = recordsConfig?.permissionsText ?? Constants.YamlDefaults.HealthRecordsPermissionsText
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class HealthRecordsStepViewController: ORKInstructionStepViewController {
    
    /**
     When this step is being dismissed, get `HealthKit`  authorization in the process.
     
     Relies on a `CKHealthDataStep` instance as `self.step`.
     */
    override func goForward() {
        let manager = HealthRecordsManager.shared
        manager.getAuth { succeeded, _ in
            if succeeded {
                manager.upload()
            }
            
            OperationQueue.main.addOperation {
                super.goForward()
            }
        }
    }
}
