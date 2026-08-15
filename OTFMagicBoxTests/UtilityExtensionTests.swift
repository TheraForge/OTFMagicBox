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
import Testing
@testable import OTFMagicBox

@Suite("String extensions")
struct StringExtensionTests {
    @Test("Email validation accepts ordinary addresses and rejects malformed addresses")
    func emailValidationAcceptsOrdinaryAddressesAndRejectsMalformedAddresses() {
        #expect("person.name+tag@example.co.uk".isValidEmail)
        #expect("first_last@example.org".isValidEmail)
        #expect(!"missing-at-symbol.example.com".isValidEmail)
        #expect(!"person@example".isValidEmail)
        #expect(!"person @example.com".isValidEmail)
    }

    @Test("SHA256 produces stable lowercase hexadecimal digest")
    func sha256ProducesStableLowercaseDigest() {
        #expect("magic-box".sha256 == "76436737f5b42f68fbeba3abc851a8a5d70eb31419d7650b3a3b582d19dc2742")
    }

    @Test("Hex conversion handles prefixes whitespace mixed case and invalid input")
    func hexConversionHandlesPrefixesWhitespaceMixedCaseAndInvalidInput() {
        #expect(" 0x0A1b2C ".hexToBytes() == [10, 27, 44])
        #expect("FF00".hexToBytes() == [255, 0])
        #expect("abc".hexToBytes() == nil)
        #expect("zz".hexToBytes() == nil)
    }

    @Test("Random nonce honors requested length and allowed character set")
    func randomNonceHonorsRequestedLengthAndAllowedCharacterSet() {
        let nonce = String.makeRandomNonce(ofLength: 16)
        let allowed = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        #expect(nonce.count == 16)
        #expect(Set(nonce).isSubset(of: allowed))
    }
}

@Suite("URLRequest extensions")
struct URLRequestExtensionTests {
    @Test("cURL preserves diagnostics while redacting secrets and body")
    func curlRedactsSecretsAndBody() throws {
        let url = try #require(URL(string: "https://example.com/api"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "API-KEY": "production-key",
            "Authorization": "Bearer secret-token",
            "Cookie": "session=secret",
            "X-Trace": "abc",
            "Accept": "application/json"
        ]
        request.httpBody = Data("can't stop".utf8)

        let curl = request.cURL

        #expect(curl.hasPrefix("curl --verbose"))
        #expect(curl.contains("'https://example.com/api'"))
        #expect(curl.contains("-X POST"))
        #expect(curl.contains("-H 'Accept: application/json'"))
        #expect(curl.contains("-H 'API-KEY: <redacted>'"))
        #expect(curl.contains("-H 'Authorization: <redacted>'"))
        #expect(curl.contains("-H 'Cookie: <redacted>'"))
        #expect(curl.contains("-H 'X-Trace: abc'"))
        #expect(curl.contains("--data '<redacted: 10 bytes>'"))
        #expect(!curl.contains("production-key"))
        #expect(!curl.contains("secret-token"))
        #expect(!curl.contains("session=secret"))
        #expect(!curl.contains("can't stop"))

        var credentialRequest = URLRequest(
            url: try #require(URL(string: "https://sync-user:sync-password@example.com/api"))
        )
        credentialRequest.httpMethod = "GET"
        #expect(!credentialRequest.cURL.contains("sync-user"))
        #expect(!credentialRequest.cURL.contains("sync-password"))

        let acceptRange = try #require(curl.range(of: "Accept"))
        let traceRange = try #require(curl.range(of: "X-Trace"))
        #expect(acceptRange.lowerBound < traceRange.lowerBound)
    }

    @Test("cURL omits GET method and escapes single quotes")
    func curlOmitsGetMethodAndEscapesSingleQuotes() throws {
        let url = try #require(URL(string: "https://example.com/status"))
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.allHTTPHeaderFields = [:]

        #expect(!getRequest.cURL.contains("-X GET"))
        #expect(URLRequest.escapeAllSingleQuotes("Leo's test") == "Leo'\\''s test")
    }
}
