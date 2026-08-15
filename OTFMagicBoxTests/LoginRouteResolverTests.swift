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
import Testing
@testable import OTFMagicBox

@Suite("Login route resolver")
struct LoginRouteResolverTests {
    @Test("Verification failures route to resend email")
    func verificationFailuresRouteToResendEmail() {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://doctor.example.com")
        let route = resolver.failureRoute(for: makeLoginForgeError(statusCode: 601, message: "Verify your email"))

        #expect(route == .resendVerificationEmail)
    }

    @Test("Generic failures show login error message")
    func genericFailuresShowLoginErrorMessage() {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://doctor.example.com")
        let route = resolver.failureRoute(for: makeLoginForgeError(statusCode: 401, message: "Invalid credentials"))

        #expect(route == .showLoginError(message: "Invalid credentials"))
    }

    @Test("Patient success carries encrypted storage keys")
    func patientSuccessCarriesEncryptedStorageKeys() {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://doctor.example.com")
        let response = makeLoginResponse(
            type: .patient,
            encryptedDefaultStorageKey: "encrypted-default",
            encryptedConfidentialStorageKey: "encrypted-confidential"
        )

        let route = resolver.successRoute(for: response)

        #expect(route == .patient(
            encryptedDefaultStorageKeyHex: "encrypted-default",
            encryptedConfidentialStorageKeyHex: "encrypted-confidential"
        ))
    }

    @Test("Doctor success routes to configured portal URL")
    func doctorSuccessRoutesToConfiguredPortalURL() throws {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://doctor.example.com/portal")
        let response = makeLoginResponse(type: .doctor)

        let route = try #require(resolver.successRoute(for: response))

        #expect(route == .doctorPortal(URL(string: "https://doctor.example.com/portal")!))
    }

    @Test("Doctor success returns nil for invalid configured portal URL")
    func doctorSuccessReturnsNilForInvalidConfiguredPortalURL() {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://[invalid")
        let response = makeLoginResponse(type: .doctor)

        let route = resolver.successRoute(for: response)

        #expect(route == nil)
    }

    @Test("Every non-patient success routes to the configured portal URL")
    func everyNonPatientSuccessRoutesToConfiguredPortalURL() throws {
        let resolver = LoginRouteResolver(doctorPortalURLString: "https://doctor.example.com/portal")

        for userType in UserType.allCases where userType != .patient {
            let route = try #require(resolver.successRoute(for: makeLoginResponse(type: userType)))
            #expect(route == .doctorPortal(URL(string: "https://doctor.example.com/portal")!))
        }
    }
}

private func makeLoginForgeError(statusCode: Int, message: String) -> ForgeError {
    ForgeError(error: .init(statusCode: statusCode, name: "login", message: message, code: nil))
}

private func makeLoginResponse(
    type: UserType,
    encryptedDefaultStorageKey: String? = nil,
    encryptedConfidentialStorageKey: String? = nil
) -> Response.Login {
    Response.Login(
        error: false,
        message: nil,
        data: Response.User(
            id: "user-id",
            email: "user@example.com",
            firstName: "Ada",
            lastName: "Lovelace",
            type: type,
            gender: .other,
            dob: "2000-01-01",
            encryptedMasterKey: "encrypted-master",
            encryptedConfidentialStorageKey: encryptedConfidentialStorageKey,
            encryptedDefaultStorageKey: encryptedDefaultStorageKey
        ),
        accessToken: Auth(token: "token", refreshToken: "refresh", iat: 0, exp: .greatestFiniteMagnitude)
    )
}
