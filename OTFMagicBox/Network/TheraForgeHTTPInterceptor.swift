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
    private let verboseLoggingEnabled: Bool
    private let responseLogHandler: ((String) -> Void)?
    private let authHeaderQueue = DispatchQueue(label: "com.hippocrates.magicbox.replication.auth-header")
    private var cachedAuthorizationHeader: String?
    private let clientIdentifierProvider: () -> String
    private let apiKeyProvider: () -> String

    init(
        authorizationHeader: String? = nil,
        clientIdentifierProvider: @escaping () -> String = {
            "\(TheraForgeNetwork.shared.identifierForVendor)"
        },
        apiKeyProvider: @escaping () -> String = {
            "\(TheraForgeNetwork.configurations!.apiKey)"
        },
        verboseLoggingEnabled: Bool = ProcessInfo.processInfo.environment["OTF_VERBOSE_REPLICATION_LOGS"] == "1",
        responseLogHandler: ((String) -> Void)? = nil
    ) {
        self.cachedAuthorizationHeader = authorizationHeader
        self.clientIdentifierProvider = clientIdentifierProvider
        self.apiKeyProvider = apiKeyProvider
        self.verboseLoggingEnabled = verboseLoggingEnabled
        self.responseLogHandler = responseLogHandler
    }

    // MARK: - CDTHTTPInterceptor

    func interceptRequest(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        context.request.setValue(clientIdentifierProvider(), forHTTPHeaderField: "Client")
        context.request.addValue(apiKeyProvider(), forHTTPHeaderField: "API-KEY")

        if let authorizationHeader {
            context.request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        return context
    }

    func interceptResponse(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        guard let response = context.response, let responseData = context.responseData else {
            if verboseLoggingEnabled {
                logger.info("TheraForgeHTTPInterceptor: replication response metadata is unavailable.")
            }
            return context
        }

        if response.statusCode == 404 {
            return handle404Response(in: context, response: response, responseData: responseData)
        }

        logResponse(response: response)
        return context
    }

    // MARK: - Private Methods

    private var authorizationHeader: String? {
        return authHeaderQueue.sync {
            if let cachedAuthorizationHeader {
                return cachedAuthorizationHeader
            }

            guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
                return nil
            }

            let header = "Bearer \(auth.token)"
            cachedAuthorizationHeader = header
            return header
        }
    }

    /// Handles 404 responses by checking if they represent deleted documents.
    /// If so, mocks a 200 OK response with `_deleted: true` to unblock replication.
    private func handle404Response(
        in context: CDTHTTPInterceptorContext,
        response: HTTPURLResponse,
        responseData: Data
    ) -> CDTHTTPInterceptorContext? {
        guard let url = context.request.url else { return context }

        guard isDocumentRevisionRequest(url: url) else {
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
            return true
        }

        // Some backend tombstones omit the "deleted" reason, but revision GETs still need
        // a deletion body so the puller can mark the remote sequence as processed.
        return true
    }

    /// Checks if the response JSON indicates a deleted document.
    private func isDeletedDocumentResponse(responseData: Data) -> Bool {
        do {
            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                if let error = json["error"] as? String, error == "not_found",
                   let reason = json["reason"] as? String, reason == "deleted" {
                    return true
                }
            }
        } catch {
            if verboseLoggingEnabled {
                logger.error("TheraForgeHTTPInterceptor could not parse a 404 response.")
            }
        }
        return false
    }

    /// Determines if the URL is a document revision fetch instead of a replication control endpoint.
    private func isDocumentRevisionRequest(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.queryItems?.contains(where: { $0.name == "rev" }) == true else {
            return false
        }

        let path = url.path
        return !path.contains("/_local/")
            && !path.contains("/_session")
            && !path.contains("/_changes")
            && !path.contains("/_bulk_get")
            && !path.contains("/_all_docs")
    }

    /// Creates a mocked 200 OK response with `_deleted: true` for the given context.
    private func createMockedDeletedResponse(
        for context: CDTHTTPInterceptorContext,
        url: URL,
        responseData: Data
    ) -> CDTHTTPInterceptorContext? {
        var newBody: [String: Any] = ["_deleted": true]
        newBody["_id"] = documentID(from: url)

        // Preserve revision if available
        if let rev = extractRevision(from: url, responseData: responseData) {
            newBody["_rev"] = rev
            if let revisions = couchRevisionHistory(for: rev) {
                newBody["_revisions"] = revisions
            }
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
        SyncPerformanceTracker.shared.recordTombstone404()
        if verboseLoggingEnabled {
            logger.info("TheraForgeHTTPInterceptor: mocked a deleted-document response.")
        }
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

    private func documentID(from url: URL) -> String {
        let marker = "/db/"
        guard let markerRange = url.path.range(of: marker) else {
            return url.lastPathComponent
        }

        let suffix = String(url.path[markerRange.upperBound...])
        return suffix.removingPercentEncoding ?? suffix
    }

    private func couchRevisionHistory(for revisionID: String) -> [String: Any]? {
        let parts = revisionID.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2,
              let generation = Int(parts[0]),
              generation > 0,
              !parts[1].isEmpty else {
            return nil
        }

        return [
            "start": generation,
            "ids": [String(parts[1])]
        ]
    }

    /// Emits only redacted response metadata so replication debug logs cannot expose patient documents or credentials.
    private func logResponse(response: HTTPURLResponse) {
        guard verboseLoggingEnabled else { return }

        let message = Self.redactedResponseLogMessage(statusCode: response.statusCode)
        if let responseLogHandler {
            responseLogHandler(message)
        } else {
            logger.info("\(message, privacy: .public)")
        }
    }

    static func redactedResponseLogMessage(statusCode: Int) -> String {
        "TheraForgeHTTPInterceptor: replication response completed (HTTP \(statusCode))."
    }
}
