//
//  PasswordlessLoginStep.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 01/09/21.
//

import ResearchKit

class PasswordlessLoginStep: ORKFormStep {
    
    static let identifier = "Login"
    
    static let idStepIdentifier = "IdStep"
    static let idConfirmStepIdentifier = "ConfirmIdStep"
    
    override init(identifier: String) {
        super.init(identifier: identifier)
        
        title = YmlReader().loginStepTitle()
        text = YmlReader().loginStepText()
        
        formItems = createFormItems()
        isOptional = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     This function creates a form with the exact email question to ask.
     
     - Returns a `ORKFormItem` array with questions to show.
    */
    fileprivate func createFormItems() -> [ORKFormItem] {
        let idStepTitle = "Email:"
        
        let titleStep = ORKFormItem(sectionTitle: "✉️ 🌎")
        
        let idQuestionStep = ORKFormItem(identifier: PasswordlessLoginStep.idStepIdentifier, text: idStepTitle, answerFormat: ORKEmailAnswerFormat(), optional: false)
        
        return [titleStep, idQuestionStep]
    }
    
}
