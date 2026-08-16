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
@testable import OTFMagicBox

@Suite("Signup profile details")
struct SignupProfileDetailsTests {
    @Test("Profile-details step is hidden when both feature toggles are disabled")
    func profileDetailsStepIsHiddenUntilEnabled() throws {
        let appConfiguration = makeAppConfiguration(enableLocation: false, enableConditions: false)

        #expect(SignupProfileDetailsStepFactory(
            auth: .fallback,
            appConfiguration: appConfiguration
        ).makeStep() == nil)
    }

    @Test("Profile-details step uses optional fields for enabled location and conditions")
    func profileDetailsStepUsesConfiguredLocationFields() throws {
        let auth = AuthConfiguration.fallback
        let appConfiguration = makeAppConfiguration(enableLocation: true, enableConditions: true)
        let step = try #require(SignupProfileDetailsStepFactory(
            auth: auth,
            appConfiguration: appConfiguration
        ).makeStep())
        let formItems = try #require(step.formItems)
        let conditions = try #require(formItems.last)
        let choiceFormat = try #require(conditions.answerFormat as? ORKTextChoiceAnswerFormat)
        let allInputItemsAreOptional = formItems.dropFirst().allSatisfy { $0.isOptional }

        #expect(step.identifier == Constants.Auth.registrationProfileDetailsStep)
        #expect(step.footerText == nil)
        #expect(formItems[0].text == auth.addressSectionTitle.localized)
        #expect(formItems.dropFirst().map(\.identifier) == [
            Constants.Auth.registrationLocationDisplayName,
            Constants.Auth.registrationLocationCity,
            Constants.Auth.registrationLocationAddressLine1,
            Constants.Auth.registrationLocationAddressLine2,
            Constants.Auth.registrationLocationRegion,
            Constants.Auth.registrationLocationPostalCode,
            Constants.Auth.registrationLocationCountryCode,
            Constants.Auth.registrationConditions
        ])
        #expect(allInputItemsAreOptional)
        #expect(formItems[1].text == "Country")
        #expect(conditions.identifier == Constants.Auth.registrationConditions)
        #expect(conditions.isOptional)
        #expect(formItems.count == 9)
        #expect(choiceFormat.textChoices.count == 21)
        #expect(choiceFormat.textChoices.contains { $0.text == auth.conditionsNoneReportedText.localized })
        #expect(!choiceFormat.textChoices.contains { $0.text == "Not sure" })
        #expect(!choiceFormat.textChoices.contains { $0.text == "Other" })
    }

    @Test("Location and conditions toggles independently control collected values")
    func profileDetailsTogglesIndependentlyControlValues() throws {
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let result = makeProfileDetailsStepResult(
            displayName: "Portugal",
            city: "Lisbon",
            conditions: [asthma.id]
        )
        let conditionsOnly = try SignupProfileData.make(
            from: result,
            auth: .fallback,
            appConfiguration: makeAppConfiguration(enableLocation: false, enableConditions: true)
        )
        let locationOnly = try SignupProfileData.make(
            from: result,
            auth: .fallback,
            appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: false)
        )

        #expect(conditionsOnly.location == nil)
        #expect(conditionsOnly.conditions?.items.map(\.coding.code) == [asthma.code])
        #expect(locationOnly.location?.country == "Portugal")
        #expect(locationOnly.conditions == nil)
    }

    @Test("Profile-details parser normalizes values without retaining them")
    func profileDetailsParserNormalizesValuesWithoutRetainingThem() throws {
        let auth = AuthConfiguration.fallback
        let appConfiguration = makeAppConfiguration(enableLocation: true, enableConditions: true)
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let hypertension = try #require(HealthProfileConditionCatalogue.condition(withCode: "38341003"))
        let stepResult = makeProfileDetailsStepResult(
            displayName: " Portugal ",
            city: " Lisbon ",
            addressLine1: " 12 Fixture Way ",
            addressLine2: " Suite 2 ",
            region: " Lisbon ",
            postalCode: " 1000-001 ",
            countryCode: " +351 ",
            conditions: [asthma.id, hypertension.id, asthma.id]
        )

        let profileData = try SignupProfileData.make(
            from: stepResult,
            auth: auth,
            appConfiguration: appConfiguration
        )

        #expect(profileData.location == ProfileLocation(
            country: "Portugal",
            city: "Lisbon",
            addressLine1: "12 Fixture Way",
            addressLine2: "Suite 2",
            region: "Lisbon",
            postalCode: "1000-001",
            countryCode: "+351"
        ))
        #expect(profileData.conditions?.status == .reported)
        #expect(profileData.conditions?.items.map(\.coding.code) == ["195967001", "38341003"])
        let cityResult = try #require(stepResult.results?.first {
            $0.identifier == Constants.Auth.registrationLocationCity
        } as? ORKTextQuestionResult)
        #expect(cityResult.textAnswer == " Lisbon ")
    }

    @Test("Profile-details data produces canonical top-level signup values")
    func profileDetailsDataProducesCanonicalSignupPayload() throws {
        let auth = AuthConfiguration.fallback
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let profileData = try SignupProfileData.make(
            from: makeProfileDetailsStepResult(
                displayName: " Portugal ",
                city: " Lisbon ",
                addressLine1: " 12 Fixture Way ",
                region: " Lisbon ",
                postalCode: " 1000-001 ",
                countryCode: " +351 ",
                conditions: [asthma.id]
            ),
            auth: auth,
            appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: true)
        )

        let payload = try profileData.signupPayload()

        #expect(payload.location == ProfileLocation(
            country: "Portugal",
            city: "Lisbon",
            addressLine1: "12 Fixture Way",
            region: "Lisbon",
            postalCode: "1000-001",
            countryCode: "+351"
        ))
        #expect(payload.conditions == [asthma])
    }

    @Test("Signup profile data represents none reported as a raw empty array")
    func profileDetailsDataEncodesNoneReportedAsRawArray() throws {
        let payload = try SignupProfileData(
            location: nil,
            conditions: ConditionsResponse(status: .none, items: [])
        ).signupPayload()

        #expect(payload.location == nil)
        #expect(payload.conditions?.isEmpty == true)
    }

    @Test("Profile-details parser distinguishes unanswered and none reported")
    func profileDetailsParserDistinguishesConditionResponses() throws {
        let auth = AuthConfiguration.fallback
        let appConfiguration = makeAppConfiguration(enableLocation: false, enableConditions: true)
        let unanswered = try SignupProfileData.make(
            from: makeProfileDetailsStepResult(addConditionsResult: false),
            auth: auth,
            appConfiguration: appConfiguration
        )
        let empty = try SignupProfileData.make(
            from: makeProfileDetailsStepResult(conditions: []),
            auth: auth,
            appConfiguration: appConfiguration
        )
        let none = try SignupProfileData.make(
            from: makeProfileDetailsStepResult(conditions: [SignupConditionsChoiceValue.none]),
            auth: auth,
            appConfiguration: appConfiguration
        )

        #expect(unanswered.conditions == nil)
        #expect(empty.conditions == nil)
        #expect(none.conditions == ConditionsResponse(status: .none, items: []))
    }

    @Test("Profile-details parser rejects selecting a condition with None reported")
    func profileDetailsParserEnforcesMutuallyExclusiveStatusRules() throws {
        let appConfiguration = makeAppConfiguration(enableLocation: true, enableConditions: true)
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let mixedStatus = makeProfileDetailsStepResult(conditions: [
            asthma.id, SignupConditionsChoiceValue.none
        ])

        #expect(throws: SignupProfileDataValidationError.self) {
            try SignupProfileData.make(
                from: mixedStatus,
                auth: .fallback,
                appConfiguration: appConfiguration
            )
        }
    }

    @Test("Profile-details parser rejects an invalid calling code instead of discarding it")
    func profileDetailsParserRejectsInvalidCallingCode() throws {
        let auth = AuthConfiguration.fallback
        for invalidCallingCode in ["+1234", "+0", "+000", "+012"] {
            let result = makeProfileDetailsStepResult(
                city: "Lisbon",
                countryCode: invalidCallingCode
            )

            #expect(throws: SignupProfileDataValidationError.self) {
                try SignupProfileData.make(
                    from: result,
                    auth: auth,
                    appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: true)
                )
            }
        }
    }

    @Test("Profile-details parser canonicalizes localized calling-code digits")
    func profileDetailsParserCanonicalizesLocalizedCallingCodeDigits() throws {
        let appConfiguration = makeAppConfiguration(enableLocation: true, enableConditions: false)

        for (input, expected) in [(" +٣٥١ ", "+351"), ("+１２", "+12")] {
            let profileData = try SignupProfileData.make(
                from: makeProfileDetailsStepResult(city: "Lisbon", countryCode: input),
                auth: .fallback,
                appConfiguration: appConfiguration
            )

            #expect(profileData.location?.countryCode == expected)
        }
    }

    @Test("Profile-details parser treats a blank optional calling code as absent")
    func profileDetailsParserTreatsBlankCallingCodeAsAbsent() throws {
        let profileData = try SignupProfileData.make(
            from: makeProfileDetailsStepResult(city: "Lisbon", countryCode: "   "),
            auth: .fallback,
            appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: false)
        )

        #expect(profileData.location?.city == "Lisbon")
        #expect(profileData.location?.countryCode == nil)
    }

    @Test("Signup profile data validates configured raw condition values before encoding")
    func profileDetailsDataRejectsNonCanonicalConditionValues() throws {
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let invalid = MedicalCondition(
            system: asthma.system,
            code: asthma.code,
            name: "Incorrect condition name"
        )
        let data = SignupProfileData(
            location: nil,
            conditions: ConditionsResponse(
                status: .reported,
                items: [ReportedCondition(coding: invalid)]
            )
        )

        #expect(throws: SignupProfileDataValidationError.self) {
            try data.signupPayload()
        }
    }

    @Test("Profile-details parser rejects values outside the configured catalogue")
    func profileDetailsParserRejectsUnknownConditionValues() throws {
        let auth = AuthConfiguration.fallback
        let unknown = makeProfileDetailsStepResult(conditions: [
            "\(HealthProfileConditionCatalogue.snomedSystem)|999999999"
        ])

        #expect(throws: SignupProfileDataValidationError.self) {
            try SignupProfileData.make(
                from: unknown,
                auth: auth,
                appConfiguration: makeAppConfiguration(enableLocation: true, enableConditions: true)
            )
        }
    }
}

private func makeProfileDetailsStepResult(
    displayName: String? = nil,
    city: String? = nil,
    addressLine1: String? = nil,
    addressLine2: String? = nil,
    region: String? = nil,
    postalCode: String? = nil,
    countryCode: String? = nil,
    conditions: [String]? = nil,
    addConditionsResult: Bool = true
) -> ORKStepResult {
    var results: [ORKResult] = []
    for (identifier, answer) in [
        (Constants.Auth.registrationLocationDisplayName, displayName),
        (Constants.Auth.registrationLocationCity, city),
        (Constants.Auth.registrationLocationAddressLine1, addressLine1),
        (Constants.Auth.registrationLocationAddressLine2, addressLine2),
        (Constants.Auth.registrationLocationRegion, region),
        (Constants.Auth.registrationLocationPostalCode, postalCode),
        (Constants.Auth.registrationLocationCountryCode, countryCode)
    ] {
        guard let answer else { continue }
        let locationResult = ORKTextQuestionResult(identifier: identifier)
        locationResult.textAnswer = answer
        results.append(locationResult)
    }
    if addConditionsResult {
        let conditionsResult = ORKChoiceQuestionResult(identifier: Constants.Auth.registrationConditions)
        conditionsResult.choiceAnswers = conditions?.map { $0 as NSString }
        results.append(conditionsResult)
    }
    return ORKStepResult(
        stepIdentifier: Constants.Auth.registrationProfileDetailsStep,
        results: results
    )
}
