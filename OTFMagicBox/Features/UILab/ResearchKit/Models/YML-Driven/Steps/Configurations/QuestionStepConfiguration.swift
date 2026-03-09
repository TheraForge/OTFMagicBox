/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import Foundation
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct QuestionStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized
    var question: OTFStringLocalized

    var text: OTFStringLocalized?
    var answer: ResearchKitAnswerType

    var learnMore: LearnMoreItemConfiguration?
}

extension QuestionStepConfiguration {

    init(from raw: RawQuestionStepConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.question = raw.question ?? Self.fallback.question
        self.text = raw.text ?? Self.fallback.text
        self.answer = raw.answer ?? Self.fallback.answer
        self.learnMore = raw.learnMore ?? Self.fallback.learnMore
    }
    var step: ORKQuestionStep {

        let question = ORKQuestionStep(
            identifier: identifier,
            title: title.localized,
            question: question.localized,
            answer: answer.answerFormat,
            learnMoreItem: learnMore?.item)
        
        if let text {
            question.text = text.localized
        }

        return question
    }
}

extension QuestionStepConfiguration {

    static let fallback = QuestionStepConfiguration(
        identifier: "questionStep",
        title: "Questionnaire",
        question: "Would you like to subscribe to our newsletter?",
        text: "Additional text can go here.",
        answer: .boolean(.fallback),
        learnMore: LearnMoreItemConfiguration(
            learnMoreIdentifier: "learnMoreInstructionStep",
            learnMoreTitle: "Learn More Title",
            learnMoreText: "Learn More Text",
            text: nil
        )
    )
}

@RawGenerable
struct LearnMoreItemConfiguration: Codable {

    var learnMoreIdentifier: String

    var learnMoreTitle: OTFStringLocalized
    var learnMoreText: OTFStringLocalized
    var text: OTFStringLocalized?
}

extension LearnMoreItemConfiguration {

    var item: ORKLearnMoreItem {

        let step = ORKLearnMoreInstructionStep(identifier: learnMoreIdentifier)
        step.title = learnMoreTitle.localized
        step.text = learnMoreText.localized

        return ORKLearnMoreItem(text: text?.localized, learnMoreInstructionStep: step)
    }
}

#Preview {
    TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "question", steps: [QuestionStepConfiguration.fallback.step]))
}
