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

 4. Commercial redistribution in any form requires an explicit license agreement with
 the copyright holder(s). Please contact support@hippocratestech.com for further information
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
import OTFCareKitStore
import Testing
@testable import OTFMagicBox

@Suite("Health profile metadata")
struct HealthProfileMetadataTests {
    @Test("The v1 catalogue maps all approved SNOMED CT codes and canonical names")
    func catalogueMapsApprovedCodesAndCanonicalNames() {
        let expected = [
            ("44054006", "Type 2 diabetes mellitus"),
            ("46635009", "Type 1 diabetes mellitus"),
            ("38341003", "Hypertensive disorder, systemic arterial"),
            ("84114007", "Heart failure"),
            ("53741008", "Coronary arteriosclerosis"),
            ("22298006", "Myocardial infarction"),
            ("230690007", "Cerebrovascular accident"),
            ("13645005", "Chronic obstructive pulmonary disease"),
            ("195967001", "Asthma"),
            ("233604007", "Pneumonia"),
            ("65363002", "Otitis media"),
            ("444814009", "Viral upper respiratory tract infection"),
            ("36971009", "Acute sinusitis"),
            ("10509002", "Acute bronchitis"),
            ("193462001", "Chronic kidney disease"),
            ("709044004", "Chronic kidney disease stage 3"),
            ("271737000", "Anemia"),
            ("64859006", "Osteoporosis"),
            ("396275006", "Osteoarthritis"),
            ("370143000", "Major depressive disorder")
        ]

        #expect(HealthProfileConditionCatalogue.conditions.map(\.code) == expected.map(\.0))
        #expect(HealthProfileConditionCatalogue.conditions.map(\.name) == expected.map(\.1))
        #expect(HealthProfileConditionCatalogue.conditions.allSatisfy {
            $0.system == HealthProfileConditionCatalogue.snomedSystem
        })
    }

    @Test("Reported conditions encode as backend raw code-and-name values")
    func reportedConditionsEncodeAsRawCodeAndNameValues() throws {
        var patient = makePatient()
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))

        try patient.setConditionsResponse(ConditionsResponse(
            status: .reported,
            items: [ReportedCondition(coding: asthma)]
        ))

        let encoded = try #require(patient.userInfo?[ProfileUserInfoKey.conditions])
        let payload = try jsonArray(from: encoded)

        #expect(payload == [[
            "code": "195967001",
            "name": "Asthma"
        ]])
    }

    @Test("Raw conditions retain unanswered, none, and reported semantics")
    func rawConditionsRetainSupportedSemantics() throws {
        var patient = makePatient()
        #expect(patient.conditionsResponse == nil)

        try patient.setConditionsResponse(ConditionsResponse(status: .none, items: []))
        #expect(patient.conditionsResponse == ConditionsResponse(status: .none, items: []))
        #expect(patient.userInfo?[ProfileUserInfoKey.conditions] == "[]")

        try patient.setConditionsResponse(ConditionsResponse(status: .unknown, items: []))
        #expect(patient.conditionsResponse == nil)
        #expect(patient.userInfo?[ProfileUserInfoKey.conditions] == nil)

        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let reported = ConditionsResponse(status: .reported, items: [ReportedCondition(coding: asthma)])
        try patient.setConditionsResponse(reported)
        #expect(patient.conditionsResponse == reported)

        try patient.setConditionsResponse(nil)
        #expect(patient.conditionsResponse == nil)
        #expect(patient.userInfo?[ProfileUserInfoKey.conditions] == nil)
    }

    @Test("Duplicate and unknown SNOMED CT concepts survive a safe round trip")
    func duplicateAndUnknownConceptsSurviveSafeRoundTrip() throws {
        var patient = makePatient()
        patient.userInfo = [
            ProfileUserInfoKey.conditions: """
            {"status":"reported","items":[
              {"coding":{"system":"http://snomed.info/sct","code":"999999999","name":"Future concept"}},
              {"coding":{"system":"http://snomed.info/sct","code":"195967001","name":"Asthma"}},
              {"coding":{"system":"http://snomed.info/sct","code":"999999999","name":"Future concept"}}
            ]}
            """
        ]

        let decoded = try #require(patient.conditionsResponse)
        #expect(decoded.items.map(\.coding.code) == ["999999999", "195967001"])

        var draft = HealthProfileDraft(patient: patient)
        let hypertension = try #require(HealthProfileConditionCatalogue.condition(withCode: "38341003"))
        draft.setCondition(hypertension, isSelected: true)
        try draft.apply(to: &patient)

        #expect(patient.conditionsResponse?.items.map(\.coding.code) == [
            "38341003", "195967001", "999999999"
        ])
    }

    @Test("Malformed condition states and unsupported v1 details fail safely")
    func malformedConditionStatesAndUnsupportedDetailsFailSafely() throws {
        var patient = makePatient()
        patient.userInfo = [
            ProfileUserInfoKey.conditions: #"{"status":"reported","items":[]}"#,
            "attachments": "attachment-data"
        ]
        #expect(patient.conditionsResponse == nil)
        #expect(patient.userInfo?["attachments"] == "attachment-data")

        patient.userInfo?[ProfileUserInfoKey.conditions] = """
        {"status":"none","items":[{"coding":{"system":"http://snomed.info/sct","code":"195967001","name":"Asthma"}}]}
        """
        #expect(patient.conditionsResponse == nil)

        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        #expect(throws: HealthProfileMetadataError.self) {
            try patient.setConditionsResponse(ConditionsResponse(
                status: .reported,
                items: [ReportedCondition(coding: asthma, notes: "Not persisted in v1")]
            ))
        }
        #expect(patient.userInfo?["attachments"] == "attachment-data")
    }

    @Test("New locations encode country as backend display name with address components")
    func newLocationsEncodeBackendLocationComponents() throws {
        var patient = makePatient()
        try patient.setProfileLocation(ProfileLocation(
            country: " Portugal ",
            city: " Lisbon ",
            addressLine1: " 10 Example Street ",
            addressLine2: " ",
            region: " Lisbon ",
            postalCode: " 1000-001 ",
            countryCode: " +351 "
        ))

        let encoded = try #require(patient.userInfo?[ProfileUserInfoKey.location])
        let payload = try jsonObject(from: encoded)
        #expect(payload["city"] as? String == "Lisbon")
        #expect(payload["addressLine1"] as? String == "10 Example Street")
        #expect(payload["addressLine2"] == nil)
        #expect(payload["countryCode"] as? String == "+351")
        #expect(payload["displayName"] as? String == "Portugal")
        #expect(payload["locality"] == nil)
    }

    @Test("Location calling codes encode localized decimal digits canonically")
    func locationCallingCodesEncodeLocalizedDecimalDigitsCanonically() throws {
        for (input, expected) in [(" +٣٥١ ", "+351"), ("+１２", "+12")] {
            var patient = makePatient()
            try patient.setProfileLocation(ProfileLocation(city: "Lisbon", countryCode: input))

            let encoded = try #require(patient.userInfo?[ProfileUserInfoKey.location])
            let payload = try jsonObject(from: encoded)
            #expect(payload["countryCode"] as? String == expected)
        }
    }

    @Test("Blank optional calling codes are treated as absent")
    func blankOptionalCallingCodesAreTreatedAsAbsent() throws {
        var patient = makePatient()
        var draft = HealthProfileDraft(patient: patient)
        draft.location = ProfileLocation(city: "Lisbon", countryCode: "   ")

        try draft.apply(to: &patient)

        #expect(patient.profileLocation == ProfileLocation(city: "Lisbon"))
    }

    @Test("Location decoding distinguishes backend country from legacy city forms")
    func locationDecodingDistinguishesCountryFromCity() {
        var patient = makePatient()

        patient.userInfo = [ProfileUserInfoKey.location: "Fixture City"]
        #expect(patient.profileLocation?.city == "Fixture City")

        patient.userInfo = [ProfileUserInfoKey.location: #""Fixture City""#]
        #expect(patient.profileLocation?.city == "Fixture City")

        patient.userInfo = [ProfileUserInfoKey.location: #"{"displayName":"Fixture Country"}"#]
        #expect(patient.profileLocation?.country == "Fixture Country")
        #expect(patient.profileLocation?.city == nil)

        patient.userInfo = [ProfileUserInfoKey.location: #"{"locality":"Fixture City"}"#]
        #expect(patient.profileLocation?.city == "Fixture City")
    }

    @Test("Metadata updates preserve unrelated userInfo and remove only empty values")
    func metadataUpdatesPreserveUnrelatedUserInfo() throws {
        var patient = makePatient()
        patient.userInfo = [
            ProfileUserInfoKey.location: #"{"city":"Fixture City"}"#,
            ProfileUserInfoKey.conditions: #"{"status":"none","items":[]}"#,
            "attachments": "attachment-data",
            "appSettings": "settings",
            "revId": "revision",
            "futureKey": "future-value"
        ]

        try patient.setProfileLocation(ProfileLocation(city: "  "))
        try patient.setConditionsResponse(nil)

        #expect(patient.userInfo == [
            "attachments": "attachment-data",
            "appSettings": "settings",
            "revId": "revision",
            "futureKey": "future-value"
        ])
    }

    @Test("Health Profile is reconstructed solely from userInfo")
    func healthProfileIsReconstructedSolelyFromUserInfo() throws {
        let location = #"{"displayName":"Fixture Country","city":"Fixture City","countryCode":"+351"}"#
        let conditions = #"[{"code":"195967001","name":"Asthma"}]"#
        let persistedUserInfo = [
            ProfileUserInfoKey.location: location,
            ProfileUserInfoKey.conditions: conditions,
            "attachments": "fixture-attachment",
            "appSettings": "fixture-settings"
        ]
        var reconstructedPatient = makePatient()
        reconstructedPatient.userInfo = persistedUserInfo

        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let draft = HealthProfileDraft(patient: reconstructedPatient)

        #expect(reconstructedPatient.profileLocation == ProfileLocation(
            country: "Fixture Country",
            city: "Fixture City",
            countryCode: "+351"
        ))
        #expect(reconstructedPatient.conditionsResponse == ConditionsResponse(
            status: .reported,
            items: [ReportedCondition(coding: asthma)]
        ))
        #expect(draft.location == reconstructedPatient.profileLocation)
        #expect(draft.selectedConditions.map(\.code) == ["195967001"])
        #expect(reconstructedPatient.userInfo == persistedUserInfo)
    }

    @Test("Profile drafts preserve supported raw conditions semantics")
    func profileDraftPreservesSupportedRawConditionsSemantics() throws {
        var patient = makePatient()
        var draft = HealthProfileDraft(patient: patient)
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))

        draft.setCondition(asthma, isSelected: true)
        try draft.apply(to: &patient)
        #expect(patient.conditionsResponse?.status == .reported)
        #expect(patient.conditionsResponse?.items.map(\.coding.code) == ["195967001"])

        draft = HealthProfileDraft(patient: patient)
        draft.setReportingStatus(.none)
        try draft.apply(to: &patient)
        #expect(patient.conditionsResponse == ConditionsResponse(status: .none, items: []))

        draft = HealthProfileDraft(patient: patient)
        draft.setReportingStatus(.unknown)
        try draft.apply(to: &patient)
        #expect(patient.conditionsResponse == nil)

        draft = HealthProfileDraft(patient: patient)
        draft.clearConditions()
        try draft.apply(to: &patient)
        #expect(patient.conditionsResponse == nil)
    }

    @Test("Disabled profile sections preserve their existing userInfo values")
    func disabledProfileSectionsPreserveExistingValues() throws {
        var patient = makePatient()
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        try patient.setProfileLocation(ProfileLocation(country: "Portugal", countryCode: "+351"))
        try patient.setConditionsResponse(ConditionsResponse(
            status: .reported,
            items: [ReportedCondition(coding: asthma)]
        ))
        let originalLocation = patient.userInfo?[ProfileUserInfoKey.location]
        let originalConditions = patient.userInfo?[ProfileUserInfoKey.conditions]

        var draft = HealthProfileDraft(patient: patient)
        draft.location = ProfileLocation(country: "Ignored country", countryCode: "+92")
        draft.clearConditions()
        try draft.apply(to: &patient, applyLocation: false, applyConditions: true)

        #expect(patient.userInfo?[ProfileUserInfoKey.location] == originalLocation)
        #expect(patient.userInfo?[ProfileUserInfoKey.conditions] == nil)

        draft = HealthProfileDraft(patient: patient)
        draft.location = ProfileLocation(country: "Pakistan", countryCode: "+92")
        draft.setCondition(asthma, isSelected: true)
        try draft.apply(to: &patient, applyLocation: true, applyConditions: false)

        #expect(patient.profileLocation?.country == "Pakistan")
        #expect(patient.userInfo?[ProfileUserInfoKey.conditions] == nil)
        #expect(originalConditions != nil)
    }

    @Test("Profile draft validation is atomic and leaves generic errors metadata-free")
    func profileDraftValidationIsAtomicAndErrorsAreMetadataFree() {
        for invalidCallingCode in ["PT", "+0", "+000", "+012"] {
            var patient = makePatient()
            patient.userInfo = ["attachments": "attachment-data"]
            var draft = HealthProfileDraft(patient: patient)
            draft.location.city = "Fixture City"
            draft.location.countryCode = invalidCallingCode

            #expect(throws: HealthProfileDraftValidationError.self) {
                try draft.apply(to: &patient)
            }
            #expect(patient.userInfo == ["attachments": "attachment-data"])
        }
        #expect(!UpdateUserProfileConfiguration.fallback.profileSaveErrorMessage.localized.contains("Fixture City"))
        #expect(!UpdateUserProfileConfiguration.fallback.profileSaveErrorMessage.localized.contains("PT"))
    }

    @Test("Health profile fixture survives a local patient write and reread")
    func healthProfileFixtureSurvivesLocalPatientWriteAndReread() async throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }

        var patient = makePatient()
        patient.userInfo = [
            "attachments": "fixture-attachment",
            "appSettings": "fixture-settings"
        ]
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let hypertension = try #require(HealthProfileConditionCatalogue.condition(withCode: "38341003"))
        try patient.setProfileLocation(ProfileLocation(city: "Fixture City"))
        try patient.setConditionsResponse(ConditionsResponse(
            status: .reported,
            items: [asthma, hypertension].map { ReportedCondition(coding: $0) }
        ))

        let savedPatients = try await withCheckedThrowingContinuation { continuation in
            storeFixture.store.addPatients([patient], callbackQueue: .main) { result in
                continuation.resume(with: result)
            }
        }
        var savedPatient = try #require(savedPatients.first)
        var draft = HealthProfileDraft(patient: savedPatient)
        draft.location = ProfileLocation(
            city: "Fixture City",
            addressLine1: "12 Fixture Way",
            countryCode: "+351"
        )
        draft.setCondition(asthma, isSelected: false)
        try draft.apply(to: &savedPatient)

        let updatedPatients = try await withCheckedThrowingContinuation { continuation in
            storeFixture.store.updatePatients([savedPatient], callbackQueue: .main) { result in
                continuation.resume(with: result)
            }
        }
        let updatedPatient = try #require(updatedPatients.first)
        let rereadPatients = try await withCheckedThrowingContinuation { continuation in
            storeFixture.store.fetchPatients(callbackQueue: .main) { result in
                continuation.resume(with: result)
            }
        }
        let rereadPatient = try #require(rereadPatients.first { $0.id == updatedPatient.id })

        #expect(rereadPatient.profileLocation == ProfileLocation(
            city: "Fixture City",
            addressLine1: "12 Fixture Way",
            countryCode: "+351"
        ))
        #expect(rereadPatient.conditionsResponse?.status == .reported)
        #expect(rereadPatient.conditionsResponse?.items.map(\.coding.code) == ["38341003"])
        #expect(rereadPatient.userInfo?["attachments"] == "fixture-attachment")
        #expect(rereadPatient.userInfo?["appSettings"] == "fixture-settings")
    }
}

private func makePatient() -> OCKPatient {
    OCKPatient(id: "patient-id", givenName: "Test", familyName: "Person")
}

private func jsonObject(from encoded: String) throws -> [String: Any] {
    try #require(JSONSerialization.jsonObject(with: Data(encoded.utf8)) as? [String: Any])
}

private func jsonArray(from encoded: String) throws -> [[String: String]] {
    try #require(JSONSerialization.jsonObject(with: Data(encoded.utf8)) as? [[String: String]])
}
