/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFResearchKit
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("ResearchKit answer construction")
struct ResearchKitAnswerConstructionTests {
    @Test("Boolean answer configuration builds localized ORK answer format")
    func booleanAnswerConfigurationBuildsORKAnswerFormat() throws {
        let answer = ResearchKitAnswerType.boolean(BooleanAnswerFormatConfiguration(
            yesString: "Absolutely",
            noString: "Not today"
        ))

        let format = try #require(answer.answerFormat as? ORKBooleanAnswerFormat)

        #expect(format.yes == "Absolutely")
        #expect(format.no == "Not today")
    }

    @Test("Text answer configuration builds max length format with all text traits")
    func textAnswerConfigurationBuildsMaxLengthFormatWithAllTextTraits() {
        let configuration = TextAnswerFormatConfiguration(
            validationPattern: nil,
            invalidMessage: nil,
            maximumLength: 24,
            multipleLines: false,
            placeholder: "Username",
            defaultTextAnswer: "guest",
            hideClearButton: true,
            hideCharacterCountLabel: true,
            keyboardType: .emailAddress,
            autocapitalizationType: AutocapitalizationStyle.none,
            autocorrectionType: .no,
            spellCheckingType: .no,
            textContentType: UITextContentType.username.rawValue,
            secureTextEntry: true,
            passwordRules: "required: upper; minlength: 8;"
        )

        let format = configuration.answerFormat

        #expect(format.maximumLength == 24)
        #expect(format.multipleLines == false)
        #expect(format.placeholder == "Username")
        #expect(format.defaultTextAnswer == "guest")
        #expect(format.hideClearButton)
        #expect(format.hideCharacterCountLabel)
        #expect(format.keyboardType == .emailAddress)
        #expect(format.autocapitalizationType == .none)
        #expect(format.autocorrectionType == .no)
        #expect(format.spellCheckingType == .no)
        #expect(format.textContentType == .username)
        #expect(format.isSecureTextEntry)
        #expect(format.passwordRules != nil)
    }

    @Test("Text answer configuration prefers valid regex over max length")
    func textAnswerConfigurationPrefersValidRegexOverMaxLength() throws {
        let configuration = TextAnswerFormatConfiguration(
            validationPattern: #"^[A-Z]{3}$"#,
            invalidMessage: "Use three uppercase letters",
            maximumLength: 24,
            multipleLines: nil,
            placeholder: nil,
            defaultTextAnswer: nil,
            hideClearButton: nil,
            hideCharacterCountLabel: nil,
            keyboardType: nil,
            autocapitalizationType: nil,
            autocorrectionType: nil,
            spellCheckingType: nil,
            textContentType: nil,
            secureTextEntry: nil,
            passwordRules: nil
        )

        let format = configuration.answerFormat
        let regex = try #require(format.validationRegularExpression)

        #expect(regex.pattern == #"^[A-Z]{3}$"#)
        #expect(format.invalidMessage == "Use three uppercase letters")
        #expect(format.maximumLength == 0)
    }

    @Test("Text answer configuration falls back to unconstrained text for invalid regex and nonpositive max length")
    func textAnswerConfigurationFallsBackToUnconstrainedText() {
        let configuration = TextAnswerFormatConfiguration(
            validationPattern: "[",
            invalidMessage: "Invalid",
            maximumLength: 0,
            multipleLines: nil,
            placeholder: nil,
            defaultTextAnswer: nil,
            hideClearButton: nil,
            hideCharacterCountLabel: nil,
            keyboardType: nil,
            autocapitalizationType: nil,
            autocorrectionType: nil,
            spellCheckingType: nil,
            textContentType: nil,
            secureTextEntry: nil,
            passwordRules: nil
        )

        let format = configuration.answerFormat

        #expect(format.validationRegularExpression == nil)
        #expect(format.maximumLength == 0)
        #expect(format.invalidMessage == nil)
    }

    @Test("Text input trait enum mappings round trip UIKit values")
    func textInputTraitEnumMappingsRoundTripUIKitValues() {
        let keyboardCases: [(KeyboardTypeStyle, UIKeyboardType)] = [
            (.default, .default),
            (.asciiCapable, .asciiCapable),
            (.numbersAndPunctuation, .numbersAndPunctuation),
            (.URL, .URL),
            (.numberPad, .numberPad),
            (.phonePad, .phonePad),
            (.namePhonePad, .namePhonePad),
            (.emailAddress, .emailAddress),
            (.decimalPad, .decimalPad),
            (.twitter, .twitter),
            (.webSearch, .webSearch),
            (.asciiCapableNumberPad, .asciiCapableNumberPad)
        ]
        let capitalizationCases: [(AutocapitalizationStyle, UITextAutocapitalizationType)] = [
            (.none, .none),
            (.words, .words),
            (.sentences, .sentences),
            (.allCharacters, .allCharacters)
        ]
        let autocorrectionCases: [(AutocorrectionStyle, UITextAutocorrectionType)] = [
            (.default, .default),
            (.no, .no),
            (.yes, .yes)
        ]
        let spellCheckingCases: [(SpellCheckingStyle, UITextSpellCheckingType)] = [
            (.default, .default),
            (.no, .no),
            (.yes, .yes)
        ]

        for (style, uiValue) in keyboardCases {
            #expect(style.uiValue == uiValue)
            #expect(KeyboardTypeStyle(uiValue) == style)
        }
        for (style, uiValue) in capitalizationCases {
            #expect(style.uiValue == uiValue)
            #expect(AutocapitalizationStyle(uiValue) == style)
        }
        for (style, uiValue) in autocorrectionCases {
            #expect(style.uiValue == uiValue)
            #expect(AutocorrectionStyle(uiValue) == style)
        }
        for (style, uiValue) in spellCheckingCases {
            #expect(style.uiValue == uiValue)
            #expect(SpellCheckingStyle(uiValue) == style)
        }
    }

    @Test("Choice answer configurations build ORK text and image choice formats")
    func choiceAnswerConfigurationsBuildORKTextAndImageChoiceFormats() throws {
        let textConfiguration = TextChoiceAnswerFormatConfiguration(
            style: .multiple,
            textChoices: ["Alpha", "Beta", "Gamma"]
        )
        let imageConfiguration = ImageChoiceAnswerFormatConfiguration(
            style: .single,
            vertical: true,
            imageChoices: [
                ImageChoiceAnswerFormatConfiguration.Item(
                    normalImageName: "round_shape",
                    selectedImageName: nil,
                    text: "Round",
                    value: "round"
                ),
                ImageChoiceAnswerFormatConfiguration.Item(
                    normalImageName: "missing_asset",
                    selectedImageName: nil,
                    text: "Missing",
                    value: "missing"
                ),
                ImageChoiceAnswerFormatConfiguration.Item(
                    normalImageName: "square_shape",
                    selectedImageName: "round_shape",
                    text: nil,
                    value: "square"
                )
            ]
        )

        let textFormat = try #require(textConfiguration.answerFormat as? ORKTextChoiceAnswerFormat)
        let imageFormat = try #require(imageConfiguration.answerFormat as? ORKImageChoiceAnswerFormat)

        #expect(ChoiceAnswerStyle.single.orkStyle == .singleChoice)
        #expect(ChoiceAnswerStyle.multiple.orkStyle == .multipleChoice)
        #expect(textFormat.style == .multipleChoice)
        #expect(textFormat.textChoices.map(\.text) == ["Alpha", "Beta", "Gamma"])
        #expect(textFormat.textChoices.compactMap { ($0.value as? NSNumber)?.intValue } == [0, 1, 2])

        #expect(imageFormat.style == .singleChoice)
        #expect(imageFormat.isVertical)
        #expect(imageFormat.imageChoices.count == 2)
        #expect(imageFormat.imageChoices.map(\.text) == ["Round", nil])
        #expect(imageFormat.imageChoices.map { $0.value as? String } == ["round", "square"])
        #expect(imageFormat.imageChoices.first?.normalStateImage != nil)
        #expect(imageFormat.imageChoices.last?.selectedStateImage != nil)
    }

    @Test("Scale answer configurations build ORK scale formats")
    func scaleAnswerConfigurationsBuildORKScaleFormats() throws {
        let scaleConfiguration = ScaleFormatConfiguration(
            maxValue: 7,
            minValue: 1,
            defaultValue: 3,
            step: 2,
            vertical: true,
            maximumValueDescription: "Maximum",
            minimumValueDescription: "Minimum"
        )
        let continuousConfiguration = ContinuousScaleFormatConfiguration(
            maxValue: 1.0,
            minValue: 0.25,
            defaultValue: 0.75,
            maximumFractionDigits: 2,
            vertical: true,
            maximumValueDescription: "Full",
            minimumValueDescription: "Low",
            isPercent: true
        )
        let textScaleConfiguration = TextScaleFormatConfiguration(
            textChoices: ["Poor", "Good", "Great"],
            defaultIndex: 1,
            vertical: true
        )

        let scale = try #require(scaleConfiguration.answerFormat as? ORKScaleAnswerFormat)
        let continuousScale = try #require(continuousConfiguration.answerFormat as? ORKContinuousScaleAnswerFormat)
        let textScale = try #require(textScaleConfiguration.answerFormat as? ORKTextScaleAnswerFormat)

        #expect(scale.maximum == 7)
        #expect(scale.minimum == 1)
        #expect(scale.defaultValue == 3)
        #expect(scale.step == 2)
        #expect(scale.isVertical)
        #expect(scale.maximumValueDescription == "Maximum")
        #expect(scale.minimumValueDescription == "Minimum")

        #expect(continuousScale.maximum == 1.0)
        #expect(continuousScale.minimum == 0.25)
        #expect(continuousScale.defaultValue == 0.25)
        #expect(continuousScale.maximumFractionDigits == 2)
        #expect(continuousScale.isVertical)
        #expect(continuousScale.maximumValueDescription == "Full")
        #expect(continuousScale.minimumValueDescription == "Low")
        #expect(continuousScale.numberStyle == .percent)

        #expect(textScale.textChoices.map(\.text) == ["Poor", "Good", "Great"])
        #expect(textScale.textChoices.compactMap { ($0.value as? NSNumber)?.intValue } == [0, 1, 2])
        #expect(textScale.defaultIndex == 1)
        #expect(textScale.isVertical)
    }

    @Test("Numeric date and value picker answer configurations preserve configured values")
    func numericDateAndValuePickerAnswerConfigurationsPreserveConfiguredValues() throws {
        let integerConfiguration = IntegerAnswerFormatConfiguration(unit: "steps")
        let decimalConfiguration = DecimalAnswerFormatConfiguration(unit: "liters")
        let defaultDate = Date(timeIntervalSince1970: 1_700_000_000)
        let minimumDate = Date(timeIntervalSince1970: 1_600_000_000)
        let maximumDate = Date(timeIntervalSince1970: 1_800_000_000)
        let dateConfiguration = DateFormatConfiguration(
            defaultDate: defaultDate,
            minimumDate: minimumDate,
            maximumDate: maximumDate
        )
        let pickerConfiguration = ValuePickerAnswerFormatConfiguration(
            textChoices: ["One", "Two", "Three"]
        )

        let integerFormat = try #require(integerConfiguration.answerFormat as? ORKNumericAnswerFormat)
        let decimalFormat = try #require(decimalConfiguration.answerFormat as? ORKNumericAnswerFormat)
        let dateFormat = dateConfiguration.answerFormat
        let pickerFormat = try #require(pickerConfiguration.answerFormat as? ORKValuePickerAnswerFormat)

        #expect(integerFormat.style == .integer)
        #expect(integerFormat.unit == "steps")
        #expect(decimalFormat.style == .decimal)
        #expect(decimalFormat.unit == "liters")

        #expect(dateFormat.style == .date)
        #expect(dateFormat.defaultDate == defaultDate)
        #expect(dateFormat.minimumDate == minimumDate)
        #expect(dateFormat.maximumDate == maximumDate)
        #expect(dateFormat.calendar?.identifier == Calendar.current.identifier)

        #expect(pickerFormat.textChoices.map(\.text) == ["One", "Two", "Three"])
        #expect(pickerFormat.textChoices.compactMap { ($0.value as? NSNumber)?.intValue } == [0, 1, 2])
    }
}
