//
//  EmailLoginSteps.swift
//  OTFMagicBox
//
//  Created by Admin on 19/11/2021.
//

import Foundation
import OTFResearchKit

protocol LoginSteps {
    var steps: [ORKStep] { get }
}

struct EmailLoginSteps: LoginSteps {
    let steps: [ORKStep]
    
    public init() {
        var loginSteps: [ORKStep]
        
        let loginStep = ORKLoginStep(identifier: Constants.Login.Identifier, title: Constants.Login.Title,
                                     text: Constants.Login.Text, loginViewControllerClass: LoginViewController.self)
        
        loginSteps = [loginStep]
        
        // use the `ORKPasscodeStep` from ResearchKit.
        if YmlReader().isPasscodeEnabled {
            let passcodeStep = ORKPasscodeStep(identifier: "Passcode")
            
            let type = YmlReader().passcodeType
            
            if type == Constants.Passcode.lengthSix {
                passcodeStep.passcodeType = .type6Digit
            } else {
                passcodeStep.passcodeType = .type4Digit
            }
            
            passcodeStep.text = "Enter your passcode"
            
            loginSteps += [passcodeStep]
        }
        
        self.steps = loginSteps
    }
}

struct AppleLoginSteps: LoginSteps {
    let steps: [ORKStep]
    
    public init() {
        var loginSteps: [ORKStep]
        
        let appleLoginStep = SignInWithAppleStep(identifier: "SignInWithApple")
        
        loginSteps = [appleLoginStep]
        
        // use the `ORKPasscodeStep` from ResearchKit.
        if YmlReader().isPasscodeEnabled {
            let passcodeStep = ORKPasscodeStep(identifier: "Passcode")
            
            let type = YmlReader().passcodeType
            
            if type == Constants.Passcode.lengthSix {
                passcodeStep.passcodeType = .type6Digit
            } else {
                passcodeStep.passcodeType = .type4Digit
            }
            
            passcodeStep.text = "Enter your passcode"
            
            loginSteps += [passcodeStep]
        }
        
        self.steps = loginSteps
    }
}
