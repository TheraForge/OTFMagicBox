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

@Suite("Signup request profile-payload compatibility")
struct SignupRequestProfilePayloadCompatibilityTests {
    @Test("Signup request omits profile values when callers use the existing initializer")
    func signupRequestOmitsProfileValuesByDefault() throws {
        let request = makeSignupRequest()
        let payload = try jsonPayload(for: request)

        #expect(request.location == nil)
        #expect(request.conditions == nil)
        #expect(payload["userInfo"] == nil)
        #expect(payload["location"] == nil)
        #expect(payload["conditions"] == nil)
    }

    @Test("Signup request encodes supplied profile values at the parent level")
    func signupRequestEncodesSuppliedProfileValuesAtParentLevel() throws {
        let location = Request.SignUpLocation(displayName: "Portugal", city: "Lisbon", countryCode: "+351")
        let conditions = [Request.SignUpCondition(code: "195967001", name: "Asthma")]
        let request = makeSignupRequest(location: location, conditions: conditions)
        let payload = try jsonPayload(for: request)

        #expect(request.location == location)
        #expect(request.conditions == conditions)
        #expect(payload["userInfo"] == nil)
        #expect(payload["attachments"] == nil)
        #expect(payload["location"] as? [String: String] == [
            "displayName": "Portugal",
            "city": "Lisbon",
            "countryCode": "+351"
        ])
        #expect(payload["conditions"] as? [[String: String]] == [[
            "code": "195967001",
            "name": "Asthma"
        ]])
    }

    private func makeSignupRequest() -> Request.SignUp {
        Request.SignUp(
            email: "patient@example.com",
            password: "secret-password",
            first_name: "Ada",
            last_name: "Lovelace",
            type: .patient,
            dob: "1970-01-01T00:00:00Z",
            gender: "female",
            phoneNo: "",
            encryptedMasterKey: "encrypted-master-key",
            publicKey: "public-key",
            encryptedDefaultStorageKey: "encrypted-default-storage-key",
            encryptedConfidentialStorageKey: "encrypted-confidential-storage-key"
        )
    }

    private func makeSignupRequest(
        location: Request.SignUpLocation,
        conditions: [Request.SignUpCondition]
    ) -> Request.SignUp {
        Request.SignUp(
            email: "patient@example.com",
            password: "secret-password",
            first_name: "Ada",
            last_name: "Lovelace",
            type: .patient,
            dob: "1970-01-01T00:00:00Z",
            gender: "female",
            phoneNo: "",
            encryptedMasterKey: "encrypted-master-key",
            publicKey: "public-key",
            encryptedDefaultStorageKey: "encrypted-default-storage-key",
            encryptedConfidentialStorageKey: "encrypted-confidential-storage-key",
            location: location,
            conditions: conditions
        )
    }

    private func jsonPayload(for request: Request.SignUp) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
