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
        
        title = "Permission to read Activity Data"
        text = "Use this text to provide an explanation to your app participants about what activity data you intend to read from the Health app and why. This sample will read step count, distance, heart rate, and flights climbed data."
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

