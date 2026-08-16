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
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("TheraForge HTTP interceptor")
struct TheraForgeHTTPInterceptorTests {
    @Test("Thera Forge HTTP Interceptor Adds Replication Auth Headers")
    func theraForgeHTTPInterceptorAddsReplicationAuthHeaders() throws {
        let url = try #require(URL(string: "https://stg.theraforge.org/api/v1/db/doc-1"))
        let context = CDTHTTPInterceptorContext(request: NSMutableURLRequest(url: url))

        let result = try #require(
            TheraForgeHTTPInterceptor(
                authorizationHeader: "Bearer injected-token",
                clientIdentifierProvider: { "test-client-id" },
                apiKeyProvider: { "test-api-key" }
            )
                .interceptRequest(in: context)
        )

        #expect(result.request.value(forHTTPHeaderField: "API-KEY") == "test-api-key")
        #expect(result.request.value(forHTTPHeaderField: "Authorization") == "Bearer injected-token")
        #expect(result.request.value(forHTTPHeaderField: "Client") == "test-client-id")
    }

    @Test("Thera Forge HTTP Interceptor Mocks Deleted Document With Revision History")
    func theraForgeHTTPInterceptorMocksDeletedDocumentWithRevisionHistory() throws {
        let url = try #require(URL(
            string: "https://stg.theraforge.org/api/v1/db/outcome-1?rev=12-abc123&latest=true&revs=true"
        ))
        let request = NSMutableURLRequest(url: url)
        let context = CDTHTTPInterceptorContext(request: request)
        context.response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        context.responseData = Data(#"{"error":"not_found","reason":"deleted"}"#.utf8)

        let result = try #require(TheraForgeHTTPInterceptor().interceptResponse(in: context))
        let responseData = try #require(result.responseData)
        let body = try #require(JSONSerialization.jsonObject(with: responseData) as? [String: Any])
        let revisions = try #require(body["_revisions"] as? [String: Any])

        #expect(result.response?.statusCode == 200)
        #expect(body["_id"] as? String == "outcome-1")
        #expect(body["_rev"] as? String == "12-abc123")
        #expect(body["_deleted"] as? Bool == true)
        #expect(revisions["start"] as? Int == 12)
        #expect(revisions["ids"] as? [String] == ["abc123"])
    }

    @Test("Thera Forge HTTP Interceptor Does Not Mock Checkpoint 404")
    func theraForgeHTTPInterceptorDoesNotMockCheckpoint404() throws {
        let url = try #require(URL(
            string: "https://stg.theraforge.org/api/v1/db/_local/checkpoint-id"
        ))
        let request = NSMutableURLRequest(url: url)
        let context = CDTHTTPInterceptorContext(request: request)
        let originalBody = Data(#"{"error":"not_found","reason":"missing"}"#.utf8)
        context.response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        context.responseData = originalBody

        let result = try #require(TheraForgeHTTPInterceptor().interceptResponse(in: context))

        #expect(result.response?.statusCode == 404)
        #expect(result.responseData == originalBody)
    }

    @Test("Replication debug logging emits only the response status")
    func replicationDebugLoggingContainsOnlyResponseStatus() throws {
        let url = try #require(URL(string: "https://stg.theraforge.org/api/v1/db/patient-document"))
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        let context = CDTHTTPInterceptorContext(request: request)
        context.response = HTTPURLResponse(
            url: url,
            statusCode: 201,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        context.responseData = Data(#"{"city":"Fixture City","condition":"Asthma"}"#.utf8)
        var messages: [String] = []
        let interceptor = TheraForgeHTTPInterceptor(
            verboseLoggingEnabled: true,
            responseLogHandler: { messages.append($0) }
        )

        _ = interceptor.interceptResponse(in: context)

        #expect(messages == ["TheraForgeHTTPInterceptor: replication response completed (HTTP 201)."])
        let message = try #require(messages.first)
        #expect(!message.contains("POST"))
        #expect(!message.contains("response bytes"))
        #expect(!message.contains("patient-document"))
        #expect(!message.contains("Fixture City"))
        #expect(!message.contains("Asthma"))
    }
}
