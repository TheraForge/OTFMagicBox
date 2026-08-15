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
import OTFCloudClientAPI
import OTFResearchKit
import Sodium
import Testing
@testable import OTFMagicBox

@Suite("Auth signup request factory")
struct AuthSignupRequestFactoryTests {
    @Test("Signup request uses registration fields and generated keys")
    func signupRequestUsesRegistrationFieldsAndGeneratedKeys() throws {
        let crypto = AuthSignupFakeCrypto()
        let factory = SignupRequestFactory(crypto: crypto)

        let data = try #require(factory.createSignupRequest(from: makeRegistrationStepResult()))

        #expect(data.signupRequest.email == "patient@example.com")
        #expect(data.signupRequest.password == "secret-password")
        #expect(data.signupRequest.first_name == "Ada")
        #expect(data.signupRequest.last_name == "Lovelace")
        #expect(data.signupRequest.type == .patient)
        #expect(data.signupRequest.gender == "female")
        #expect(!data.signupRequest.dob.isEmpty)
        #expect(data.signupRequest.phoneNo.isEmpty)
        #expect(data.signupRequest.encryptedMasterKey == "01020309")
        #expect(data.signupRequest.publicKey == "09")
        #expect(data.signupRequest.encryptedDefaultStorageKey == "040509")
        #expect(data.signupRequest.encryptedConfidentialStorageKey == "060709")
        #expect(data.masterKey == [1, 2, 3])
        #expect(data.defaultStorageKey == [4, 5])
        #expect(data.confidentialStorageKey == [6, 7])
    }

    @Test("Signup request ignores raw profile results unless validated profile data is supplied")
    func signupRequestIgnoresRawProfileResults() throws {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())

        let data = try #require(factory.createSignupRequest(
            from: makeRegistrationStepResult(includeProfileDetails: true)
        ))

        #expect(data.signupRequest.email == "patient@example.com")
        #expect(data.signupRequest.first_name == "Ada")
        #expect(data.signupRequest.last_name == "Lovelace")
        #expect(data.signupRequest.gender == "female")
        #expect(data.signupRequest.location == nil)
        #expect(data.signupRequest.conditions == nil)
    }

    @Test("Signup request includes top-level profile values only when explicitly supplied")
    func signupRequestIncludesExplicitProfileData() throws {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let profileData = SignupProfileData(
            location: ProfileLocation(
                country: " Pakistan ",
                city: " Lahore ",
                countryCode: " +92 "
            ),
            conditions: ConditionsResponse(
                status: .reported,
                items: [ReportedCondition(coding: asthma)]
            )
        )

        let data = try #require(factory.createSignupRequest(
            from: makeRegistrationStepResult(includeProfileDetails: true),
            profileData: profileData
        ))
        let location = try #require(data.signupRequest.location)
        let conditions = try #require(data.signupRequest.conditions)

        #expect(location == .init(
            displayName: "Pakistan",
            city: "Lahore",
            countryCode: "+92"
        ))
        #expect(conditions == [.init(code: asthma.code, name: asthma.name)])
    }

    @Test("Signup request preserves None reported as an explicit empty conditions array")
    func signupRequestPreservesNoneReportedConditions() throws {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())
        let profileData = SignupProfileData(
            location: nil,
            conditions: ConditionsResponse(status: .none, items: [])
        )

        let data = try #require(factory.createSignupRequest(
            from: makeRegistrationStepResult(includeProfileDetails: true),
            profileData: profileData
        ))

        #expect(data.signupRequest.location == nil)
        #expect(data.signupRequest.conditions?.isEmpty == true)
    }

    @Test("Signup request rejects profile data outside the approved condition catalogue")
    func signupRequestRejectsInvalidProfileConditions() {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())
        let profileData = SignupProfileData(
            location: nil,
            conditions: ConditionsResponse(
                status: .reported,
                items: [ReportedCondition(coding: MedicalCondition(
                    system: HealthProfileConditionCatalogue.snomedSystem,
                    code: "999999999",
                    name: "Unknown condition"
                ))]
            )
        )

        #expect(factory.createSignupRequest(
            from: makeRegistrationStepResult(),
            profileData: profileData
        ) == nil)
    }

    @Test("Signup request returns nil when required fields are missing")
    func signupRequestReturnsNilWhenRequiredFieldsAreMissing() {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())
        let incompleteStepResult = makeRegistrationStepResult(email: nil)

        let data = factory.createSignupRequest(from: incompleteStepResult)

        #expect(data == nil)
    }

    @Test(
        "Signup request returns nil when required registration values are malformed",
        arguments: [
            makeRegistrationStepResult(password: nil),
            makeRegistrationStepResult(gender: nil),
            makeRegistrationStepResult(dob: nil)
        ]
    )
    func signupRequestReturnsNilWhenRequiredRegistrationValuesAreMalformed(stepResult: ORKStepResult) {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())

        let data = factory.createSignupRequest(from: stepResult)

        #expect(data == nil)
    }

    @Test("Signup request returns nil when key pair derivation fails")
    func signupRequestReturnsNilWhenKeyPairDerivationFails() {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto(shouldReturnKeyPair: false))

        let data = factory.createSignupRequest(from: makeRegistrationStepResult())

        #expect(data == nil)
    }

    @Test("Signup request falls back to default patient names when optional names are missing")
    func signupRequestFallsBackToDefaultPatientNamesWhenOptionalNamesAreMissing() throws {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto())

        let data = try #require(factory.createSignupRequest(
            from: makeRegistrationStepResult(firstName: nil, lastName: nil)
        ))

        #expect(data.signupRequest.first_name == "patientFirstName")
        #expect(data.signupRequest.last_name == "patientLastName")
    }

    @Test(
        "Signup request returns nil when crypto operation throws",
        arguments: AuthSignupFakeCrypto.ThrowingOperation.allCases
    )
    fileprivate func signupRequestReturnsNilWhenCryptoOperationThrows(
        operation: AuthSignupFakeCrypto.ThrowingOperation
    ) {
        let factory = SignupRequestFactory(crypto: AuthSignupFakeCrypto(throwingOperation: operation))

        let data = factory.createSignupRequest(from: makeRegistrationStepResult())

        #expect(data == nil)
    }
}

@Suite("Social signup request factory")
struct SocialSignupRequestFactoryTests {
    @Test("Social signup uses the email signup parent-level profile contract")
    func socialSignupUsesSharedProfileContract() throws {
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let profileData = SignupProfileData(
            location: ProfileLocation(
                country: " Portugal ",
                city: " Lisbon ",
                countryCode: " +351 "
            ),
            conditions: ConditionsResponse(
                status: .reported,
                items: [ReportedCondition(coding: asthma)]
            )
        )

        let request = try SocialSignupRequestFactory().createRequest(
            socialType: .apple,
            identityToken: "identity-token",
            profileData: profileData
        )

        #expect(request.userType == .patient)
        #expect(request.socialType == .apple)
        #expect(request.requestType == .signup)
        #expect(request.identityToken == "identity-token")
        #expect(request.location == .init(
            displayName: "Portugal",
            city: "Lisbon",
            countryCode: "+351"
        ))
        #expect(request.conditions == [.init(code: asthma.code, name: asthma.name)])
    }

    @Test("Social signup preserves omitted and None reported conditions")
    func socialSignupPreservesConditionsSemantics() throws {
        let omitted = try SocialSignupRequestFactory().createRequest(
            socialType: .gmail,
            identityToken: "identity-token",
            profileData: nil
        )
        let noneReported = try SocialSignupRequestFactory().createRequest(
            socialType: .gmail,
            identityToken: "identity-token",
            profileData: SignupProfileData(
                location: nil,
                conditions: ConditionsResponse(status: .none, items: [])
            )
        )

        #expect(omitted.location == nil)
        #expect(omitted.conditions == nil)
        #expect(noneReported.location == nil)
        #expect(noneReported.conditions?.isEmpty == true)
    }

    @Test("Social signup JSON uses parent-level profile fields and social login omits them")
    func socialRequestJSONEnforcesProfileBoundary() throws {
        let location = OTFCloudClientAPI.Request.SignUpLocation(
            displayName: "Portugal",
            city: "Lisbon",
            countryCode: "+351"
        )
        let conditions = [OTFCloudClientAPI.Request.SignUpCondition(code: "195967001", name: "Asthma")]
        let signup = OTFCloudClientAPI.Request.SocialLogin(
            userType: .patient,
            socialType: .apple,
            authType: .signup,
            identityToken: "identity-token",
            location: location,
            conditions: conditions
        )
        let login = OTFCloudClientAPI.Request.SocialLogin(
            userType: .patient,
            socialType: .apple,
            authType: .login,
            identityToken: "identity-token",
            location: location,
            conditions: conditions
        )

        let signupJSON = try jsonPayload(for: signup)
        let loginJSON = try jsonPayload(for: login)

        #expect(signupJSON["userInfo"] == nil)
        #expect(signupJSON["attachments"] == nil)
        #expect(signupJSON["location"] as? [String: String] == [
            "displayName": "Portugal",
            "city": "Lisbon",
            "countryCode": "+351"
        ])
        #expect(signupJSON["conditions"] as? [[String: String]] == [[
            "code": "195967001",
            "name": "Asthma"
        ]])
        #expect(loginJSON["location"] == nil)
        #expect(loginJSON["conditions"] == nil)
    }

    private func jsonPayload(
        for request: OTFCloudClientAPI.Request.SocialLogin
    ) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private final class AuthSignupFakeCrypto: SignupCryptoProviding {
    enum ThrowingOperation: CaseIterable {
        case generateMasterKey
        case encryptMasterKey
        case defaultStorageKey
        case confidentialStorageKey
        case encryptDefaultStorageKey
        case encryptConfidentialStorageKey
    }

    private let shouldReturnKeyPair: Bool
    private let throwingOperation: ThrowingOperation?
    private var encryptCallCount = 0

    init(
        shouldReturnKeyPair: Bool = true,
        throwingOperation: ThrowingOperation? = nil
    ) {
        self.shouldReturnKeyPair = shouldReturnKeyPair
        self.throwingOperation = throwingOperation
    }

    func generateMasterKey(password: String, email: String) throws -> Bytes {
        #expect(password == "secret-password")
        #expect(email == "patient@example.com")
        if throwingOperation == .generateMasterKey {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        return [1, 2, 3]
    }

    func keyPair(seed: Bytes) -> Box.KeyPair? {
        #expect(seed == [1, 2, 3])
        guard shouldReturnKeyPair else { return nil }
        return Box.KeyPair(publicKey: [9], secretKey: [8])
    }

    func encryptSealedBox(bytes: Bytes, recipientPublicKey: Bytes) throws -> Bytes {
        #expect(recipientPublicKey == [9])
        encryptCallCount += 1
        if throwingOperation == .encryptMasterKey, encryptCallCount == 1 {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        if throwingOperation == .encryptDefaultStorageKey, encryptCallCount == 2 {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        if throwingOperation == .encryptConfidentialStorageKey, encryptCallCount == 3 {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        return bytes + [9]
    }

    func defaultStorageKey(from masterKey: Bytes) throws -> Bytes {
        #expect(masterKey == [1, 2, 3])
        if throwingOperation == .defaultStorageKey {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        return [4, 5]
    }

    func confidentialStorageKey(from masterKey: Bytes) throws -> Bytes {
        #expect(masterKey == [1, 2, 3])
        if throwingOperation == .confidentialStorageKey {
            throw AuthSignupFakeCryptoError.requestedFailure
        }
        return [6, 7]
    }
}

private enum AuthSignupFakeCryptoError: Error {
    case requestedFailure
}

private func makeRegistrationStepResult(
    email: String? = "patient@example.com",
    password: String? = "secret-password",
    firstName: String? = "Ada",
    lastName: String? = "Lovelace",
    gender: String? = "female",
    dob: Date? = Date(timeIntervalSince1970: 0),
    includeProfileDetails: Bool = false
) -> ORKStepResult {
    let emailResult = ORKTextQuestionResult(identifier: ORKRegistrationFormItemIdentifierEmail)
    emailResult.textAnswer = email

    let passwordResult = ORKTextQuestionResult(identifier: ORKRegistrationFormItemIdentifierPassword)
    passwordResult.textAnswer = password

    let unusedResult = ORKTextQuestionResult(identifier: "unused")

    let firstNameResult = ORKTextQuestionResult(identifier: ORKRegistrationFormItemIdentifierGivenName)
    firstNameResult.textAnswer = firstName

    let lastNameResult = ORKTextQuestionResult(identifier: ORKRegistrationFormItemIdentifierFamilyName)
    lastNameResult.textAnswer = lastName

    let genderResult = ORKChoiceQuestionResult(identifier: ORKRegistrationFormItemIdentifierGender)
    genderResult.choiceAnswers = gender.map { [$0 as NSString] }

    let dobResult = ORKDateQuestionResult(identifier: ORKRegistrationFormItemIdentifierDOB)
    dobResult.dateAnswer = dob

    var results: [ORKResult] = [
        dobResult,
        unusedResult,
        lastNameResult,
        genderResult,
        emailResult,
        firstNameResult,
        passwordResult
    ]
    if includeProfileDetails {
        let locationResult = ORKTextQuestionResult(identifier: Constants.Auth.registrationLocationCity)
        locationResult.textAnswer = "Lisbon"
        let conditionsResult = ORKChoiceQuestionResult(identifier: Constants.Auth.registrationConditions)
        conditionsResult.choiceAnswers = [
            "\(HealthProfileConditionCatalogue.snomedSystem)|195967001" as NSString
        ]
        results += [locationResult, conditionsResult]
    }
    return ORKStepResult(stepIdentifier: Constants.Auth.registrationStep, results: results)
}
