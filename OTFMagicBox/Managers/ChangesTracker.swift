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
#if canImport(OTFCareKitStore)
import OTFCareKitStore
#endif

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
/// - Triggers sync only when the remote revision is missing, newer, or divergent locally.
/// - Ignores changes already present locally to avoid echo-syncing this device's own push.
/// - Handles deletions by directly removing local documents to prevent 404 errors during pull.
class ChangesTracker {

    // MARK: - Private Properties

    typealias RemoteChangeHandler = (
        _ changedDocumentIDs: [String],
        _ deletedDocumentIDs: [String],
        _ typedDeletions: [OTFWatchSyncDeletion]
    ) -> Void
    typealias RequestStarter = (URLRequest, @escaping (Data?, Error?) -> Void) -> Void
    typealias RetryScheduler = (TimeInterval, @escaping () -> Void) -> Void

    private let datastore: CDTDatastore
    private let remoteURL: URL
    private let startRequest: RequestStarter
    private let startDeletionSweepRequest: RequestStarter
    private let scheduleAfter: RetryScheduler
    private let remoteChangeHandler: RemoteChangeHandler
    private let defaults: UserDefaults
    private var isTracking = false
    private var lastSequenceToken = "now"
    private let logger = OTFLogger.logger()
    private let deletionSweepSequenceKey = "changes.tracker.deletion.sweep.sequence"

    /// Retry delay in seconds when a connection error occurs.
    private let retryDelaySeconds: TimeInterval = 5
    private let idlePollDelaySeconds: TimeInterval = 5

    /// Heartbeat interval in milliseconds for the longpoll connection.
    private let heartbeatMs = "30000"
    private let verboseLoggingEnabled = ProcessInfo.processInfo.environment["OTF_VERBOSE_REPLICATION_LOGS"] == "1"

    // MARK: - Initialization

    /// Creates a new ChangesTracker.
    /// - Parameters:
    ///   - datastore: The local CDTDatastore to update when deletions are detected.
    ///   - remoteURL: The base URL of the remote Cloudant/CouchDB database.
    init(
        datastore: CDTDatastore,
        remoteURL: URL,
        startRequest: @escaping RequestStarter = ChangesTracker.defaultStartRequest,
        startDeletionSweepRequest: @escaping RequestStarter = ChangesTracker.defaultStartRequest,
        scheduleAfter: @escaping RetryScheduler = ChangesTracker.defaultScheduleAfter,
        remoteChangeHandler: @escaping RemoteChangeHandler = { _, _, _ in },
        defaults: UserDefaults = .standard
    ) {
        self.datastore = datastore
        self.remoteURL = remoteURL
        self.startRequest = startRequest
        self.startDeletionSweepRequest = startDeletionSweepRequest
        self.scheduleAfter = scheduleAfter
        self.remoteChangeHandler = remoteChangeHandler
        self.defaults = defaults
    }

    // MARK: - Public Methods

    /// Starts tracking changes from the remote database.
    func start() {
        guard !isTracking else { return }
        isTracking = true
        lastSequenceToken = "now"
        logger.info("ChangesTracker: Starting change tracking")
        trackChanges()
    }

    /// Stops tracking changes.
    func stop() {
        isTracking = false
        logger.info("ChangesTracker: Stopped change tracking")
    }

    /// Applies remote tombstones before replication so stale local outcomes cannot be pushed back.
    ///
    /// The sweep only deletes a local document when the remote deleted revision is newer than the
    /// local revision. That keeps old tombstones from erasing newer local work while still allowing
    /// devices that were offline to catch up with deletions made elsewhere.
    func performDeletionSweep(completion: @escaping () -> Void) {
        guard let url = buildChangesURL(since: deletionSweepSinceToken, feed: nil, heartbeat: nil) else {
            logger.error("ChangesTracker: Failed to build deletion sweep URL")
            completion()
            return
        }

        var request = URLRequest(url: url)
        addAuthHeaders(to: &request)

        startDeletionSweepRequest(request) { [weak self] data, error in
            guard let self else {
                completion()
                return
            }

            if let error {
                self.logger.error("ChangesTracker deletion sweep error: \(error.localizedDescription)")
                completion()
                return
            }

            let summary = data.map(self.processDeletionSweep) ?? .empty
            if self.verboseLoggingEnabled || summary.deletedCount > 0 || summary.skippedCount > 0 {
                self.logger.info(
                    "ChangesTracker: deletion sweep deleted=\(summary.deletedCount) skipped=\(summary.skippedCount)"
                )
            }
            completion()
        }
    }

    // MARK: - Private Methods

    private var deletionSweepSinceToken: String {
        defaults.string(forKey: deletionSweepSequenceKey) ?? "0"
    }

    private func trackChanges() {
        guard isTracking else { return }

        guard let url = buildChangesURL(since: lastSequenceToken, feed: "longpoll", heartbeat: heartbeatMs) else {
            logger.error("ChangesTracker: Failed to build changes URL")
            return
        }

        var request = URLRequest(url: url)
        addAuthHeaders(to: &request)

        startRequest(request) { [weak self] data, error in
            self?.handleChangesResponse(data: data, error: error)
        }
    }

    private static func defaultStartRequest(
        _ request: URLRequest,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            completion(data, error)
        }.resume()
    }

    private static func defaultScheduleAfter(
        _ delay: TimeInterval,
        work: @escaping () -> Void
    ) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func buildChangesURL(since: String, feed: String?, heartbeat: String?) -> URL? {
        let changesURL = remoteURL.appendingPathComponent("_changes")
        var components = URLComponents(url: changesURL, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "style", value: "all_docs"),
            URLQueryItem(name: "since", value: since)
        ]
        if let feed {
            queryItems.append(URLQueryItem(name: "feed", value: feed))
        }
        if let heartbeat {
            queryItems.append(URLQueryItem(name: "heartbeat", value: heartbeat))
        }
        components?.queryItems = queryItems
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

        let processedChanges = data.map(processChanges) ?? .empty
        continueTracking(after: processedChanges.hasActivity ? 0 : idlePollDelaySeconds)
    }

    private func scheduleRetry() {
        scheduleAfter(self.retryDelaySeconds) { [weak self] in
            self?.trackChanges()
        }
    }

    private func continueTracking(after delay: TimeInterval) {
        let work: () -> Void = { [weak self] in
            self?.trackChanges()
        }

        if delay <= 0 {
            DispatchQueue.global().async(execute: work)
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    private func processChanges(_ data: Data) -> ProcessedChanges {
        do {
            guard let payload = try decodeChangesPayload(from: data) else {
                return .empty
            }

            updateLastSequenceToken(payload.lastSequenceToken)

            let batch = processChangeResults(payload.results)
            logProcessedChanges(batch)
            notifyRemoteChanges(batch)

            return batch.processedChanges
        } catch {
            logger.error("ChangesTracker: JSON parse error: \(error)")
            return .empty
        }
    }

    private func decodeChangesPayload(from data: Data) throws -> ChangesPayload? {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return nil
        }

        return ChangesPayload(
            results: results,
            lastSequenceToken: json["last_seq"].map { String(describing: $0) }
        )
    }

    private func updateLastSequenceToken(_ token: String?) {
        guard let token else { return }
        lastSequenceToken = token
    }

    private func processChangeResults(_ results: [[String: Any]]) -> ProcessedChangeBatch {
        var batch = ProcessedChangeBatch()

        for change in results {
            guard let docId = change["id"] as? String else { continue }

            if change["deleted"] as? Bool == true {
                processDeletedChange(id: docId, change: change, batch: &batch)
            } else {
                processChangedDocument(id: docId, change: change, batch: &batch)
            }
        }

        return batch
    }

    private func processDeletedChange(
        id docId: String,
        change: [String: Any],
        batch: inout ProcessedChangeBatch
    ) {
        let typedDeletion = typedDeletionDescriptor(for: docId)
        let deletionResult = deleteLocalDocumentIfRemoteDeletionIsNewer(
            id: docId,
            deletedRevId: deletedRevisionID(from: change)
        )

        var locallyDeletedDocumentIDs = batch.recordPrimaryDeletionResult(deletionResult, documentID: docId)

        guard deletionResult != .failed else { return }

        let matchingDeletedDocumentIDs = deleteLocalOutcomeDocumentsMatchingDeletedDocumentID(docId)
        if !matchingDeletedDocumentIDs.isEmpty {
            locallyDeletedDocumentIDs.append(docId)
            locallyDeletedDocumentIDs.append(contentsOf: matchingDeletedDocumentIDs)
        }
        batch.recordDeletedDocuments(
            locallyDeletedDocumentIDs,
            typedDeletion: typedDeletion
        )
    }

    private func processChangedDocument(
        id docId: String,
        change: [String: Any],
        batch: inout ProcessedChangeBatch
    ) {
        batch.changedCount += 1

        guard shouldPullRemoteRevision(id: docId, remoteRevId: revisionID(from: change)) else {
            return
        }

        batch.remoteRevisionCount += 1
        batch.changedDocumentIDs.append(docId)
    }

    private func logProcessedChanges(_ batch: ProcessedChangeBatch) {
        guard verboseLoggingEnabled || batch.deletedCount > 0 || batch.remoteRevisionCount > 0 else {
            return
        }

        logger.info(
            "ChangesTracker: processed batch changed=\(batch.changedCount) remoteNeeded=\(batch.remoteRevisionCount) deleted=\(batch.deletedCount) missingLocal=\(batch.missingLocalCount)"
        )
    }

    private func notifyRemoteChanges(_ batch: ProcessedChangeBatch) {
        guard !batch.changedDocumentIDs.isEmpty || !batch.deletedDocumentIDs.isEmpty else {
            return
        }

        remoteChangeHandler(batch.changedDocumentIDs, batch.deletedDocumentIDs, batch.typedDeletions)
    }

    private struct ChangesPayload {
        let results: [[String: Any]]
        let lastSequenceToken: String?
    }

    private struct ProcessedChangeBatch {
        var changedCount = 0
        var remoteRevisionCount = 0
        var changedDocumentIDs = [String]()
        var deletedCount = 0
        var deletedDocumentIDs = [String]()
        var typedDeletions = [OTFWatchSyncDeletion]()
        var missingLocalCount = 0

        var processedChanges: ProcessedChanges {
            ProcessedChanges(
                changedCount: changedCount,
                deletedCount: deletedCount,
                missingLocalCount: missingLocalCount
            )
        }

        mutating func recordPrimaryDeletionResult(
            _ deletionResult: LocalDeletionResult,
            documentID: String
        ) -> [String] {
            switch deletionResult {
            case .deleted:
                deletedCount += 1
                return [documentID]
            case .missing:
                missingLocalCount += 1
                return []
            case .failed:
                return []
            }
        }

        mutating func recordDeletedDocuments(
            _ locallyDeletedDocumentIDs: [String],
            typedDeletion: OTFWatchSyncDeletion?
        ) {
            guard !locallyDeletedDocumentIDs.isEmpty else { return }

            let deletedIDs = Array(Set(locallyDeletedDocumentIDs)).sorted()
            deletedDocumentIDs.append(contentsOf: deletedIDs)
            guard let typedDeletion else { return }
            typedDeletions.append(typedDeletion)
        }
    }

    private struct ProcessedChanges {
        let changedCount: Int
        let deletedCount: Int
        let missingLocalCount: Int

        var hasActivity: Bool {
            changedCount > 0 || deletedCount > 0 || missingLocalCount > 0
        }

        static let empty = ProcessedChanges(changedCount: 0, deletedCount: 0, missingLocalCount: 0)
    }

#if DEBUG
    @discardableResult
    func processChangesForTesting(_ data: Data) -> Bool {
        processChanges(data).hasActivity
    }
#endif

    private struct DeletionSweepSummary {
        let deletedCount: Int
        let skippedCount: Int

        static let empty = DeletionSweepSummary(deletedCount: 0, skippedCount: 0)
    }

    private enum LocalDeletionResult {
        case deleted
        case missing
        case failed
    }

    private func processDeletionSweep(_ data: Data) -> DeletionSweepSummary {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return .empty
            }

            if let lastSeq = json["last_seq"] {
                defaults.set(String(describing: lastSeq), forKey: deletionSweepSequenceKey)
            }

            var deletedCount = 0
            var skippedCount = 0

            for change in results {
                guard change["deleted"] as? Bool == true,
                      let docId = change["id"] as? String,
                      let deletedRevId = deletedRevisionID(from: change) else {
                    continue
                }

                let deletionResult = deleteLocalDocumentIfRemoteDeletionIsNewer(id: docId, deletedRevId: deletedRevId)
                switch deletionResult {
                case .deleted:
                    deletedCount += 1
                case .missing:
                    break
                case .failed:
                    skippedCount += 1
                }
                if deletionResult != .failed {
                    deletedCount += deleteLocalOutcomeDocumentsMatchingDeletedDocumentID(docId).count
                }
            }

            return DeletionSweepSummary(deletedCount: deletedCount, skippedCount: skippedCount)
        } catch {
            logger.error("ChangesTracker deletion sweep JSON parse error: \(error)")
            return .empty
        }
    }

    private func deletedRevisionID(from change: [String: Any]) -> String? {
        revisionID(from: change)
    }

    private func revisionID(from change: [String: Any]) -> String? {
        guard let changes = change["changes"] as? [[String: Any]] else {
            return nil
        }
        return changes.compactMap { $0["rev"] as? String }.first
    }

    private func shouldPullRemoteRevision(id: String, remoteRevId: String?) -> Bool {
        guard let remoteRevId else {
            return true
        }

        guard let localRevision = try? datastore.getDocumentWithId(id),
              let localRevId = localRevision.revId else {
            return true
        }

        guard localRevId != remoteRevId else {
            return false
        }

        guard let remoteGeneration = revisionGeneration(remoteRevId),
              let localGeneration = revisionGeneration(localRevId) else {
            return true
        }

        return remoteGeneration >= localGeneration
    }

    @discardableResult
    private func deleteLocalDocumentIfRemoteDeletionIsNewer(id: String, deletedRevId: String?) -> LocalDeletionResult {
        do {
            guard let revision = try? datastore.getDocumentWithId(id) else {
                return .missing
            }

            guard let deletedRevId else {
                return .failed
            }

            guard isRemoteRevision(deletedRevId, newerThan: revision.revId) else {
                return .failed
            }

            try datastore.deleteDocument(from: revision)
            return .deleted
        } catch {
            logger.error("ChangesTracker: Failed to sweep deleted doc \(id): \(error)")
            return .failed
        }
    }

    private func isRemoteRevision(_ remoteRevId: String, newerThan localRevId: String?) -> Bool {
        guard let localRevId,
              let remoteGeneration = revisionGeneration(remoteRevId),
              let localGeneration = revisionGeneration(localRevId) else {
            return false
        }

        return remoteGeneration > localGeneration
    }

    private func revisionGeneration(_ revId: String) -> Int? {
        Int(revId.split(separator: "-", maxSplits: 1).first ?? "")
    }

    private func typedDeletionDescriptor(for documentID: String) -> OTFWatchSyncDeletion? {
#if canImport(OTFCareKitStore)
        if let outcomeIdentity = outcomeIdentity(forCanonicalDocumentID: documentID) {
            return OTFWatchSyncDeletion(
                documentID: documentID,
                entityType: .outcome,
                taskUUID: outcomeIdentity.taskUUID,
                occurrenceIndex: outcomeIdentity.occurrenceIndex
            )
        }

        guard let revision = try? datastore.getDocumentWithId(documentID),
              let body = revision.body as? [String: Any],
              body["entityType"] as? String == String(describing: OCKTask.self) else {
            return nil
        }

        return OTFWatchSyncDeletion(documentID: documentID, entityType: .task)
#else
        return nil
#endif
    }

    private func deleteLocalOutcomeDocumentsMatchingDeletedDocumentID(_ documentID: String) -> [String] {
#if canImport(OTFCareKitStore)
        guard let logicalKey = logicalOutcomeKey(forCanonicalDocumentID: documentID) else {
            return []
        }

        return (datastore.getAllDocuments() ?? []).compactMap { revision in
            guard let docId = revision.docId,
                  docId != documentID,
                  let body = revision.body as? [String: Any],
                  body["entityType"] as? String == String(describing: OCKOutcome.self),
                  let outcome = try? revision.data(as: OCKOutcome.self),
                  logicalOutcomeKey(outcome) == logicalKey else {
                return nil
            }

            do {
                try datastore.deleteDocument(from: revision)
                return docId
            } catch {
                logger.error("ChangesTracker: Failed to delete matching outcome doc \(docId): \(error)")
                return nil
            }
        }
#else
        return []
#endif
    }

#if canImport(OTFCareKitStore)
    private func logicalOutcomeKey(_ outcome: OCKOutcome) -> String {
        "\(outcome.taskUUID.uuidString)|\(outcome.taskOccurrenceIndex)"
    }

    private func logicalOutcomeKey(forCanonicalDocumentID documentID: String) -> String? {
        guard let outcomeIdentity = outcomeIdentity(forCanonicalDocumentID: documentID) else {
            return nil
        }

        return "\(outcomeIdentity.taskUUID.uuidString)|\(outcomeIdentity.occurrenceIndex)"
    }

    private func outcomeIdentity(forCanonicalDocumentID documentID: String) -> (taskUUID: UUID, occurrenceIndex: Int)? {
        guard let separatorRange = documentID.range(of: "_", options: .backwards) else {
            return nil
        }

        let uuidString = String(documentID[..<separatorRange.lowerBound])
        let occurrenceIndexString = String(documentID[separatorRange.upperBound...])
        guard let taskUUID = UUID(uuidString: uuidString),
              let occurrenceIndex = Int(occurrenceIndexString) else {
            return nil
        }

        return (taskUUID, occurrenceIndex)
    }
#endif

    @discardableResult
    private func deleteLocalDocument(id: String) -> LocalDeletionResult {
        do {
            if let revision = try? datastore.getDocumentWithId(id) {
                try datastore.deleteDocument(from: revision)
                return .deleted
            } else {
                return .missing
            }
        } catch {
            logger.error("ChangesTracker: Failed to delete doc \(id): \(error)")
            return .failed
        }
    }
}
