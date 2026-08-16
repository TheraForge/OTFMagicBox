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
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("Authentication configuration")
struct AuthConfigurationTests {
    @Test("Shipped configuration uses the two shared profile feature toggles")
    func shippedHealthProfileConfigurationsDecodeSafely() throws {
        let decoder = OTFYAMLDecoderEngine()
        let app = try decoder.decode("AppConfiguration", as: AppConfiguration.self)
        let auth = try decoder.decode("AuthConfiguration", as: AuthConfiguration.self)
        let profile = try decoder.decode(
            "UpdateUserProfileConfiguration",
            as: UpdateUserProfileConfiguration.self
        )

        #expect(app.enableLocation)
        #expect(app.enableConditions)
        #expect(auth.conditionLabels.count == 20)
        #expect(profile.conditionLabels.count == 20)
        #expect(auth.conditionLabels.keys.sorted() == profile.conditionLabels.keys.sorted())

        let authTranslations = try localizedValues(in: auth.conditionLabels)
        let profileTranslations = try localizedValues(in: profile.conditionLabels)
        for condition in HealthProfileConditionCatalogue.conditions {
            #expect(authTranslations[condition.code]?.keys.sorted() == ["ar", "en", "pt"])
            #expect(profileTranslations[condition.code]?.keys.sorted() == ["ar", "en", "pt"])
            #expect(authTranslations[condition.code]?.values.allSatisfy { !$0.isEmpty } == true)
            #expect(profileTranslations[condition.code]?.values.allSatisfy { !$0.isEmpty } == true)
        }
    }

    @Test("Auth configuration fills missing raw values from fallback")
    func authConfigurationFillsMissingRawValuesFromFallback() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [:])

        let config = AuthConfiguration(from: raw)

        #expect(config.version == AuthConfiguration.fallback.version)
        #expect(config.consentFileName == AuthConfiguration.fallback.consentFileName)
        #expect(config.consentSections.map { $0.type } == AuthConfiguration.fallback.consentSections.map { $0.type })
        #expect(config.includeDOB == AuthConfiguration.fallback.includeDOB)
        #expect(config.includeGender == AuthConfiguration.fallback.includeGender)
        #expect(config.addressSectionTitle.localized == "Address")
        #expect(config.locationDisplayNameLabel.localized == "Country")
        #expect(config.locationDisplayNamePlaceholder.localized == "Enter your country")
        #expect(config.cityLabel.localized == "City")
        #expect(config.addressLine1Label.localized == "Address line 1")
        #expect(config.countryCodePlaceholder.localized == "Enter calling code, for example +351")
        #expect(config.countryCodeValidationMessage.localized == "Use a valid country calling code, for example +351.")
        #expect(config.conditionLabels.count == 20)
        #expect(config.signupProfileDetailsText.localized.contains("self-reported"))
        #expect(config.signupProfileDetailsText.localized.contains("GPS"))
        #expect(config.signupFailureMessage.localized == "We could not complete sign up. Please review your account details and try again.")
        let dataGatheringSection = try #require(config.consentSections.first { $0.type == "dataGathering" })
        #expect(dataGatheringSection.content.localized.contains("self-reported"))
        #expect(dataGatheringSection.content.localized.contains("minimum location detail"))
        #expect(dataGatheringSection.content.localized.contains("GPS"))
        let privacySection = try #require(config.consentSections.first { $0.type == "privacy" })
        #expect(privacySection.content.localized.contains("Health Profile"))
        #expect(privacySection.content.localized.contains("approval"))
        let withdrawingSection = try #require(config.consentSections.first { $0.type == "withdrawing" })
        #expect(withdrawingSection.content.localized.contains("Health Profile"))
        #expect(withdrawingSection.content.localized.contains("not confirmation"))
        #expect(config.showAppleLogin == AuthConfiguration.fallback.showAppleLogin)
        #expect(config.showGoogleLogin == AuthConfiguration.fallback.showGoogleLogin)
        #expect(config.doctorPortalUrl == AuthConfiguration.fallback.doctorPortalUrl)
        #expect(config.healthTypes == AuthConfiguration.fallback.healthTypes)
        #expect(config.healthRecords?.permissionsTitle.localized == AuthConfiguration.fallback.healthRecords?.permissionsTitle.localized)
        #expect(config.completionTitle.localized == AuthConfiguration.fallback.completionTitle.localized)
    }

    @Test("Auth configuration preserves explicit registration and login values")
    func authConfigurationPreservesExplicitRegistrationAndLoginValues() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "version": "3.1.0",
            "includeDOB": false,
            "includeGender": false,
            "registrationTitle": authLocalized("Create Account"),
            "registrationText": authLocalized("Join the study"),
            "emailPlaceholder": authLocalized("patient@example.org"),
            "passwordPlaceholder": authLocalized("Secure password"),
            "showAppleLogin": false,
            "showGoogleLogin": true,
            "signInWithEmail": authLocalized("Continue with email"),
            "loginTitle": authLocalized("Welcome Back"),
            "loginSectionHeader": authLocalized("Your credentials")
        ])

        let config = AuthConfiguration(from: raw)

        #expect(config.version == "3.1.0")
        #expect(config.includeDOB == false)
        #expect(config.includeGender == false)
        #expect(config.registrationTitle.localized == "Create Account")
        #expect(config.registrationText.localized == "Join the study")
        #expect(config.emailPlaceholder.localized == "patient@example.org")
        #expect(config.passwordPlaceholder.localized == "Secure password")
        #expect(config.showAppleLogin == false)
        #expect(config.showGoogleLogin == true)
        #expect(config.signInWithEmail.localized == "Continue with email")
        #expect(config.loginTitle.localized == "Welcome Back")
        #expect(config.loginSectionHeader.localized == "Your credentials")
    }

    @Test("Auth configuration preserves explicit profile-details values")
    func authConfigurationPreservesExplicitProfileDetailsValues() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "signupFailureMessage": authLocalized("Try again without exposing entered values"),
            "addressSectionTitle": authLocalized("Address details"),
            "locationDisplayNameLabel": authLocalized("Place name"),
            "cityLabel": authLocalized("Municipality"),
            "addressLine1Label": authLocalized("Street address"),
            "countryCodePlaceholder": authLocalized("Calling code"),
            "countryCodeValidationMessage": authLocalized("Enter a calling code"),
            "conditionsLabel": authLocalized("Conditions"),
            "conditionLabels": [
                "195967001": authLocalized("Configured asthma label")
            ]
        ])

        let config = AuthConfiguration(from: raw)

        #expect(config.signupFailureMessage.localized == "Try again without exposing entered values")
        #expect(config.addressSectionTitle.localized == "Address details")
        #expect(config.locationDisplayNameLabel.localized == "Place name")
        #expect(config.cityLabel.localized == "Municipality")
        #expect(config.addressLine1Label.localized == "Street address")
        #expect(config.countryCodePlaceholder.localized == "Calling code")
        #expect(config.countryCodeValidationMessage.localized == "Enter a calling code")
        #expect(config.conditionsLabel.localized == "Conditions")
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        #expect(config.conditionLabel(for: asthma) == "Configured asthma label")
    }

    @Test("Condition catalogue localization falls back to the canonical name")
    func conditionCatalogueLocalizationFallsBackToCanonicalName() throws {
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "conditionLabels": [:]
        ])
        let misconfigured = AuthConfiguration(from: raw)

        #expect(misconfigured.conditionLabel(for: asthma) == asthma.name)

        let encodedLabel = try JSONEncoder().encode(
            try #require(AuthConfiguration.fallback.conditionLabels[asthma.code])
        )
        let translations = try #require(
            JSONSerialization.jsonObject(with: encodedLabel) as? [String: String]
        )
        #expect(translations["en"] == "Asthma")
        #expect(translations["pt"] == "Asma")
        #expect(translations["ar"] == "الربو")
    }

    @Test("Auth configuration migrates consent and health records")
    func authConfigurationMigratesConsentAndHealthRecords() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "consentFileName": "CustomConsent",
            "consentReason": authLocalized("Agree to continue"),
            "consentTitle": authLocalized("Study Consent"),
            "consentSections": [
                [
                    "type": "privacy",
                    "show": false,
                    "title": authLocalized("Privacy"),
                    "summary": authLocalized("Summary"),
                    "content": authLocalized("Content"),
                    "image": "privacy-lock"
                ],
                [
                    "title": authLocalized("Fallback Section")
                ]
            ],
            "healthPermissionsTitle": authLocalized("Health Permission"),
            "healthPermissionsText": authLocalized("Share selected health data"),
            "healthBackgroundReadFrequency": "daily",
            "healthTypes": ["StepCount", "HeartRate"],
            "healthRecords": [
                "permissionsTitle": authLocalized("Clinical Records"),
                "permissionsText": authLocalized("Share clinical documents")
            ]
        ])

        let config = AuthConfiguration(from: raw)

        #expect(config.consentFileName == "CustomConsent")
        #expect(config.consentReason.localized == "Agree to continue")
        #expect(config.consentTitle.localized == "Study Consent")
        #expect(config.consentSections.count == 2)
        #expect(config.consentSections[0].type == "privacy")
        #expect(config.consentSections[0].show == false)
        #expect(config.consentSections[0].title.localized == "Privacy")
        #expect(config.consentSections[0].image == "privacy-lock")
        #expect(config.consentSections[1].type == ConsentSectionConfig.fallback.type)
        #expect(config.consentSections[1].show == ConsentSectionConfig.fallback.show)
        #expect(config.consentSections[1].title.localized == "Fallback Section")
        #expect(config.healthPermissionsTitle.localized == "Health Permission")
        #expect(config.healthPermissionsText.localized == "Share selected health data")
        #expect(config.healthBackgroundReadFrequency == "daily")
        #expect(config.healthTypes == ["StepCount", "HeartRate"])
        #expect(config.healthRecords?.permissionsTitle.localized == "Clinical Records")
        #expect(config.healthRecords?.permissionsText.localized == "Share clinical documents")
    }

    @Test("Auth configuration treats empty consent sections as fallback")
    func authConfigurationTreatsEmptyConsentSectionsAsFallback() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "consentSections": []
        ])

        let config = AuthConfiguration(from: raw)

        #expect(
            config.consentSections.map { $0.title.localized }
            == AuthConfiguration.fallback.consentSections.map { $0.title.localized }
        )
    }

    @Test("Auth configuration migrate entry point preserves raw overrides")
    func authConfigurationMigrateEntryPointPreservesRawOverrides() throws {
        let raw = try decodeAuthJSON(RawAuthConfiguration.self, from: [
            "doctorPortalUrl": "https://doctor.example.org/login",
            "doctorPortalConfirmTitle": authLocalized("Doctor Portal"),
            "doctorPortalConfirmMessage": authLocalized("Open %@?"),
            "passcodeEnabled": true,
            "passcodeType": "6",
            "passcodePrompt": authLocalized("Enter code")
        ])

        let version = try #require(OTFSemanticVersion(string: "2.0.0"))
        let config = try AuthConfiguration.migrate(from: version, raw: raw)

        #expect(config.doctorPortalUrl == "https://doctor.example.org/login")
        #expect(config.doctorPortalConfirmTitle.localized == "Doctor Portal")
        #expect(config.doctorPortalConfirmMessage.localized == "Open %@?")
        #expect(config.passcodeEnabled == true)
        #expect(config.passcodeType == "6")
        #expect(config.passcodePrompt.localized == "Enter code")
    }
}

private func decodeAuthJSON<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

private func authLocalized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}

private func localizedValues(
    in labels: [String: OTFStringLocalized]
) throws -> [String: [String: String]] {
    let data = try JSONEncoder().encode(labels)
    return try #require(JSONSerialization.jsonObject(with: data) as? [String: [String: String]])
}
