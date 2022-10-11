//
//  SurveyViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/24/22.
//

import Foundation
import OTFResearchKit
import OTFCareKitStore

class SurveyViewModel: ObservableObject {
    @Published var cards: [SurveyCard] = []
    @Published var allSurveysTaken: Bool = false
    var cardToPresent: SurveyCard?
    var storeManager: OCKStoreManager = OCKStoreManager.shared
    
    let medicationSurvey = (index: 0, identifier: "medicationTask")
    let conditionSurvey = (index: 1, identifier: "conditionTask")
    
    init() {
        cards = [SurveyCard(title: "Tell us how are you feeling after medications", buttonTitle: "I am Feeling ..", surveyTask: conditionTask, action: { self.cards[0].isAlreadyTaken = true; print("i am feeeling") ; self.checkAreAllSurveysTaken() }), SurveyCard(title: "Did Freeze of Gait occur today?", buttonTitle: "Report", surveyTask: medicationTask, action:  { self.cards[1].isAlreadyTaken = true ;print("Report") ; self.checkAreAllSurveysTaken()})]
        
        checkForStoredSurveys()
    }
    
    func checkForStoredSurveys() {
        let date = Date()
        let calendar = Calendar.current
        let startTime = calendar.startOfDay(for: date)
        let endTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startTime)
        let outcomeQuery = OCKOutcomeQuery(dateInterval: DateInterval(start: startTime, end: endTime!))
        storeManager.coreDataStore.fetchOutcomes(query: outcomeQuery, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let outcomes):
                for outcome in outcomes {
                    print("outcome ", outcome.groupIdentifier)
                    if outcome.groupIdentifier == self.conditionSurvey.identifier {
                        self.cards[self.conditionSurvey.index].action?()
                    } else if outcome.groupIdentifier == self.medicationSurvey.identifier {
                        self.cards[self.medicationSurvey.index].action?()
                    }
                }
                self.checkAreAllSurveysTaken()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func checkAreAllSurveysTaken() {
        allSurveysTaken = cards.filter({!$0.isAlreadyTaken}).count == 0
    }
    
    func getTaskViewController(for task: ORKTask) -> TaskViewControllerRepresentable {
        var controller = TaskViewControllerRepresentable(task: task)
        controller.taskDidFinishWithResultCompletionHandler = gotSurveyResult
        return controller
    }
    
    func gotSurveyResult(result: ORKResult, childrenResults: [ORKResult]?) {
        let index = cards.firstIndex(where: {$0.id == cardToPresent?.id})
        guard let index = index else {
            return
        }
        cards[index].isAlreadyTaken = true
        checkAreAllSurveysTaken()
        if result.identifier == medicationTask.identifier, let results = childrenResults {
            storeMedicationOutcome(from: results)
        } else if result.identifier == conditionTask.identifier, let results = childrenResults {
            storeConditionOutcome(from: results)
        }
    }
    
    func storeConditionOutcome(from results: [ORKResult]) {
        var outcomeValues: [OCKOutcomeValue] = []
        if let resultValue = ((results.first(where: { $0.identifier == "conditionExamStep"}) as? ORKStepResult)?.results?.first as? ORKScaleQuestionResult)?.scaleAnswer {
            let outcome = OCKOutcomeValue(Double(truncating: resultValue))
            outcomeValues.append(outcome)
        }
        
        if let resultValue = ((results.first(where: { $0.identifier == "conditionQuestionOneStep"}) as? ORKStepResult)?.results?.first as? ORKBooleanQuestionResult)?.booleanAnswer {
            let outcome = OCKOutcomeValue(Int(truncating: resultValue))
            outcomeValues.append(outcome)
        }
        storeOutcome(outcomeValues, for: conditionSurvey.identifier)
    }
    
    func storeMedicationOutcome(from results: [ORKResult]) {
        var outcomeValues: [OCKOutcomeValue] = []
        if let resultValue = ((results.first(where: { $0.identifier == "medicationQuestionOneStep" }) as? ORKStepResult)?.results?.first as? ORKBooleanQuestionResult)?.booleanAnswer {
            let outcome = OCKOutcomeValue(Int(truncating: resultValue))
            outcomeValues.append(outcome)
        }
        
        if let resultValue = ((results.first(where: { $0.identifier == "medicationQuestionTwoStep" }) as? ORKStepResult)?.results?.first as? ORKBooleanQuestionResult)?.booleanAnswer {
            let outcome = OCKOutcomeValue(Int(truncating: resultValue))
            outcomeValues.append(outcome)
        }
        storeOutcome(outcomeValues, for: medicationSurvey.identifier)
    }
    
    func storeOutcome(_ outcomeValues: [OCKOutcomeValue], for identifier: String) {
        var outcome = OCKOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: outcomeValues)
        outcome.groupIdentifier = identifier
        outcome.createdDate = Date()
        storeManager.coreDataStore.addOutcome(outcome) { result in
            switch result {
            case .success(let outcome):
                print("outcome stored: ", outcome.groupIdentifier)
            case .failure(let error):
                print("outcome storing failed: ", error.localizedDescription)
            }
        }
    }
    
    private var conditionTask: ORKTask {
        let formStep = ORKFormStep(identifier: "conditionExamStep", title: "Daily checkup", text: "Please slide bar which best describe your todays state.")
        
        let scaleAnswerFormat = ORKScaleAnswerFormat(maximumValue: 5, minimumValue: 0, defaultValue: 3, step: 1, vertical: false, maximumValueDescription: "No Tremor", minimumValueDescription: "Intense Tremor")
        scaleAnswerFormat.shouldHideRanges = false
        let formItem = ORKFormItem(identifier: "conditionExamStepItem", text: "How do you feel today?", answerFormat: scaleAnswerFormat)
        formItem.detailText = "Move slider to select value"
        formItem.isOptional = false
        
        formStep.formItems = [formItem]
        
        let learnMoreInstructionStep = ORKLearnMoreInstructionStep(identifier: "conditionQuestionOneLearnMoreStep")
        learnMoreInstructionStep.title = "Yes/No Question"
        learnMoreInstructionStep.text = "This is simple question with Yes or No answer. This specificaly ask you wether Freeze of Gait have occured today."
        let learnMoreItem = ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStep)
        
        let questionOneStep = ORKQuestionStep(identifier: "conditionQuestionOneStep", title: "FoG Checkup", question: "Did Freeze of Gait occur today?", answer: ORKBooleanAnswerFormat(), learnMoreItem: learnMoreItem)
        questionOneStep.isOptional = false
        
        let completionStep = ORKCompletionStep(identifier: "conditionCompletionStep")
        completionStep.title = "Daily check Complete"
        completionStep.text = "Thank you for your answer. It will be analyzed and it will, hopefully, help you and others to successfully get over it."
        
        return ORKOrderedTask(identifier: "conditionTask", steps: [ formStep, questionOneStep, completionStep])
    }
    
    private var medicationTask: ORKTask {
//        let instructionStep = ORKInstructionStep(identifier: "")
//        instructionStep.title = ""
//        instructionStep.text = ""
//        instructionStep.image = UIImage(named: "")
//        instructionStep.imageContentMode = .center
//        instructionStep.detailText = ""
        
        let learnMoreInstructionStepOne = ORKLearnMoreInstructionStep(identifier: "medicationQuestionOneLearnMoreStep")
        learnMoreInstructionStepOne.title = "Yes/No Question"
        learnMoreInstructionStepOne.text = "This is simple question with Yes or No answer. This specificaly ask you wether Freeze of Gait have occured today."
        let learnMoreItemOne = ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStepOne)
        
        let questionOneStep = ORKQuestionStep(identifier: "medicationQuestionOneStep", title: "FoG Checkup", question: "Did Freeze of Gait occur today?", answer: ORKBooleanAnswerFormat(), learnMoreItem: learnMoreItemOne)
        questionOneStep.isOptional = false
        
        let learnMoreInstructionStepTwo = ORKLearnMoreInstructionStep(identifier: "medicationQuestionTwoLearnMoreStep")
        learnMoreInstructionStepTwo.title = "Yes/No Question"
        learnMoreInstructionStepTwo.text = "This is simple question with Yes or No answer. This specificaly ask you wether you have took all the medications what your doctor have given to you."
        let learnMoreItemTwo = ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStepTwo)
        
        let questionTwoStep = ORKQuestionStep(identifier: "medicationQuestionTwoStep", title: "FoG Checkup reasons", question: "Have you took your prescribed medications?", answer: ORKBooleanAnswerFormat(), learnMoreItem: learnMoreItemTwo)
        
        questionTwoStep.isOptional = false
        
        let completionStep = ORKCompletionStep(identifier: "conditionCompletionStep")
        completionStep.title = "FoG Checkup Complete"
        completionStep.text = "Thank you for your answer. It will be analyzed and it will, hopefully, help you and others to successfully get over it."
        
        return ORKOrderedTask(identifier: "medicationTask", steps: [ questionOneStep, questionTwoStep, completionStep])
    }
}

struct SurveyCard: Identifiable {
    var id: UUID = UUID()
    var title: String
    var buttonTitle: String
    var isAlreadyTaken: Bool = false
    var surveyTask: ORKTask
    var action: (() -> Void)?
}
