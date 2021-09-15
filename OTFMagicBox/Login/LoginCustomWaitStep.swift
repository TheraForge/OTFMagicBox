//
//  LoginCustomWaitStep.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 14/09/21.
//

import Foundation
import OTFResearchKit

class LoginCustomWaitStep: ORKStep {
    
    static let identifier = "LoginCustomWaitStep"
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
