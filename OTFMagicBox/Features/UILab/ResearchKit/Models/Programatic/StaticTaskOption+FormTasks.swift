/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Macro Yau.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import OTFResearchKit
import HealthKit
import UIKit

extension StaticTaskOption {
    /**
     This task demonstrates a form step, in which multiple items are presented
     in a single scrollable form. This might be used for entering multi-value
     data, like taking a blood pressure reading with separate systolic and
     diastolic values.
     */
    var formTask: ORKTask {
        let step = ORKFormStep(
            identifier: "formStep",
            title: "Form Step",
            text: "Additional text can go here."
        )

        // A first field, for entering an integer.
        let formItem01Text = "Field01"
        let formItem01 = ORKFormItem(
            identifier: "formItem01",
            text: formItem01Text,
            answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: nil)
        )
        formItem01.placeholder = "Your placeholder here"

        // A second field, for entering a time interval.
        let formItem02Text = "Field02"
        let formItem02 = ORKFormItem(
            identifier: "formItem02",
            text: formItem02Text,
            answerFormat: ORKTimeIntervalAnswerFormat()
        )
        formItem02.placeholder = "Your placeholder here"

        // A third field, scale.
        let formItem03Text = "Your question goes here."
        let scaleAnswerFormat = ORKScaleAnswerFormat(maximumValue: 10, minimumValue: 0, defaultValue: 0, step: 1)
        scaleAnswerFormat.shouldHideRanges = true
        let formItem03 = ORKFormItem(
            identifier: "formItem03",
            text: formItem03Text,
            answerFormat: scaleAnswerFormat
        )

        // A fourth field, text scale with choices.
        let textChoices: [ORKTextChoice] = [
            ORKTextChoice(text: "choice 1", detailText: "detail 1", value: 1 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "choice 2", detailText: "detail 2", value: 2 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "choice 3", detailText: "detail 3", value: 3 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "choice 4", detailText: "detail 4", value: 4 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "choice 5", detailText: "detail 5", value: 5 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "choice 6", detailText: "detail 6", value: 6 as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        ]
        let textScaleAnswerFormat = ORKTextScaleAnswerFormat(textChoices: textChoices, defaultIndex: 10)
        textScaleAnswerFormat.shouldHideLabels = true
        textScaleAnswerFormat.shouldShowDontKnowButton = true
        let formItem04 = ORKFormItem(
            identifier: "formItem04",
            text: "Your question goes here.",
            answerFormat: textScaleAnswerFormat
        )

        // Apple choices, single choice.
        let appleChoices: [ORKTextChoice] = [
            ORKTextChoice(text: "Granny Smith", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Honeycrisp", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Fuji", value: 3 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "McIntosh", value: 10 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Kanzi", value: 5 as NSCoding & NSCopying & NSObjectProtocol)
        ]
        let appleAnswerFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: appleChoices)
        let appleFormItem = ORKFormItem(
            identifier: "appleFormItemIdentifier",
            text: "Which is your favorite apple?",
            answerFormat: appleAnswerFormat
        )

        step.formItems = [ appleFormItem, formItem03, formItem04, formItem01, formItem02 ]

        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "All Done!"
        completionStep.detailText = "You have completed the questionnaire."

        return ORKOrderedTask(
            identifier: "formTask",
            steps: [step, completionStep]
        )
    }

    var groupedFormTask: ORKTask {
        let step = ORKFormStep(
            identifier: "groupedFormStep",
            title: "Form Step",
            text: "Your question goes here."
        )

        // Start of first section
        let learnMoreInstructionStep01 = ORKLearnMoreInstructionStep(identifier: "LearnMoreInstructionStep01")
        learnMoreInstructionStep01.title = "Learn more title"
        learnMoreInstructionStep01.text = "Learn more text"
        let learnMoreItem01 = ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStep01)

        let section01 = ORKFormItem(
            sectionTitle: "Section title",
            detailText: "Section detail text",
            learnMoreItem: learnMoreItem01,
            showsProgress: true
        )

        // A first field, for entering an integer.
        let formItem01Text = "Field01"
        let formItem01 = ORKFormItem(
            identifier: "formItem01",
            text: formItem01Text,
            answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: nil)
        )
        formItem01.placeholder = "Your placeholder here"

        // A second field, for entering a time interval.
        let formItem02Text = "Field02"
        let formItem02 = ORKFormItem(
            identifier: "formItem02",
            text: formItem02Text,
            answerFormat: ORKTimeIntervalAnswerFormat()
        )
        formItem02.placeholder = "Your placeholder here"

        // Socioeconomic ladder.
        let sesAnswerFormat = ORKSESAnswerFormat(topRungText: "Best Off", bottomRungText: "Worst Off")
        let sesFormItem = ORKFormItem(
            identifier: "sesIdentifier",
            text: "Select where you are on the socioeconomic ladder.",
            answerFormat: sesAnswerFormat
        )

        // Start of section for scale question.
        let formItem03Text = "Your question goes here."
        let scaleAnswerFormat = ORKContinuousScaleAnswerFormat(
            maximumValue: 10,
            minimumValue: 0,
            defaultValue: 0.0,
            maximumFractionDigits: 1
        )
        let formItem03 = ORKFormItem(
            identifier: "formItem03",
            text: formItem03Text,
            detailText: nil,
            learnMoreItem: nil,
            showsProgress: true,
            answerFormat: scaleAnswerFormat,
            tagText: nil,
            optional: true
        )

        step.formItems = [ section01, formItem01, formItem02, formItem03, sesFormItem ]

        // Add a question step.
        let question1StepAnswerFormat = ORKBooleanAnswerFormat()
        let question1 = "Would you like to subscribe to our newsletter?"

        let learnMoreInstructionStep = ORKLearnMoreInstructionStep(identifier: "LearnMoreInstructionStep01")
        learnMoreInstructionStep.title = "Learn more title"
        learnMoreInstructionStep.text = "Learn more text"
        let learnMoreItem = ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStep)

        let question1Step = ORKQuestionStep(
            identifier: "questionStep",
            title: "Questionnaire",
            question: question1,
            answer: question1StepAnswerFormat,
            learnMoreItem: learnMoreItem
        )
        question1Step.text = exampleDetailText

        // Add a question step with different layout format.
        let question2StepAnswerFormat = ORKAnswerFormat.dateAnswerFormat(
            withDefaultDate: nil,
            minimumDate: nil,
            maximumDate: Date(),
            calendar: nil
        )
        let question2 = "When is your birthday?"
        let question2Step = ORKQuestionStep(
            identifier: "birthdayQuestion",
            title: "Questionnaire",
            question: question2,
            answer: question2StepAnswerFormat
        )
        question2Step.text = exampleDetailText

        // Apple picker as a separate step.
        let groupedAppleChoices: [ORKTextChoice] = [
            ORKTextChoice(text: "Granny Smith", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Honeycrisp", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Fuji", value: 3 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "McIntosh", value: 10 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Kanzi", value: 5 as NSCoding & NSCopying & NSObjectProtocol)
        ]
        let appleAnswerFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: groupedAppleChoices)
        let appleFormItem = ORKFormItem(
            identifier: "appleFormItemIdentifier",
            text: "Which is your favorite apple?",
            answerFormat: appleAnswerFormat
        )
        let appleFormStep = ORKFormStep(
            identifier: "appleFormStepIdentifier",
            title: "Fruit!",
            text: "Select the fruit you like."
        )
        appleFormStep.formItems = [appleFormItem]

        return ORKOrderedTask(
            identifier: "groupedFormTask",
            steps: [step, question1Step, question2Step, appleFormStep]
        )
    }
}
