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
import OTFTemplateBox
import RawModel

extension StaticTaskOption {
    /**
     A task demonstrating how the ResearchKit framework can be used to present a simple
     survey with an introduction, a question, and a conclusion.
     */
    var surveyTask: ORKTask {
        // Create the intro step.
        let instructionStep = ORKInstructionStep(identifier: "introStep")
        instructionStep.title = "Simple Survey"
        instructionStep.text = exampleDescription
        instructionStep.detailText =
            "Please use this space to provide instructions for participants. Please make sure to provide enough information so that users can progress through the survey and complete with ease."

        let learnMoreInstructionStep = ORKLearnMoreInstructionStep(identifier: "LearnMoreInstructionStep01")
        learnMoreInstructionStep.title = "Learn more title"
        learnMoreInstructionStep.text = "Learn more text"

        let question1Step = ORKQuestionStep(
            identifier: "questionStep",
            title: "Questionnaire",
            question: "Would you like to subscribe to our newsletter?",
            answer: ORKBooleanAnswerFormat(),
            learnMoreItem: ORKLearnMoreItem(text: nil, learnMoreInstructionStep: learnMoreInstructionStep))
        question1Step.text = exampleDetailText

        // Add a question step with different layout format.
        let question2StepAnswerFormat = ORKAnswerFormat.dateAnswerFormat(withDefaultDate: nil, minimumDate: nil, maximumDate: Date(), calendar: nil)
        let question2 = "When is your birthday?"
        let question2Step = ORKQuestionStep(
            identifier: "birthdayQuestion",
            title: "Questionnaire",
            question: question2,
            answer: question2StepAnswerFormat)
        question2Step.text = exampleDetailText

        // Add a summary step.
        let summaryStep = ORKInstructionStep(identifier: "summaryStep")
        summaryStep.title = "Thanks"
        summaryStep.text = "Thank you for participating in this sample survey."

        return ORKOrderedTask(identifier: "surveyTask",
                              steps: [ instructionStep, question1Step, question2Step, summaryStep ])
    }

    /// This task presents just a single "Yes" / "No" question.
    var booleanQuestionTask: ORKTask {
        // We attach an answer format to a question step to specify what controls the user sees.
        let questionStep = ORKQuestionStep(
            identifier: "booleanQuestionStep",
            title: "Boolean",
            question: "Your question goes here.",
            answer: ORKBooleanAnswerFormat())
        // The detail text is shown in a small font below the title.
        questionStep.text = exampleDetailText
        return ORKOrderedTask(identifier: "booleanQuestionTask", steps: [questionStep])
    }

    /// This task presents a customized "Yes" / "No" question.
    var customBooleanQuestionTask: ORKTask {
        // We attach an answer format to a question step to specify what controls the user sees.
        let questionStep = ORKQuestionStep(
            identifier: "booleanQuestionStep",
            title: "Custom Boolean",
            question: "Your question goes here.",
            answer: ORKBooleanAnswerFormat(yesString: "Agree", noString: "Disagree"))
        // The detail text is shown in a small font below the title.
        questionStep.text = exampleDetailText
        return ORKOrderedTask(identifier: "booleanQuestionTask", steps: [questionStep])
    }

    /// This task demonstrates a question which asks for a date.
    var dateQuestionTask: ORKTask {
        /*
         The date answer format can also support minimum and maximum limits,
         a specific default value, and overriding the calendar to use.
         */

        let step = ORKQuestionStep(
            identifier: "dateQuestionStep",
            title: "Date",
            question: "Your question goes here.",
            answer: ORKAnswerFormat.dateAnswerFormat())

        step.text = exampleDetailText

        return ORKOrderedTask(identifier: "dateQuestionTask", steps: [step])
    }

    /// This task demonstrates a question asking for a date and time of an event.
    var dateTimeQuestionTask: ORKTask {
        /*
         This uses the default calendar. Use a more detailed constructor to
         set minimum / maximum limits.
         */
        let answerFormat = ORKAnswerFormat.dateTime()

        let step = ORKQuestionStep(
            identifier: "dateTimeQuestionStep",
            title: "Date and Time",
            question: "Your question goes here.",
            answer: answerFormat)

        step.text = exampleDetailText

        return ORKOrderedTask(identifier: "dateTimeQuestionTask", steps: [step])
    }

    /**
     This task demonstrates use of numeric questions with and without units.
     Note that the unit is just a string, prompting the user to enter the value
     in the expected unit. The unit string propagates into the result object.
     */
    var numericQuestionTask: ORKTask {
        // This answer format will display a unit in-line with the numeric entry field.
        let localizedQuestionStep1AnswerFormatUnit = "Your unit"
        let questionStep1AnswerFormat = ORKAnswerFormat.decimalAnswerFormat(withUnit: localizedQuestionStep1AnswerFormatUnit)

        let questionStep1 = ORKQuestionStep(
            identifier: "numericQuestionStep",
            title: "Numeric",
            question: "Your question goes here.",
            answer: questionStep1AnswerFormat)
        questionStep1.text = exampleDetailText
        questionStep1.placeholder = "Your placeholder here"

        // This answer format is similar to the previous one, but this time without displaying a unit.
        let questionStep2 = ORKQuestionStep(
            identifier: "numericNoUnitQuestionStep",
            title: "Numeric",
            question: "Your question goes here.",
            answer: ORKAnswerFormat.decimalAnswerFormat(withUnit: nil))
        questionStep2.text = exampleDetailText
        questionStep2.placeholder = "Placeholder without unit."
        return ORKOrderedTask(identifier: "numericQuestionTask", steps: [
            questionStep1,
            questionStep2
        ])
    }

    /// This task presents two options for questions displaying a scale control.
    var scaleQuestionTask: ORKTask {
        // The first step is a scale control with 10 discrete ticks.
        let stepTitle = "Scale"
        let step1AnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 1,
            defaultValue: NSIntegerMax,
            step: 1,
            vertical: false,
            maximumValueDescription: exampleHighValueText,
            minimumValueDescription: exampleLowValueText)
        let questionStep1 = ORKQuestionStep(
            identifier: "discreteScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step1AnswerFormat)
        questionStep1.text = "Discrete Scale"

        // The second step is a scale control that allows continuous movement with a percent formatter.
        let step2AnswerFormat = ORKAnswerFormat.continuousScale(
            withMaximumValue: 1.0,
            minimumValue: 0.0,
            defaultValue: 99.0,
            maximumFractionDigits: 0,
            vertical: false,
            maximumValueDescription: nil,
            minimumValueDescription: nil)
        step2AnswerFormat.numberStyle = .percent
        let questionStep2 = ORKQuestionStep(
            identifier: "continuousScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step2AnswerFormat)
        questionStep2.text = "Continuous Scale"

        // The third step is a vertical scale control with 10 discrete ticks.
        let step3AnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 1,
            defaultValue: NSIntegerMax,
            step: 1,
            vertical: true,
            maximumValueDescription: nil,
            minimumValueDescription: nil)
        let questionStep3 = ORKQuestionStep(
            identifier: "discreteVerticalScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step3AnswerFormat)
        questionStep3.text = "Discrete Vertical Scale"

        // The fourth step is a vertical scale control that allows continuous movement.
        let step4AnswerFormat = ORKAnswerFormat.continuousScale(
            withMaximumValue: 5.0,
            minimumValue: 1.0,
            defaultValue: 99.0,
            maximumFractionDigits: 2,
            vertical: true,
            maximumValueDescription: exampleHighValueText,
            minimumValueDescription: exampleLowValueText)
        let questionStep4 = ORKQuestionStep(
            identifier: "continuousVerticalScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step4AnswerFormat)
        questionStep4.text = "Continuous Vertical Scale"

        // The fifth step is a scale control that allows text choices.
        let textChoices: [ORKTextChoice] = [
            ORKTextChoice(text: "Poor", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Fair", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Good", value: 3 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Above Average", value: 10 as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: "Excellent", value: 5 as NSCoding & NSCopying & NSObjectProtocol)]
        let step5AnswerFormat = ORKAnswerFormat.textScale(with: textChoices, defaultIndex: NSIntegerMax, vertical: false)
        let questionStep5 = ORKQuestionStep(
            identifier: "textScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step5AnswerFormat)
        questionStep5.text = "Text Scale"

        // The sixth step is a vertical scale control that allows text choices.
        let step6AnswerFormat = ORKAnswerFormat.textScale(with: textChoices, defaultIndex: NSIntegerMax, vertical: true)
        let questionStep6 = ORKQuestionStep(
            identifier: "textVerticalScaleQuestionStep",
            title: stepTitle,
            question: "Your question goes here.",
            answer: step6AnswerFormat)
        questionStep6.text = "Text Vertical Scale"

        return ORKOrderedTask(identifier: "scaleQuestionTask", steps: [
            questionStep1,
            questionStep2,
            questionStep3,
            questionStep4,
            questionStep5,
            questionStep6
        ])
    }

    /**
     This task demonstrates asking for text entry. Both single and multi-line
     text entry are supported, with appropriate parameters to the text answer
     format.
     */
    var textQuestionTask: ORKTask {
        let answerFormat = ORKAnswerFormat.textAnswerFormat()
        answerFormat.multipleLines = true
        answerFormat.maximumLength = 280
        let step = ORKQuestionStep(
            identifier: "textQuestionStep",
            title: "Text",
            question: "Your question goes here.",
            answer: answerFormat)
        step.text = exampleDetailText
        return ORKOrderedTask(identifier: "textQuestionTask", steps: [step])
    }

    /**
     This task demonstrates a survey question for picking from a list of text
     choices. In this case, the text choices are presented in a table view
     (compare with the `valuePickerQuestionTask`).
     */
    var textChoiceQuestionTask: ORKTask {
        let textChoiceOneText = "Choice 1"
        let textChoiceTwoText = "Choice 2"
        let textChoiceThreeText = "Choice 3"
        let textChoiceFourText = "Other"
        // The text to display can be separate from the value coded for each choice:
        let textChoices = [
            ORKTextChoice(text: textChoiceOneText, value: "choice_1" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: textChoiceTwoText, value: "choice_2" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: textChoiceThreeText, value: "choice_3" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoiceOther.choice(
                withText: textChoiceFourText,
                detailText: nil,
                value: "choice_4" as NSCoding & NSCopying & NSObjectProtocol,
                exclusive: true,
                textViewPlaceholderText: "enter additional information")
        ]
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .singleChoice, textChoices: textChoices)
        let questionStep = ORKQuestionStep(
            identifier: "textChoiceQuestionStep",
            title: "Text Choice",
            question: "Your question goes here.",
            answer: answerFormat)
        questionStep.text = exampleDetailText
        return ORKOrderedTask(identifier: "textChoiceQuestionTask", steps: [questionStep])
    }

    /**
     This task demonstrates asking for text entry. Both single and multi-line
     text entry are supported, with appropriate parameters to the text answer
     format.
     */
    var validatedTextQuestionTask: ORKTask {
        let answerFormatEmail = ORKAnswerFormat.emailAnswerFormat()
        let stepEmail = ORKQuestionStep(
            identifier: "validatedTextQuestionStepEmail",
            title: "Validated Text",
            question: "Email",
            answer: answerFormatEmail)
        stepEmail.text = exampleDetailText

        let domainRegularExpressionPattern = "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
        let domainRegularExpression = try? NSRegularExpression(pattern: domainRegularExpressionPattern)
        let answerFormatDomain = ORKAnswerFormat.textAnswerFormat(withValidationRegularExpression: domainRegularExpression!, invalidMessage: "Invalid URL: %@")
        answerFormatDomain.multipleLines = false
        answerFormatDomain.keyboardType = .URL
        answerFormatDomain.autocapitalizationType = UITextAutocapitalizationType.none
        answerFormatDomain.autocorrectionType = UITextAutocorrectionType.no
        answerFormatDomain.spellCheckingType = UITextSpellCheckingType.no
        answerFormatDomain.textContentType = UITextContentType.URL
        let stepDomain = ORKQuestionStep(
            identifier: "validatedTextQuestionStepDomain",
            title: "Validated Text",
            question: "URL",
            answer: answerFormatDomain)
        stepDomain.text = exampleDetailText
        return ORKOrderedTask(identifier: "validatedTextQuestionTask", steps: [stepEmail, stepDomain])
    }

    /**
     This task demonstrates a survey question using a value picker wheel.
     Compare with the `textChoiceQuestionTask` and `imageChoiceQuestionTask`
     which can serve a similar purpose.
     */
    var valuePickerChoiceQuestionTask: ORKTask {
        let textChoiceOneText = "Choice 1"
        let textChoiceTwoText = "Choice 2"
        let textChoiceThreeText = "Choice 3"
        // The text to display can be separate from the value coded for each choice:
        let textChoices = [
            ORKTextChoice(text: textChoiceOneText, value: "choice_1" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: textChoiceTwoText, value: "choice_2" as NSCoding & NSCopying & NSObjectProtocol),
            ORKTextChoice(text: textChoiceThreeText, value: "choice_3" as NSCoding & NSCopying & NSObjectProtocol)
        ]
        let answerFormat = ORKAnswerFormat.valuePickerAnswerFormat(with: textChoices)
        let questionStep = ORKQuestionStep(
            identifier: "valuePickerChoiceQuestionStep",
            title: "Value Picker",
            question: "Your question goes here.",
            answer: answerFormat)
        questionStep.text = "Text Value picker"
        return ORKOrderedTask(identifier: "valuePickerChoiceQuestionTask", steps: [questionStep])
    }

    /// This task presents just a single location question.
    var locationQuestionTask: ORKTask {
        let answerFormat = ORKLocationAnswerFormat()
        // We attach an answer format to a question step to specify what controls the user sees.
        let questionStep = ORKQuestionStep(
            identifier: "locationQuestionStep",
            title: "Location",
            question: "Your question goes here.",
            answer: answerFormat)
        // The detail text is shown in a small font below the title.
        questionStep.text = exampleDetailText
        questionStep.placeholder = "Address"
        return ORKOrderedTask(identifier: "locationQuestionTask", steps: [questionStep])
    }

    /**
     This task demonstrates requesting a time interval. For example, this might
     be a suitable answer format for a question like "How long is your morning
     commute?"
     */
    var timeIntervalQuestionTask: ORKTask {
        /*
         The time interval answer format is constrained to entering a time
         less than 24 hours and in steps of minutes. For times that don't fit
         these restrictions, use another mode of data entry.
         */
        let answerFormat = ORKAnswerFormat.timeIntervalAnswerFormat()
        let step = ORKQuestionStep(
            identifier: "timeIntervalQuestionStep",
            title: "Time Interval",
            question: "Your question goes here.",
            answer: answerFormat)
        step.text = exampleDetailText
        return ORKOrderedTask(identifier: "timeIntervalQuestionTask", steps: [step])
    }

    /// This task demonstrates a question asking for a time of day.
    var timeOfDayQuestionTask: ORKTask {
        /*
         Because we don't specify a default, the picker will default to the
         time the step is presented. For questions like "What time do you have
         breakfast?", it would make sense to set the default on the answer
         format.
         */
        let answerFormat = ORKAnswerFormat.timeOfDayAnswerFormat()
        let questionStep = ORKQuestionStep(
            identifier: "timeOfDayQuestionStep",
            title: "Time",
            question: "Your question goes here.",
            answer: answerFormat)
        questionStep.text = exampleDetailText
        return ORKOrderedTask(
            identifier: "timeOfDayQuestionTask",
            steps: [questionStep])
    }
}
