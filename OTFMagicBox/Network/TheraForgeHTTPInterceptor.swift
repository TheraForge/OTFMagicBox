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

import OTFUtilities
import OTFCDTDatastore
import OTFCloudClientAPI

/// HTTP interceptor for Cloudant replication requests.
///
/// This interceptor handles two main responsibilities:
/// 1. **Request Authentication**: Adds required headers (API key, authorization token, client ID)
/// 2. **404 Response Handling**: Mocks 404 responses for deleted documents to prevent replication failures
///
/// When the server returns 404 for a deleted document (tombstone), this interceptor converts
/// the response to a 200 OK with `_deleted: true`, allowing the CDTReplicator to process
/// the deletion gracefully instead of treating it as an error.
class TheraForgeHTTPInterceptor: NSObject, CDTHTTPInterceptor {

    private let logger = OTFLogger.logger()

    // MARK: - CDTHTTPInterceptor

    func interceptRequest(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        context.request.setValue("\(TheraForgeNetwork.shared.identifierForVendor)", forHTTPHeaderField: "Client")
        context.request.addValue("\(TheraForgeNetwork.configurations!.apiKey)", forHTTPHeaderField: "API-KEY")

        if let currentAuth = TheraForgeNetwork.shared.currentAuth {
            context.request.setValue("Bearer \(currentAuth.token)", forHTTPHeaderField: "Authorization")
        } else if let auth = TheraForgeKeychainService.shared.loadAuth() {
            context.request.setValue("Bearer \(auth.token)", forHTTPHeaderField: "Authorization")
        }
        return context
    }

    func interceptResponse(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        logger.info("TheraForgeHTTPInterceptor: \((context.request as URLRequest).cURL)")

        guard let response = context.response, let responseData = context.responseData else {
            logger.info("TheraForgeHTTPInterceptor: Response or data is nil")
            return context
        }

        if response.statusCode == 404 {
            return handle404Response(in: context, response: response, responseData: responseData)
        }

        logResponse(context: context, response: response, responseData: responseData)
        return context
    }

    // MARK: - Private Methods

    /// Handles 404 responses by checking if they represent deleted documents.
    /// If so, mocks a 200 OK response with `_deleted: true` to unblock replication.
    private func handle404Response(
        in context: CDTHTTPInterceptorContext,
        response: HTTPURLResponse,
        responseData: Data
    ) -> CDTHTTPInterceptorContext? {
        guard let url = context.request.url else { return context }

        logger.info("TheraForgeHTTPInterceptor: 404 Detected for URL: \(url.absoluteString)")

        // Ignore session-related 404s (expected when cookie auth is not supported)
        if url.path.contains("_session") {
            return context
        }

        let shouldMock = shouldMock404As200Response(url: url, responseData: responseData)

        if shouldMock {
            return createMockedDeletedResponse(for: context, url: url, responseData: responseData)
        }

        return context
    }

    /// Determines if a 404 response should be mocked as a deleted document.
    private func shouldMock404As200Response(url: URL, responseData: Data) -> Bool {
        // Check if JSON indicates "deleted" reason
        if isDeletedDocumentResponse(responseData: responseData) {
            logger.info("TheraForgeHTTPInterceptor: confirmed 'deleted' reason.")
            return true
        }

        // Fallback: mock if path looks like a document request
        if isDocumentLikePath(url: url) {
            logger.info("TheraForgeHTTPInterceptor: 404 on doc-like path. Mocking to unblock sync.")
            return true
        }

        return false
    }

    /// Checks if the response JSON indicates a deleted document.
    private func isDeletedDocumentResponse(responseData: Data) -> Bool {
        do {
            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                logger.info("TheraForgeHTTPInterceptor: JSON parsed: \(json)")
                if let error = json["error"] as? String, error == "not_found",
                   let reason = json["reason"] as? String, reason == "deleted" {
                    return true
                }
            }
        } catch {
            logger.error("TheraForgeHTTPInterceptor error parsing 404 body: \(error)")
        }
        return false
    }

    /// Determines if the URL path looks like a document request (vs. system endpoints).
    private func isDocumentLikePath(url: URL) -> Bool {
        let lastComponent = url.lastPathComponent
        let path = url.path
        return lastComponent.count > 10 || path.contains("_local") || path.contains("attachments")
    }

    /// Creates a mocked 200 OK response with `_deleted: true` for the given context.
    private func createMockedDeletedResponse(
        for context: CDTHTTPInterceptorContext,
        url: URL,
        responseData: Data
    ) -> CDTHTTPInterceptorContext? {
        var newBody: [String: Any] = ["_deleted": true]
        newBody["_id"] = url.lastPathComponent

        // Preserve revision if available
        if let rev = extractRevision(from: url, responseData: responseData) {
            newBody["_rev"] = rev
        }

        guard let newResponseData = try? JSONSerialization.data(withJSONObject: newBody, options: []) else {
            return context
        }

        let headers = ["Content-Type": "application/json"]
        guard let newResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else {
            return context
        }

        context.response = newResponse
        context.responseData = newResponseData
        logger.info("TheraForgeHTTPInterceptor: Mocked 200 OK for doc: \(url.lastPathComponent)")
        return context
    }

    /// Extracts the document revision from URL query params or response body.
    private func extractRevision(from url: URL, responseData: Data) -> String? {
        // Try URL query parameters first
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let rev = queryItems.first(where: { $0.name == "rev" })?.value {
            return rev
        }

        // Try response body
        if let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
            return json["rev"] as? String ?? json["_rev"] as? String
        }

        return nil
    }

    /// Logs the response details for debugging.
    private func logResponse(
        context: CDTHTTPInterceptorContext,
        response: HTTPURLResponse,
        responseData: Data
    ) {
        let dataString = String(data: responseData, encoding: .utf8) ?? "nil"
        logger.info("TheraForgeHTTPInterceptor Request: \(context.request) Response: \(response) data: \(dataString)")
    }
}
