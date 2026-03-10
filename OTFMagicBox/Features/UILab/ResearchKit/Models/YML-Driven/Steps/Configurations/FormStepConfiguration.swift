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
//

import Foundation
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct FormStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized
    var text: OTFStringLocalized

    var items: [FormItemConfiguration]
}

extension FormStepConfiguration {

    init(from raw: RawFormStepConfiguration) {
        let fallback = Self.fallback
        self.identifier = raw.identifier ?? fallback.identifier
        self.title = raw.title ?? fallback.title
        self.text = raw.text ?? fallback.text
        self.items = raw.items ?? []
    }

    var step: ORKFormStep {
        let step = ORKFormStep(
            identifier: identifier,
            title: title.localized,
            text: text.localized
        )
        step.formItems = items.map { $0.item }
        return step
    }
}

extension FormStepConfiguration {

    static let fallback = FormStepConfiguration(
        identifier: "formStep",
        title: "Form Step",
        text: "Additional text can go here.",
        items: [
            // Apple choices, single choice.
            .init(
                identifier: "appleFormItemIdentifier",
                text: "Which is your favorite apple?",
                detailText: nil,
                placeholder: nil,
                tagText: nil,
                showsProgress: nil,
                optional: nil,
                learnMore: nil,
                answer: .textChoiceAnswer(
                    TextChoiceAnswerFormatConfiguration(style: .single, textChoices: [
                        "Granny Smith",
                        "Honeycrisp",
                        "Fuji",
                        "McIntosh",
                        "Kanzi"
                    ])
                )
            ),
            // Continuous scale example
            .init(
                identifier: "formItem03",
                text: "Your question goes here.",
                detailText: nil,
                placeholder: nil,
                tagText: nil,
                showsProgress: nil,
                optional: true,
                learnMore: nil,
                answer: .scale(.fallback) // Replace with proper scale if desired
            ),
            // Text scale example
            .init(
                identifier: "formItem04",
                text: "Your question goes here.",
                detailText: nil,
                placeholder: nil,
                tagText: nil,
                showsProgress: nil,
                optional: nil,
                learnMore: nil,
                answer: .textScale(.fallback)
            ),
            // Integer field
            .init(
                identifier: "formItem01",
                text: "Field01",
                detailText: nil,
                placeholder: "Your placeholder here",
                tagText: nil,
                showsProgress: nil,
                optional: nil,
                learnMore: nil,
                answer: .integer(.fallback)
            ),
            // Time interval field
            .init(
                identifier: "formItem02",
                text: "Field02",
                detailText: nil,
                placeholder: "Your placeholder here",
                tagText: nil,
                showsProgress: nil,
                optional: nil,
                learnMore: nil,
                answer: .timeInterval(.fallback)
            )
        ]
    )
}

@RawGenerable
struct FormItemConfiguration: Codable {

    var identifier: String
    var text: OTFStringLocalized
    var detailText: OTFStringLocalized?

    // Placeholder is only supported by certain formats; we expose it optionally.
    var placeholder: OTFStringLocalized?

    // Extended initializer variant support (mirrors ORKFormItem init with detail/learnMore/showsProgress/tag/optional)
    var tagText: OTFStringLocalized?
    var showsProgress: Bool?
    var optional: Bool?

    var learnMore: LearnMoreItemConfiguration?

    var answer: ResearchKitAnswerType
}

extension FormItemConfiguration {

    init(from raw: RawFormItemConfiguration) {
        // Build a minimal fallback for a single integer item
        let fallback = FormItemConfiguration(
            identifier: "formItem",
            text: "Item",
            detailText: nil,
            placeholder: nil,
            tagText: nil,
            showsProgress: nil,
            optional: nil,
            learnMore: nil,
            answer: .integer(.fallback)
        )
        self.identifier = raw.identifier ?? fallback.identifier
        self.text = raw.text ?? fallback.text
        self.detailText = raw.detailText ?? fallback.detailText
        self.placeholder = raw.placeholder ?? fallback.placeholder
        self.tagText = raw.tagText ?? fallback.tagText
        self.showsProgress = raw.showsProgress ?? fallback.showsProgress
        self.optional = raw.optional ?? fallback.optional
        self.learnMore = raw.learnMore ?? fallback.learnMore
        self.answer = raw.answer ?? fallback.answer
    }

    var item: ORKFormItem {
        // Choose initializer based on whether extended fields are present.
        var formItem: ORKFormItem
        if detailText != nil || learnMore != nil || showsProgress != nil || tagText != nil || optional != nil {
            formItem = ORKFormItem(
                identifier: identifier,
                text: text.localized,
                detailText: detailText?.localized,
                learnMoreItem: learnMore?.item,
                showsProgress: showsProgress ?? false,
                answerFormat: answer.answerFormat,
                tagText: tagText?.localized,
                optional: optional ?? true
            )
        } else {
            formItem = ORKFormItem(
                identifier: identifier,
                text: text.localized,
                answerFormat: answer.answerFormat
            )
        }
        if let placeholder = placeholder?.localized {
            formItem.placeholder = placeholder
        }
        return formItem
    }
}

#Preview {
    TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "form", steps: [FormStepConfiguration.fallback.step]))
}
