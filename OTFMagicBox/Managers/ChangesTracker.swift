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
import OTFCloudantStore
import OTFCDTDatastore
import OTFUtilities
import OTFCloudClientAPI

/// Tracks real-time changes from the remote Cloudant/CouchDB database using longpoll.
///
/// `ChangesTracker` monitors the remote database's `_changes` feed to detect when documents
/// are created, updated, or deleted. For deletions, it removes the corresponding local
/// document from the CDTDatastore.
///
/// - Note: This tracker uses `since=now` to only receive new changes, not historical ones.
///   This prevents the "echo effect" where old deletion events would be replayed and
///   unintentionally modify newly created documents.
///
/// ## Important Design Decisions
/// - Does NOT trigger sync on change detection: SSE events already handle remote change syncs.
/// - Does NOT post UI notifications: The sync completion handler posts notifications.
/// - Handles deletions by directly removing local documents to prevent 404 errors during pull.
class ChangesTracker {

    // MARK: - Private Properties

    private let datastore: CDTDatastore
    private let remoteURL: URL
    private var isTracking = false
    private let logger = OTFLogger.logger()

    /// Retry delay in seconds when a connection error occurs.
    private let retryDelaySeconds: TimeInterval = 5

    /// Heartbeat interval in milliseconds for the longpoll connection.
    private let heartbeatMs = "30000"

    // MARK: - Initialization

    /// Creates a new ChangesTracker.
    /// - Parameters:
    ///   - datastore: The local CDTDatastore to update when deletions are detected.
    ///   - remoteURL: The base URL of the remote Cloudant/CouchDB database.
    init(datastore: CDTDatastore, remoteURL: URL) {
        self.datastore = datastore
        self.remoteURL = remoteURL
    }

    // MARK: - Public Methods

    /// Starts tracking changes from the remote database.
    func start() {
        guard !isTracking else { return }
        isTracking = true
        logger.info("ChangesTracker: Starting change tracking")
        trackChanges()
    }

    /// Stops tracking changes.
    func stop() {
        isTracking = false
        logger.info("ChangesTracker: Stopped change tracking")
    }

    /// Performs a deletion sweep. Currently disabled.
    ///
    /// This method was previously used to fetch the entire change history and replay deletions,
    /// but it caused issues where old deletion events would uncheck recently completed tasks.
    /// The live `trackChanges` with `since=now` is sufficient for real-time sync.
    func performDeletionSweep(completion: @escaping () -> Void) {
        completion()
    }

    // MARK: - Private Methods

    private func trackChanges() {
        guard isTracking else { return }

        guard let url = buildChangesURL() else {
            logger.error("ChangesTracker: Failed to build changes URL")
            return
        }

        var request = URLRequest(url: url)
        addAuthHeaders(to: &request)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.handleChangesResponse(data: data, error: error)
        }
        task.resume()
    }

    private func buildChangesURL() -> URL? {
        let changesURL = remoteURL.appendingPathComponent("_changes")
        var components = URLComponents(url: changesURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "feed", value: "longpoll"),
            URLQueryItem(name: "style", value: "all_docs"),
            URLQueryItem(name: "since", value: "now"),
            URLQueryItem(name: "heartbeat", value: heartbeatMs)
        ]
        return components?.url
    }

    private func addAuthHeaders(to request: inout URLRequest) {
        if let configs = TheraForgeNetwork.configurations {
            request.setValue(configs.apiKey, forHTTPHeaderField: "API-KEY")
        }
        request.setValue(TheraForgeNetwork.shared.identifierForVendor, forHTTPHeaderField: "Client")

        if let auth = TheraForgeKeychainService.shared.loadAuth() {
            request.setValue("Bearer \(auth.token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func handleChangesResponse(data: Data?, error: Error?) {
        guard isTracking else { return }

        if let error = error {
            logger.error("ChangesTracker error: \(error.localizedDescription)")
            scheduleRetry()
            return
        }

        if let data = data {
            processChanges(data)
        }

        // Continue tracking (longpoll returns after each batch of changes)
        DispatchQueue.global().async { [weak self] in
            self?.trackChanges()
        }
    }

    private func scheduleRetry() {
        DispatchQueue.global().asyncAfter(deadline: .now() + retryDelaySeconds) { [weak self] in
            self?.trackChanges()
        }
    }

    private func processChanges(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return
            }

            for change in results {
                guard let docId = change["id"] as? String else { continue }

                if let deleted = change["deleted"] as? Bool, deleted {
                    logger.info("ChangesTracker: Detected deletion for doc: \(docId)")
                    deleteLocalDocument(id: docId)
                } else {
                    logger.info("ChangesTracker: Detected change for doc: \(docId)")
                }
            }

            // Note: We do NOT trigger a sync here because:
            // 1. SSE events (db_update) already trigger syncs for remote changes
            // 2. Local changes are pushed by CareKitStoreManager
            // 3. Triggering sync here causes echo effect where your own changes loop back

        } catch {
            logger.error("ChangesTracker: JSON parse error: \(error)")
        }
    }

    private func deleteLocalDocument(id: String) {
        do {
            if let revision = try? datastore.getDocumentWithId(id) {
                try datastore.deleteDocument(from: revision)
                logger.info("ChangesTracker: Deleted local doc: \(id)")
            } else {
                logger.info("ChangesTracker: Doc not found locally or already deleted: \(id)")
            }
        } catch {
            logger.error("ChangesTracker: Failed to delete doc \(id): \(error)")
        }
    }
}
