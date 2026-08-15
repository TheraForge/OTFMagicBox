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

extension AuthConfiguration {
    func conditionLabel(for condition: MedicalCondition) -> String {
        HealthProfileConditionCatalogue.localizedName(
            for: condition,
            configuredLabels: conditionLabels
        )
    }
}

enum SignupConditionsChoiceValue {
    static let none = "conditions.status.none"
}

struct SignupProfileDetailsStepFactory {
    let auth: AuthConfiguration
    let appConfiguration: AppConfiguration

    func makeStep() -> ORKFormStep? {
        guard appConfiguration.enableLocation || appConfiguration.enableConditions else { return nil }

        let step = ORKFormStep(
            identifier: Constants.Auth.registrationProfileDetailsStep,
            title: auth.signupProfileDetailsTitle.localized,
            text: auth.signupProfileDetailsText.localized
        )

        var formItems: [ORKFormItem] = []
        if appConfiguration.enableLocation {
            formItems += locationFormItems()
        }

        if appConfiguration.enableConditions {
            let catalogueChoices = HealthProfileConditionCatalogue.conditions.map { condition in
                ORKTextChoice(
                    text: auth.conditionLabel(for: condition),
                    value: condition.id as NSString
                )
            }
            let statusChoices = [
                ORKTextChoice(
                    text: auth.conditionsNoneReportedText.localized,
                    value: SignupConditionsChoiceValue.none as NSString
                )
            ]
            let conditions = ORKFormItem(
                identifier: Constants.Auth.registrationConditions,
                text: auth.conditionsLabel.localized,
                detailText: auth.conditionsDetailText.localized,
                learnMoreItem: nil,
                showsProgress: false,
                answerFormat: ORKTextChoiceAnswerFormat(
                    style: .multipleChoice,
                    textChoices: catalogueChoices + statusChoices
                ),
                tagText: nil,
                optional: true
            )
            formItems.append(conditions)
        }

        step.formItems = formItems
        return step
    }

    private func locationFormItems() -> [ORKFormItem] {
        [
            ORKFormItem(sectionTitle: auth.addressSectionTitle.localized),
            textFormItem(
                identifier: Constants.Auth.registrationLocationDisplayName,
                text: auth.locationDisplayNameLabel.localized,
                placeholder: auth.locationDisplayNamePlaceholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationCity,
                text: auth.cityLabel.localized,
                placeholder: auth.cityPlaceholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationAddressLine1,
                text: auth.addressLine1Label.localized,
                placeholder: auth.addressLine1Placeholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationAddressLine2,
                text: auth.addressLine2Label.localized,
                placeholder: auth.addressLine2Placeholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationRegion,
                text: auth.regionLabel.localized,
                placeholder: auth.regionPlaceholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationPostalCode,
                text: auth.postalCodeLabel.localized,
                placeholder: auth.postalCodePlaceholder.localized
            ),
            textFormItem(
                identifier: Constants.Auth.registrationLocationCountryCode,
                text: auth.countryCodeLabel.localized,
                placeholder: auth.countryCodePlaceholder.localized
            )
        ]
    }

    private func textFormItem(
        identifier: String,
        text: String,
        placeholder: String
    ) -> ORKFormItem {
        let item = ORKFormItem(
            identifier: identifier,
            text: text,
            answerFormat: ORKTextAnswerFormat.textAnswerFormat(),
            optional: true
        )
        item.placeholder = placeholder
        return item
    }
}

struct SignupProfileData: Equatable {
    let location: ProfileLocation?
    let conditions: ConditionsResponse?

    /// Produces the backend's top-level signup values for an enabled signup request.
    func signupPayload() throws -> SignupProfilePayload {

        if let location {
            guard location.hasValidCallingCode else {
                throw SignupProfileDataValidationError.invalidCountryCode
            }
        }
        let normalizedLocation = location?.normalized
        let outboundLocation = normalizedLocation?.isEmpty == false ? normalizedLocation : nil
        var outboundConditions: [MedicalCondition]?
        if let conditions {
            try validateOutboundConditions(conditions)
            switch conditions.status {
            case .reported:
                outboundConditions = conditions.items.map(\.coding)
            case .none:
                outboundConditions = []
            case .unknown:
                outboundConditions = nil
            }
        }

        return SignupProfilePayload(
            location: outboundLocation,
            conditions: outboundConditions
        )
    }

    static func make(
        from stepResult: ORKStepResult,
        auth: AuthConfiguration,
        appConfiguration: AppConfiguration
    ) throws -> SignupProfileData {
        let location = appConfiguration.enableLocation ? try profileLocation(from: stepResult) : nil
        let conditions = appConfiguration.enableConditions
            ? try conditionsResponse(from: stepResult)
            : nil

        return SignupProfileData(
            location: location,
            conditions: conditions
        )
    }

    private static func profileLocation(from stepResult: ORKStepResult) throws -> ProfileLocation? {
        let location = ProfileLocation(
            country: textAnswer(
                for: Constants.Auth.registrationLocationDisplayName,
                in: stepResult
            ),
            city: textAnswer(for: Constants.Auth.registrationLocationCity, in: stepResult),
            addressLine1: textAnswer(
                for: Constants.Auth.registrationLocationAddressLine1,
                in: stepResult
            ),
            addressLine2: textAnswer(
                for: Constants.Auth.registrationLocationAddressLine2,
                in: stepResult
            ),
            region: textAnswer(for: Constants.Auth.registrationLocationRegion, in: stepResult),
            postalCode: textAnswer(
                for: Constants.Auth.registrationLocationPostalCode,
                in: stepResult
            ),
            countryCode: textAnswer(
                for: Constants.Auth.registrationLocationCountryCode,
                in: stepResult
            )
        )
        guard location.hasValidCallingCode else {
            throw SignupProfileDataValidationError.invalidCountryCode
        }
        let normalizedLocation = location.normalized
        return normalizedLocation.isEmpty ? nil : normalizedLocation
    }

    private static func conditionsResponse(from stepResult: ORKStepResult) throws -> ConditionsResponse? {
        guard let result = stepResult.results?.first(where: {
            $0.identifier == Constants.Auth.registrationConditions
        }) as? ORKChoiceQuestionResult else {
            return nil
        }

        let rawValues = result.choiceAnswers?.compactMap { $0 as? String } ?? []
        let uniqueAnswers = uniqueValues(rawValues)
        guard !uniqueAnswers.isEmpty else { return nil }

        let includesNone = uniqueAnswers.contains(SignupConditionsChoiceValue.none)
        let conditionIdentifiers = uniqueAnswers.filter {
            $0 != SignupConditionsChoiceValue.none
        }
        guard !includesNone || conditionIdentifiers.isEmpty else {
            throw SignupProfileDataValidationError.invalidConditionsSelection
        }
        if includesNone {
            return ConditionsResponse(status: .none, items: [])
        }

        let items = try conditionIdentifiers.map { identifier -> ReportedCondition in
            guard let condition = HealthProfileConditionCatalogue.condition(withID: identifier) else {
                throw SignupProfileDataValidationError.unknownCondition
            }
            return ReportedCondition(coding: condition)
        }
        return ConditionsResponse(status: .reported, items: items)
    }

    private static func textAnswer(for identifier: String, in stepResult: ORKStepResult) -> String? {
        let answer = (stepResult.results?.first { $0.identifier == identifier } as? ORKTextQuestionResult)?.textAnswer
        guard let answer else { return nil }
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func uniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            return trimmed
        }
    }

    private func validateOutboundConditions(_ response: ConditionsResponse) throws {
        guard response.items.allSatisfy({ $0.onset == nil && $0.notes == nil }) else {
            throw SignupProfileDataValidationError.invalidConditionsSelection
        }
        guard response.status != .reported || !response.items.isEmpty else {
            throw SignupProfileDataValidationError.invalidConditionsSelection
        }
        guard response.status == .reported || response.items.isEmpty else {
            throw SignupProfileDataValidationError.invalidConditionsSelection
        }

        let identifiers = response.items.map(\.coding.id)
        guard Set(identifiers).count == identifiers.count else {
            throw SignupProfileDataValidationError.invalidConditionsSelection
        }
        for item in response.items {
            guard let approved = HealthProfileConditionCatalogue.condition(withID: item.coding.id),
                  approved.name == item.coding.name else {
                throw SignupProfileDataValidationError.unknownCondition
            }
        }
    }
}

struct SignupProfilePayload: Equatable {
    let location: ProfileLocation?
    let conditions: [MedicalCondition]?
}

enum SignupProfileDataValidationError: Error, Equatable {
    case detailsUnavailable
    case invalidCountryCode
    case invalidConditionsSelection
    case unknownCondition

    func localizedMessage(using auth: AuthConfiguration) -> String {
        switch self {
        case .invalidCountryCode:
            auth.countryCodeValidationMessage.localized
        case .invalidConditionsSelection, .unknownCondition:
            auth.conditionsValidationMessage.localized
        case .detailsUnavailable:
            auth.signupFailureMessage.localized
        }
    }
}
