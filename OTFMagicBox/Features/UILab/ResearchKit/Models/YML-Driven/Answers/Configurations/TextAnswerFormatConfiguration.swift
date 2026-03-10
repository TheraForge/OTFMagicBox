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
import OTFResearchKit
import OTFTemplateBox

// MARK: - Text Answer Format

struct TextAnswerFormatConfiguration: Codable {

    // Validation
    var validationPattern: String?
    var invalidMessage: OTFStringLocalized?

    // Limits
    var maximumLength: Int?

    // UI / behavior
    var multipleLines: Bool?
    var placeholder: OTFStringLocalized?
    var defaultTextAnswer: OTFStringLocalized?
    var hideClearButton: Bool?
    var hideCharacterCountLabel: Bool?

    // Keyboard and input traits (ChoiceAnswerStyle-like enums)
    var keyboardType: KeyboardTypeStyle?
    var autocapitalizationType: AutocapitalizationStyle?
    var autocorrectionType: AutocorrectionStyle?
    var spellCheckingType: SpellCheckingStyle?
    var textContentType: String?    // String typealias, Codable-friendly

    // Security
    var secureTextEntry: Bool?
    var passwordRules: String?                  // iOS 12+ descriptor string

    var answerFormat: ORKTextAnswerFormat {
        let format: ORKTextAnswerFormat

        if let pattern = validationPattern, let regex = try? NSRegularExpression(pattern: pattern) {
            format = ORKAnswerFormat.textAnswerFormat(withValidationRegularExpression: regex,
                                                      invalidMessage: invalidMessage?.localized ?? "")
        } else if let max = maximumLength, max > 0 {
            format = ORKAnswerFormat.textAnswerFormat(withMaximumLength: max)
        } else {
            format = ORKAnswerFormat.textAnswerFormat()
        }

        // Apply toggles
        if let multipleLines = multipleLines {
            format.multipleLines = multipleLines
        }
        if let placeholder = placeholder {
            format.placeholder = placeholder.localized
        }
        if let defaultText = defaultTextAnswer {
            format.defaultTextAnswer = defaultText.localized
        }
        if let hideClear = hideClearButton {
            format.hideClearButton = hideClear
        }
        if let hideCount = hideCharacterCountLabel {
            format.hideCharacterCountLabel = hideCount
        }

        // Input traits via mapped UIKit enums
        if let k = keyboardType {
            format.keyboardType = k.uiValue
        }
        if let cap = autocapitalizationType {
            format.autocapitalizationType = cap.uiValue
        }
        if let corr = autocorrectionType {
            format.autocorrectionType = corr.uiValue
        }
        if let spell = spellCheckingType {
            format.spellCheckingType = spell.uiValue
        }
        if let tct = textContentType {
            format.textContentType = UITextContentType(rawValue: tct)
        }

        // Security
        if let secure = secureTextEntry {
            format.isSecureTextEntry = secure
        }
        if let rules = passwordRules {
            format.passwordRules = UITextInputPasswordRules(descriptor: rules)
        }

        return format
    }

    static let fallback = TextAnswerFormatConfiguration(
        validationPattern: nil,
        invalidMessage: nil,
        maximumLength: 0,
        multipleLines: true,
        placeholder: "Enter text",
        defaultTextAnswer: nil,
        hideClearButton: false,
        hideCharacterCountLabel: false,
        keyboardType: .default,
        autocapitalizationType: .sentences,
        autocorrectionType: .default,
        spellCheckingType: .default,
        textContentType: nil,
        secureTextEntry: false,
        passwordRules: nil
    )
}

// MARK: - UIKit trait style enums (ChoiceAnswerStyle-like)

// Keyboard
enum KeyboardTypeStyle: String, Codable {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case URL
    case numberPad
    case phonePad
    case namePhonePad
    case emailAddress
    case decimalPad
    case twitter
    case webSearch
    case asciiCapableNumberPad

    var uiValue: UIKeyboardType {
        switch self {
        case .default: return .default
        case .asciiCapable: return .asciiCapable
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .URL: return .URL
        case .numberPad: return .numberPad
        case .phonePad: return .phonePad
        case .namePhonePad: return .namePhonePad
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        case .twitter: return .twitter
        case .webSearch: return .webSearch
        case .asciiCapableNumberPad: return .asciiCapableNumberPad
        }
    }

    init(_ ui: UIKeyboardType) {
        switch ui {
        case .default: self = .default
        case .asciiCapable: self = .asciiCapable
        case .numbersAndPunctuation: self = .numbersAndPunctuation
        case .URL: self = .URL
        case .numberPad: self = .numberPad
        case .phonePad: self = .phonePad
        case .namePhonePad: self = .namePhonePad
        case .emailAddress: self = .emailAddress
        case .decimalPad: self = .decimalPad
        case .twitter: self = .twitter
        case .webSearch: self = .webSearch
        case .asciiCapableNumberPad: self = .asciiCapableNumberPad
        @unknown default: self = .default
        }
    }
}

// Autocapitalization
enum AutocapitalizationStyle: String, Codable {
    case none
    case words
    case sentences
    case allCharacters

    var uiValue: UITextAutocapitalizationType {
        switch self {
        case .none: return .none
        case .words: return .words
        case .sentences: return .sentences
        case .allCharacters: return .allCharacters
        }
    }

    init(_ ui: UITextAutocapitalizationType) {
        switch ui {
        case .none: self = .none
        case .words: self = .words
        case .sentences: self = .sentences
        case .allCharacters: self = .allCharacters
        @unknown default: self = .sentences
        }
    }
}

// Autocorrection
enum AutocorrectionStyle: String, Codable {
    case `default`
    case no
    case yes

    var uiValue: UITextAutocorrectionType {
        switch self {
        case .default: return .default
        case .no: return .no
        case .yes: return .yes
        }
    }

    init(_ ui: UITextAutocorrectionType) {
        switch ui {
        case .default: self = .default
        case .no: self = .no
        case .yes: self = .yes
        @unknown default: self = .default
        }
    }
}

// Spell checking
enum SpellCheckingStyle: String, Codable {
    case `default`
    case no
    case yes

    var uiValue: UITextSpellCheckingType {
        switch self {
        case .default: return .default
        case .no: return .no
        case .yes: return .yes
        }
    }

    init(_ ui: UITextSpellCheckingType) {
        switch ui {
        case .default: self = .default
        case .no: self = .no
        case .yes: self = .yes
        @unknown default: self = .default
        }
    }
}
