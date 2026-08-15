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

import Foundation
import OTFCareKit
import OTFCareKitStore
import OTFCloudantStore
import OTFCloudClientAPI
import OTFCDTDatastore
import OTFUtilities
import WatchConnectivity

// swiftlint:disable file_length
// The sync coordinator is intentionally kept in one file until it can be split with
// focused regression coverage around replication ordering and deletion handling.

// MARK: - Configuration

/// Configuration for Cloudant replication.
struct Configuration {
    let targetURL: URL
    let username: String
    let password: String

    static var `default`: Configuration {
        let remoteURLString = Constants.Network.dbProxyURL
        let remoteURL = URL(string: remoteURLString)!
        return Configuration(targetURL: remoteURL, username: "", password: "")
    }
}

/// Direction for replication operations.
enum ReplicationDirection: String {
    case push
    case pull
}

enum SyncOrder: Equatable {
    case pushThenPull
    case pullThenPush
    case pullOnly

    var priority: Int {
        switch self {
        case .pullOnly:
            return 0
        case .pullThenPush:
            return 1
        case .pushThenPull:
            return 2
        }
    }

    var requiresDeletionSweep: Bool {
        switch self {
        case .pullOnly:
            return false
        case .pullThenPush, .pushThenPull:
            return true
        }
    }
}

enum ChangesTrackerStartupResult: Equatable {
    case started
    case failed(String)
}

enum DeletionSweepStartupDecision: Equatable {
    case runSweep
    case continueWithoutSweep
    case finishWithError(String)
}

/// Result of trying to complete the delayed watch login handoff after Cloudant sync.
///
/// The pending login is committed only after the auth command has been durably stored in
/// WatchConnectivity. Recoverable availability states keep the pending command for a
/// later retry when activation, pairing, installation, or reachability changes.
enum WatchPendingLoginPublishOutcome: Equatable {
    case skippedNoAuth
    case skippedNoPendingLogin
    case unavailable(reason: WatchAuthPublishUnavailableReason)
    case failed(message: String)
    case stalePending
    case committed
}

func deletionSweepStartupDecision(
    syncOrder: SyncOrder,
    trackerStartupResult: ChangesTrackerStartupResult
) -> DeletionSweepStartupDecision {
    guard syncOrder.requiresDeletionSweep else {
        return .continueWithoutSweep
    }
    switch trackerStartupResult {
    case .started:
        return .runSweep
    case .failed(let reason):
        return .finishWithError(reason)
    }
}

enum CloudantSyncPolicy {
    static func explicitSyncOrder(hasPendingLocalChanges: Bool) -> SyncOrder {
        hasPendingLocalChanges ? .pushThenPull : .pullThenPush
    }

    static func foregroundSyncOrder(
        hasPendingLocalChanges: Bool,
        lastSuccessfulSyncDate: Date?,
        now: Date = Date(),
        maxAge: TimeInterval
    ) -> SyncOrder? {
        if hasPendingLocalChanges {
            return .pushThenPull
        }

        guard let lastSuccessfulSyncDate else {
            return .pullOnly
        }

        guard now.timeIntervalSince(lastSuccessfulSyncDate) >= maxAge else {
            return nil
        }

        return .pullOnly
    }

    static func remoteChangeFeedSyncOrder(hasPendingLocalChanges: Bool) -> SyncOrder {
        hasPendingLocalChanges ? .pushThenPull : .pullOnly
    }
}

struct SyncMaintenanceSummary: Equatable {
    static let empty = SyncMaintenanceSummary(
        backfilledTaskDateMetadata: 0,
        prunedOutcomeDocuments: 0
    )

    let backfilledTaskDateMetadata: Int
    let prunedOutcomeDocuments: Int

    var changedScheduleContent: Bool {
        backfilledTaskDateMetadata > 0 || prunedOutcomeDocuments > 0
    }
}

final class PendingRemoteWatchChanges {

    struct Snapshot: Equatable {
        let changedDocumentIDs: [String]
        let deletedDocumentIDs: [String]
        let typedDeletions: [OTFWatchSyncDeletion]
        fileprivate let changedDocumentGenerations: [String: UInt64]
        fileprivate let deletedDocumentGenerations: [String: UInt64]

        var isEmpty: Bool {
            changedDocumentIDs.isEmpty && deletedDocumentIDs.isEmpty
        }
    }

    private let lock = NSLock()
    private var changedDocumentGenerations = [String: UInt64]()
    private var deletedDocumentGenerations = [String: UInt64]()
    private var typedDeletionsByDocumentID = [String: OTFWatchSyncDeletion]()
    private var nextGeneration: UInt64 = 0

    var hasPendingChanges: Bool {
        lock.lock()
        let hasPendingChanges = !changedDocumentGenerations.isEmpty || !deletedDocumentGenerations.isEmpty
        lock.unlock()
        return hasPendingChanges
    }

    func record(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions: [OTFWatchSyncDeletion] = []
    ) {
        lock.lock()
        var typedDeletionsByID = [String: OTFWatchSyncDeletion]()
        for typedDeletion in typedDeletions {
            typedDeletionsByID[typedDeletion.documentID] = typedDeletion
        }
        for changedDocumentID in changedDocumentIDs {
            changedDocumentGenerations[changedDocumentID] = makeGeneration()
        }
        for deletedDocumentID in deletedDocumentIDs {
            deletedDocumentGenerations[deletedDocumentID] = makeGeneration()
            if let typedDeletion = typedDeletionsByID[deletedDocumentID] {
                typedDeletionsByDocumentID[deletedDocumentID] = typedDeletion
            }
        }
        lock.unlock()
    }

    func snapshot() -> Snapshot {
        lock.lock()
        let deletedDocumentIDs = deletedDocumentGenerations.keys.sorted()
        let snapshot = Snapshot(
            changedDocumentIDs: changedDocumentGenerations.keys.sorted(),
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: typedDeletions(for: deletedDocumentIDs),
            changedDocumentGenerations: changedDocumentGenerations,
            deletedDocumentGenerations: deletedDocumentGenerations
        )
        lock.unlock()
        return snapshot
    }

    func acknowledge(_ snapshot: Snapshot) {
        lock.lock()
        for (changedDocumentID, snapshotGeneration) in snapshot.changedDocumentGenerations
            where changedDocumentGenerations[changedDocumentID] == snapshotGeneration {
            changedDocumentGenerations.removeValue(forKey: changedDocumentID)
        }
        for (deletedDocumentID, snapshotGeneration) in snapshot.deletedDocumentGenerations
            where deletedDocumentGenerations[deletedDocumentID] == snapshotGeneration {
            deletedDocumentGenerations.removeValue(forKey: deletedDocumentID)
            typedDeletionsByDocumentID.removeValue(forKey: deletedDocumentID)
        }
        lock.unlock()
    }

    func snapshot(deletedDocumentIDs requestedDeletedDocumentIDs: [String]) -> Snapshot {
        lock.lock()
        let requestedDeletedDocumentIDs = Set(requestedDeletedDocumentIDs)
        let deletedSnapshot = deletedDocumentGenerations.filter {
            requestedDeletedDocumentIDs.contains($0.key)
        }
        let deletedDocumentIDs = deletedSnapshot.keys.sorted()
        let snapshot = Snapshot(
            changedDocumentIDs: [],
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: typedDeletions(for: deletedDocumentIDs),
            changedDocumentGenerations: [:],
            deletedDocumentGenerations: deletedSnapshot
        )
        lock.unlock()
        return snapshot
    }

    func discardAll() {
        lock.lock()
        changedDocumentGenerations.removeAll()
        deletedDocumentGenerations.removeAll()
        typedDeletionsByDocumentID.removeAll()
        lock.unlock()
    }

    private func typedDeletions(for documentIDs: [String]) -> [OTFWatchSyncDeletion] {
        documentIDs.compactMap { typedDeletionsByDocumentID[$0] }
    }

    private func makeGeneration() -> UInt64 {
        nextGeneration += 1
        return nextGeneration
    }
}

// MARK: - CloudantSyncManager

// swiftlint:disable type_body_length
/// Manages synchronization between the local CDTDatastore and the remote Cloudant database.
///
/// `CloudantSyncManager` coordinates the following:
/// - Push and pull replication with the remote database
/// - Conflict resolution after pull operations
/// - Real-time change tracking via `ChangesTracker`
/// - Client-side index management for query optimization
///
/// ## Sync Flow
/// 1. Push local changes to the server
/// 2. Pull remote changes from the server
/// 3. Resolve any conflicts that arose during pull
/// 4. Optionally post a notification to update the UI
///
/// ## 404 Handling
/// When pulling, 404 errors for deleted documents are treated as normal (not failures).
/// This is because tombstones (deleted document markers) on the server may return 404
/// when the replicator tries to fetch them. `ChangesTracker` handles deletions directly.
struct CloudantSyncRequest {
    var notifyWhenDone: Bool
    var reasons: [String]
    var completions: [((Error?) -> Void)?]
    var syncOrder: SyncOrder

    mutating func merge(_ other: CloudantSyncRequest) {
        notifyWhenDone = notifyWhenDone || other.notifyWhenDone
        reasons.append(contentsOf: other.reasons)
        completions.append(contentsOf: other.completions)
        if other.syncOrder.priority > syncOrder.priority {
            syncOrder = other.syncOrder
        }
    }
}

class CloudantSyncManager {

    private enum FileConstants {
        static let datastore = "local_db"
    }

    private enum DefaultsKeys {
        static let localMutationCount = "cloudant.sync.local.mutation.count"
        static let lastCompactionDate = "cloudant.sync.last.compaction.date"
        static let lastSuccessfulSyncDate = "cloudant.sync.last.successful.date"
    }

    private typealias SyncRequest = CloudantSyncRequest

    // MARK: - Singleton

    static let shared = CloudantSyncManager()

    // MARK: - Public Properties

    var cloudantStore: OTFCloudantStore?
    let peer = OTFWatchConnectivityPeer()
    var lastSuccessfulSyncDate: Date? {
        UserDefaults.standard.object(forKey: DefaultsKeys.lastSuccessfulSyncDate) as? Date
    }
    var hasPendingOfflineChanges: Bool {
        UserDefaults.standard.bool(forKey: Constants.Storage.kPendingOfflineChanges)
    }

    var storeManager: OCKSynchronizedStoreManager {
        CareKitStoreManager.shared.synchronizedStoreManager
    }

    // MARK: - Private Properties

    private var changesTracker: ChangesTracker?
    private let conflictResolver = OutcomeConflictResolver()
    private let logger = OTFLogger.logger()
    private let syncStateQueue = DispatchQueue(label: "CloudantSyncManager.sync.state")
    private var syncInFlight = false
    private var pendingSyncRequest: SyncRequest?
    private var debouncedSyncWorkItem: DispatchWorkItem?
    private let pendingRemoteWatchChanges = PendingRemoteWatchChanges()
    private let pendingRemoteScheduleRefreshChanges = PendingRemoteWatchChanges()
    private let verboseLoggingEnabled = ProcessInfo.processInfo.environment["OTF_SYNC_VERBOSE_LOGS"] == "1"

    // MARK: - Initialization

    private init() {
        peer.outboundMessageContextProvider = {
            guard TheraForgeKeychainService.shared.loadAuth() != nil else {
                return nil
            }
            guard CareKitStoreManager.shared.isWatchSyncReadyForOutboundMessages() else {
                return nil
            }
            return WatchAuthSessionStore.shared.currentContext()
        }
        cloudantStore = try? StoreService.shared.currentStore(peer: peer)
        let startupMaintenanceSummary = performMaintenanceIfNeeded(trigger: "startup")
        if startupMaintenanceSummary.prunedOutcomeDocuments > 0 {
            postSyncNotifications(remoteChangeContext: ScheduleRefreshContext(changeKind: .fullResync))
        }
        logger.debug("CloudantSyncManager: Initialized without resetting the local datastore")
    }
    
    /// Marks that there are pending local changes that need a successful push.
    /// This is set before scheduling outbound sync so a launch or reconnect can retry safely.
    func markPendingOfflineChanges() {
        UserDefaults.standard.set(true, forKey: Constants.Storage.kPendingOfflineChanges)
    }
    
    /// Clears the pending offline changes flag after successful push.
    private func clearPendingOfflineChanges() {
        UserDefaults.standard.set(false, forKey: Constants.Storage.kPendingOfflineChanges)
    }

    func recordLocalMutation() {
        let defaults = UserDefaults.standard
        let currentCount = defaults.integer(forKey: DefaultsKeys.localMutationCount)
        defaults.set(currentCount + 1, forKey: DefaultsKeys.localMutationCount)
    }

    // MARK: - Public Methods

    /// Synchronizes the local Cloudant store with the remote database.
    ///
    /// This method validates authentication and refreshes tokens if needed before syncing.
    /// The sync flow is push-then-pull to ensure local changes are preserved.
    ///
    /// - Parameters:
    ///   - notifyWhenDone: If `true`, posts a `.databaseSynchronized` notification after sync.
    ///   - completion: Called when sync completes, with an error if one occurred.
    func syncCloudantStore(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        SyncPerformanceTracker.shared.recordSyncTrigger(source: "explicit")
        enqueueSync(
            request: SyncRequest(
                notifyWhenDone: notifyWhenDone,
                reasons: ["explicit sync"],
                completions: [completion],
                syncOrder: CloudantSyncPolicy.explicitSyncOrder(
                    hasPendingLocalChanges: hasPendingOfflineChanges
                )
            ),
            debounce: 0
        )
    }

    func scheduleIncrementalSync(
        reason: String,
        notifyWhenDone: Bool = false,
        debounce: TimeInterval = 1.0,
        syncOrder: SyncOrder = .pushThenPull
    ) {
        SyncPerformanceTracker.shared.recordSyncTrigger(source: reason.replacingOccurrences(of: " ", with: "_"))
        enqueueSync(
            request: SyncRequest(
                notifyWhenDone: notifyWhenDone,
                reasons: [reason],
                completions: [nil],
                syncOrder: syncOrder
            ),
            debounce: debounce
        )
    }

    func syncOnForegroundIfNeeded(maxAge: TimeInterval = 45) {
        guard TheraForgeKeychainService.shared.loadAuth() != nil else { return }

        guard let syncOrder = CloudantSyncPolicy.foregroundSyncOrder(
            hasPendingLocalChanges: hasPendingOfflineChanges,
            lastSuccessfulSyncDate: lastSuccessfulSyncDate,
            maxAge: maxAge
        ) else { return }

        let reason: String
        if syncOrder == .pushThenPull {
            reason = "foreground pending offline changes"
        } else if lastSuccessfulSyncDate == nil {
            reason = "foreground initial sync"
        } else {
            reason = "foreground stale sync"
        }
        scheduleIncrementalSync(
            reason: reason,
            notifyWhenDone: true,
            debounce: 0.5,
            syncOrder: syncOrder
        )
    }

    // MARK: - Private Methods

    private func enqueueSync(request: SyncRequest, debounce: TimeInterval) {
        syncStateQueue.async { [weak self] in
            guard let self else { return }

            if debounce > 0 {
                self.debouncedSyncWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.startOrQueueSync(request)
                }
                self.debouncedSyncWorkItem = workItem
                self.syncStateQueue.asyncAfter(deadline: .now() + debounce, execute: workItem)
            } else {
                self.debouncedSyncWorkItem?.cancel()
                self.startOrQueueSync(request)
            }
        }
    }

    private func startOrQueueSync(_ request: SyncRequest) {
        if syncInFlight {
            if var pendingSyncRequest {
                pendingSyncRequest.merge(request)
                self.pendingSyncRequest = pendingSyncRequest
            } else {
                pendingSyncRequest = request
            }
            return
        }

        syncInFlight = true
        performAuthenticatedSync(request)
    }

    private func performAuthenticatedSync(_ request: SyncRequest) {
        guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
            logger.error("CloudantSyncManager: Missing credentials")
            didFinishSync(error: ForgeError.missingCredential, request: request)
            return
        }

        if verboseLoggingEnabled {
            logger.info("CloudantSyncManager: Starting sync for reasons \(request.reasons.joined(separator: ", "))")
        }

        if auth.isValid() {
            startSync(request, authorizationHeader: authorizationHeader(for: auth))
        } else {
            refreshTokenAndSync(request)
        }
    }

    private func refreshTokenAndSync(_ request: SyncRequest) {
        OTFTheraforgeNetwork.shared.refreshToken { [weak self] result in
            switch result {
            case .success:
                let auth = TheraForgeKeychainService.shared.loadAuth()
                let authorizationHeader = auth.map { "Bearer \($0.token)" }
                self?.startSync(request, authorizationHeader: authorizationHeader)
            case .failure(let error):
                self?.logger.error("CloudantSyncManager: Token refresh failed: \(error.localizedDescription)")
                self?.didFinishSync(error: error, request: request)
            }
        }
    }

    private func authorizationHeader(for auth: Auth) -> String {
        "Bearer \(auth.token)"
    }

    private func startSync(_ request: SyncRequest, authorizationHeader: String?) {
        let trackerStartupResult = startChangesTracker()
        switch deletionSweepStartupDecision(
            syncOrder: request.syncOrder,
            trackerStartupResult: trackerStartupResult
        ) {
        case .continueWithoutSweep:
            performReplication(request, authorizationHeader: authorizationHeader)
        case .runSweep:
            changesTracker?.performDeletionSweep { [weak self] in
                self?.performReplication(request, authorizationHeader: authorizationHeader)
            }
        case .finishWithError(let reason):
            logger.error(
                "CloudantSyncManager: Cannot run deletion sweep for \(String(describing: request.syncOrder)): \(reason)"
            )
            didFinishSync(
                error: OCKStoreError.remoteSynchronizationFailed(reason: reason),
                request: request
            )
        }
    }

    private func performReplication(_ request: SyncRequest, authorizationHeader: String?) {
        switch request.syncOrder {
        case .pushThenPull:
            performPushThenPull(request, authorizationHeader: authorizationHeader)
        case .pullThenPush:
            performPullThenPush(request, authorizationHeader: authorizationHeader)
        case .pullOnly:
            performPull(request, authorizationHeader: authorizationHeader)
        }
    }

    private func performPushThenPull(_ request: SyncRequest, authorizationHeader: String?) {
        do {
            try replicate(direction: .push, authorizationHeader: authorizationHeader) { [weak self] pushError, processedChanges, totalChanges, _ in
                guard let self = self else {
                    return
                }

                if let error = pushError {
                    self.logger.error("CloudantSyncManager: Push failed: \(error.localizedDescription)")
                    self.didFinishSync(error: error, request: request)
                    return
                }

                self.logReplicationProgress(direction: .push, processedChanges: processedChanges, totalChanges: totalChanges)
                self.clearPendingOfflineChanges()
                self.performPull(request, authorizationHeader: authorizationHeader)
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start push: \(error.localizedDescription)")
            didFinishSync(error: error, request: request)
        }
    }

    private func performPullThenPush(_ request: SyncRequest, authorizationHeader: String?) {
        do {
            try replicate(direction: .pull, authorizationHeader: authorizationHeader) { [weak self] pullError, pullProcessedChanges, pullTotalChanges, didChangeLocalData in
                guard let self else { return }

                let is404Error = pullError?.localizedDescription.contains("404") == true || (pullError as NSError?)?.code == 404
                if let pullError, !is404Error {
                    self.logger.error("CloudantSyncManager: Pull failed: \(pullError.localizedDescription)")
                    self.didFinishSync(error: pullError, request: request)
                    return
                }

                self.resolveConflicts()
                let maintenanceSummary = self.performMaintenanceIfNeeded(trigger: "post-pull")
                self.logReplicationProgress(direction: .pull, processedChanges: pullProcessedChanges, totalChanges: pullTotalChanges)
                let scheduleRefreshChanges = self.pendingRemoteScheduleRefreshChangesSnapshot()
                let watchChanges = self.pendingRemoteWatchChangesSnapshot()
                let shouldNotifyRemotePull = didChangeLocalData ||
                    !scheduleRefreshChanges.changedDocumentIDs.isEmpty ||
                    maintenanceSummary.changedScheduleContent
                let remoteChangeContext = self.scheduleRefreshContextForPendingRemoteChanges(
                    pendingChanges: scheduleRefreshChanges,
                    fallbackToFullResync: shouldNotifyRemotePull
                )
                let didPostRemoteChangeContext = shouldNotifyRemotePull && remoteChangeContext != nil

                if shouldNotifyRemotePull {
                    DispatchQueue.main.async {
                        CareKitStoreManager.shared.notifyRemoteCloudantPullChange(
                            "cloudant remote pull",
                            refreshContext: remoteChangeContext
                        )
                    }
                }
                if didPostRemoteChangeContext {
                    self.acknowledgePendingRemoteScheduleRefreshChanges(scheduleRefreshChanges)
                }
                if !watchChanges.isEmpty {
                    self.refreshWatchFromPendingRemoteChanges(reason: "remote pull")
                }

                self.performPushAfterRemoteFirstPull(
                    request,
                    authorizationHeader: authorizationHeader,
                    pullErrorWas404: is404Error,
                    remoteChangeContext: didPostRemoteChangeContext ? nil : remoteChangeContext,
                    remoteScheduleRefreshChanges: didPostRemoteChangeContext ? nil : scheduleRefreshChanges
                )
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start pull: \(error.localizedDescription)")
            didFinishSync(error: error, request: request)
        }
    }

    private func performPushAfterRemoteFirstPull(
        _ request: SyncRequest,
        authorizationHeader: String?,
        pullErrorWas404: Bool,
        remoteChangeContext: ScheduleRefreshContext?,
        remoteScheduleRefreshChanges: PendingRemoteWatchChanges.Snapshot?
    ) {
        do {
            try replicate(direction: .push, authorizationHeader: authorizationHeader) { [weak self] pushError, processedChanges, totalChanges, _ in
                guard let self else { return }

                if let pushError {
                    self.logger.error("CloudantSyncManager: Push failed after pull: \(pushError.localizedDescription)")
                    self.didFinishSync(error: pushError, request: request)
                    return
                }

                self.logReplicationProgress(direction: .push, processedChanges: processedChanges, totalChanges: totalChanges)
                if request.notifyWhenDone {
                    self.postSyncNotifications(remoteChangeContext: remoteChangeContext)
                    if remoteChangeContext != nil, let remoteScheduleRefreshChanges {
                        self.acknowledgePendingRemoteScheduleRefreshChanges(remoteScheduleRefreshChanges)
                    }
                }

                #if DEBUG
                if pullErrorWas404 {
                    self.logger.debug("CloudantSyncManager: Pull completed with 404 (deleted docs) - normal")
                } else {
                    self.logger.debug("CloudantSyncManager: Synced successfully")
                }
                #endif

                self.didFinishSync(error: nil, request: request)
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start push after pull: \(error.localizedDescription)")
            didFinishSync(error: error, request: request)
        }
    }

    private func performPull(_ request: SyncRequest, authorizationHeader: String?) {
        do {
            try replicate(direction: .pull, authorizationHeader: authorizationHeader) { [weak self] pullError, processedChanges, totalChanges, didChangeLocalData in
                guard let self = self else {
                    return
                }

                self.handlePullCompletion(
                    error: pullError,
                    processedChanges: processedChanges,
                    totalChanges: totalChanges,
                    didChangeLocalData: didChangeLocalData,
                    request: request
                )
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start pull: \(error.localizedDescription)")
            didFinishSync(error: error, request: request)
        }
    }

    private func handlePullCompletion(
        error: Error?,
        processedChanges: Int,
        totalChanges: Int,
        didChangeLocalData: Bool,
        request: SyncRequest
    ) {
        // 404 errors for deleted documents are cosmetic, not real failures
        let is404Error = error?.localizedDescription.contains("404") == true || (error as NSError?)?.code == 404
        var remoteChangeContext: ScheduleRefreshContext?
        var scheduleRefreshChangesToAcknowledge: PendingRemoteWatchChanges.Snapshot?

        if let error = error, !is404Error {
            logger.error("CloudantSyncManager: Pull failed: \(error.localizedDescription)")
        } else {
            resolveConflicts()
            let maintenanceSummary = performMaintenanceIfNeeded(trigger: "post-pull")
            logReplicationProgress(direction: .pull, processedChanges: processedChanges, totalChanges: totalChanges)
            let scheduleRefreshChanges = pendingRemoteScheduleRefreshChangesSnapshot()
            let watchChanges = pendingRemoteWatchChangesSnapshot()
            let shouldNotifyRemotePull = didChangeLocalData ||
                !scheduleRefreshChanges.changedDocumentIDs.isEmpty ||
                maintenanceSummary.changedScheduleContent
            remoteChangeContext = scheduleRefreshContextForPendingRemoteChanges(
                pendingChanges: scheduleRefreshChanges,
                fallbackToFullResync: shouldNotifyRemotePull
            )
            let didPostRemoteChangeContext = shouldNotifyRemotePull && remoteChangeContext != nil
            if shouldNotifyRemotePull {
                DispatchQueue.main.async {
                    CareKitStoreManager.shared.notifyRemoteCloudantPullChange(
                        "cloudant remote pull",
                        refreshContext: remoteChangeContext
                    )
                }
            }
            if didPostRemoteChangeContext {
                acknowledgePendingRemoteScheduleRefreshChanges(scheduleRefreshChanges)
            }
            if !watchChanges.isEmpty {
                refreshWatchFromPendingRemoteChanges(reason: "remote pull")
            }
            if didPostRemoteChangeContext {
                remoteChangeContext = nil
            } else if remoteChangeContext != nil {
                scheduleRefreshChangesToAcknowledge = scheduleRefreshChanges
            }

            #if DEBUG
            if is404Error {
                logger.debug("CloudantSyncManager: Pull completed with 404 (deleted docs) - normal")
            } else {
                logger.debug("CloudantSyncManager: Synced successfully")
            }
            #endif
        }

        if request.notifyWhenDone {
            postSyncNotifications(remoteChangeContext: remoteChangeContext)
            if let scheduleRefreshChangesToAcknowledge {
                acknowledgePendingRemoteScheduleRefreshChanges(scheduleRefreshChangesToAcknowledge)
            }
        }

        didFinishSync(error: is404Error ? nil : error, request: request)
    }

    private func postSyncNotifications(remoteChangeContext: ScheduleRefreshContext?) {
        DispatchQueue.main.async {
            if let remoteChangeContext {
                NotificationCenter.default.postScheduleRefresh(remoteChangeContext)
            }
            NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
        }
    }

    @discardableResult
    private func startChangesTracker() -> ChangesTrackerStartupResult {
        guard changesTracker == nil else {
            changesTracker?.start()
            return .started
        }

        guard let dataStore = try? cloudantStore?.datastoreManager.datastoreNamed(FileConstants.datastore) else {
            let reason = "Failed to get datastore for ChangesTracker"
            logger.error("CloudantSyncManager: \(reason)")
            return .failed(reason)
        }

        changesTracker = ChangesTracker(
            datastore: dataStore,
            remoteURL: Configuration.default.targetURL,
            remoteChangeHandler: { [weak self] changedDocumentIDs, deletedDocumentIDs, typedDeletions in
                self?.handleChangesFeedActivity(
                    changedDocumentIDs: changedDocumentIDs,
                    deletedDocumentIDs: deletedDocumentIDs,
                    typedDeletions: typedDeletions
                )
            }
        )
        changesTracker?.start()
        return .started
    }

    private func handleChangesFeedActivity(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions: [OTFWatchSyncDeletion]
    ) {
        let matchedDeletedDocumentIDs = cloudantStore?.deleteOutcomeDocuments(
            matchingDeletedDocumentIDs: deletedDocumentIDs
        ) ?? []
        let allDeletedDocumentIDs = Array(Set(deletedDocumentIDs).union(matchedDeletedDocumentIDs))
        let didApplyLocalCleanupDeletes = allDeletedDocumentIDs.count > Set(deletedDocumentIDs).count ||
            !matchedDeletedDocumentIDs.isEmpty

        recordPendingRemoteChanges(
            changedDocumentIDs: changedDocumentIDs,
            deletedDocumentIDs: allDeletedDocumentIDs,
            typedDeletions: typedDeletions
        )

        if !allDeletedDocumentIDs.isEmpty {
            let refreshContext = scheduleRefreshContextForDeletedOutcomeDocumentIDs(allDeletedDocumentIDs)
                ?? ScheduleRefreshContext(changeKind: .fullResync)
            let scheduleDeletionSnapshot = pendingRemoteScheduleRefreshChangesSnapshot(
                deletedDocumentIDs: allDeletedDocumentIDs
            )
            notifyChangesFeedOutcomeDeletion(refreshContext: refreshContext)
            acknowledgePendingRemoteScheduleRefreshChanges(scheduleDeletionSnapshot)
            pushRemoteOutcomeDeletionsToWatchIfPossible(
                allDeletedDocumentIDs,
                reason: "changes feed deletion"
            )
        }

        guard !changedDocumentIDs.isEmpty || !allDeletedDocumentIDs.isEmpty else {
            return
        }

        let syncOrder = CloudantSyncPolicy.remoteChangeFeedSyncOrder(
            hasPendingLocalChanges: hasPendingOfflineChanges || didApplyLocalCleanupDeletes
        )
        scheduleIncrementalSync(
            reason: "changes feed remote update",
            notifyWhenDone: true,
            debounce: 0.05,
            syncOrder: syncOrder
        )
    }

    private func notifyChangesFeedOutcomeDeletion(refreshContext: ScheduleRefreshContext) {
        DispatchQueue.main.async {
            CareKitStoreManager.shared.notifyRemoteOutcomeChange("changes feed deletion")
            NotificationCenter.default.postScheduleRefresh(refreshContext)
            NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
        }
    }

    private func recordPendingRemoteChanges(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions suppliedTypedDeletions: [OTFWatchSyncDeletion] = []
    ) {
        var typedDeletionsByDocumentID = [String: OTFWatchSyncDeletion]()
        for typedDeletion in remoteDeletionDescriptors(for: deletedDocumentIDs) {
            typedDeletionsByDocumentID[typedDeletion.documentID] = typedDeletion
        }
        for typedDeletion in suppliedTypedDeletions {
            typedDeletionsByDocumentID[typedDeletion.documentID] = typedDeletion
        }
        pendingRemoteWatchChanges.record(
            changedDocumentIDs: changedDocumentIDs,
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: Array(typedDeletionsByDocumentID.values)
        )
        pendingRemoteScheduleRefreshChanges.record(
            changedDocumentIDs: changedDocumentIDs,
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: Array(typedDeletionsByDocumentID.values)
        )
    }

    private func pendingRemoteWatchChangesSnapshot() -> PendingRemoteWatchChanges.Snapshot {
        pendingRemoteWatchChanges.snapshot()
    }

    private func acknowledgePendingRemoteWatchChanges(_ snapshot: PendingRemoteWatchChanges.Snapshot) {
        pendingRemoteWatchChanges.acknowledge(snapshot)
    }

    private func pendingRemoteScheduleRefreshChangesSnapshot() -> PendingRemoteWatchChanges.Snapshot {
        pendingRemoteScheduleRefreshChanges.snapshot()
    }

    private func pendingRemoteScheduleRefreshChangesSnapshot(
        deletedDocumentIDs: [String]
    ) -> PendingRemoteWatchChanges.Snapshot {
        pendingRemoteScheduleRefreshChanges.snapshot(deletedDocumentIDs: deletedDocumentIDs)
    }

    private func acknowledgePendingRemoteScheduleRefreshChanges(_ snapshot: PendingRemoteWatchChanges.Snapshot) {
        pendingRemoteScheduleRefreshChanges.acknowledge(snapshot)
    }

    private func discardPendingRemoteChanges() {
        pendingRemoteWatchChanges.discardAll()
        pendingRemoteScheduleRefreshChanges.discardAll()
    }

    /// Sends remote pull changes to the watch and keeps them pending until delivery succeeds.
    private func refreshWatchFromPendingRemoteChanges(reason: String) {
        let pendingChanges = pendingRemoteWatchChangesSnapshot()
        guard !pendingChanges.isEmpty else {
            return
        }

        if !refreshWatchIncrementallyFromPendingRemoteChanges(pendingChanges, reason: reason) {
            refreshWatchSnapshot(reason: reason) { [weak self] success in
                guard success else {
                    return
                }

                self?.acknowledgePendingRemoteWatchChanges(pendingChanges)
            }
        }
    }

    /// Resolves conflicting document revisions after a pull replication.
    private func resolveConflicts() {
        guard let dataStore = try? cloudantStore?.datastoreManager.datastoreNamed(FileConstants.datastore) else {
            logger.debug("CloudantSyncManager: Could not get datastore for conflict resolution")
            return
        }

        guard let conflictedIds = dataStore.getConflictedDocumentIds() as? [String],
              !conflictedIds.isEmpty else {
            if verboseLoggingEnabled {
                logger.info("CloudantSyncManager: No conflicts found")
            }
            return
        }

        logger.info("CloudantSyncManager: Resolving \(conflictedIds.count) conflicts")

        for docId in conflictedIds {
            do {
                try dataStore.resolveConflicts(forDocument: docId, resolver: conflictResolver)
                logger.info("CloudantSyncManager: Resolved conflicts for \(docId)")
            } catch {
                logger.error("CloudantSyncManager: Failed to resolve conflicts for \(docId): \(error)")
            }
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
        }
    }

    private func logReplicationProgress(direction: ReplicationDirection, processedChanges: Int, totalChanges: Int) {
        guard verboseLoggingEnabled || processedChanges > 0 || totalChanges > 0 else { return }
        logger.info(
            "CloudantSyncManager: \(direction.rawValue.capitalized) processed \(processedChanges)/\(totalChanges) changes"
        )
    }

    private func didFinishSync(error: Error?, request: SyncRequest) {
        let didSucceed = error == nil
        if didSucceed {
            UserDefaults.standard.set(Date(), forKey: DefaultsKeys.lastSuccessfulSyncDate)
        }
        SyncPerformanceTracker.shared.logSummary(context: "cloudant sync finished")
        DispatchQueue.main.async { [weak self] in
            request.completions.compactMap { $0 }.forEach { $0(error) }
            if didSucceed {
                _ = self?.retryPendingWatchLoginPublishIfPossible(reason: "cloudant sync finished")
            }
        }

        syncStateQueue.async { [weak self] in
            guard let self else { return }
            self.syncInFlight = false

            if let nextRequest = self.pendingSyncRequest {
                self.pendingSyncRequest = nil
                self.startOrQueueSync(nextRequest)
            }
        }
    }

    #if DEBUG
    /// Test seam for the pending watch-login retry state machine.
    func retryPendingWatchLoginPublishIfPossibleForTesting(
        reason: String,
        isLoggedIn: Bool,
        sessionStore: WatchAuthSessionStore,
        setWatchSyncReady: (Bool) -> Void,
        publish: (WatchAuthCommand, Bool) -> WatchAuthPublishResult
    ) -> WatchPendingLoginPublishOutcome {
        retryPendingWatchLoginPublishIfPossible(
            reason: reason,
            hasAuth: { isLoggedIn },
            sessionStore: sessionStore,
            setWatchSyncReady: setWatchSyncReady,
            publish: publish
        )
    }
    #endif

    /// Retries publishing the pending watch login after sync or WatchConnectivity state changes.
    ///
    /// The method intentionally requires a durable `updateApplicationContext` write before
    /// committing the pending session. This prevents the iPhone from marking watch sync as
    /// ready while the watch has not yet received a valid login context.
    @discardableResult
    func retryPendingWatchLoginPublishIfPossible(reason: String) -> WatchPendingLoginPublishOutcome {
        retryPendingWatchLoginPublishIfPossible(
            reason: reason,
            hasAuth: { TheraForgeKeychainService.shared.loadAuth() != nil },
            sessionStore: .shared,
            setWatchSyncReady: { CareKitStoreManager.shared.setWatchSyncReady($0) },
            publish: {
                WatchAuthCommandPublisher.shared.publish($0, cancelOutstandingUserInfoTransfers: $1)
            }
        )
    }

    /// Injectable implementation used by production and tests to keep retry behavior consistent.
    private func retryPendingWatchLoginPublishIfPossible(
        reason: String,
        hasAuth: () -> Bool = { TheraForgeKeychainService.shared.loadAuth() != nil },
        sessionStore: WatchAuthSessionStore = .shared,
        setWatchSyncReady: (Bool) -> Void = { CareKitStoreManager.shared.setWatchSyncReady($0) },
        publish: (WatchAuthCommand, Bool) -> WatchAuthPublishResult = {
            WatchAuthCommandPublisher.shared.publish($0, cancelOutstandingUserInfoTransfers: $1)
        }
    ) -> WatchPendingLoginPublishOutcome {
        guard hasAuth() else {
            return .skippedNoAuth
        }

        guard let command = sessionStore.pendingLoginCommand() else {
            return .skippedNoPendingLogin
        }

        switch publish(command, false) {
        case .storedInApplicationContext:
            switch sessionStore.commitPendingLoginSession(command) {
            case .accepted:
                setWatchSyncReady(true)
                logger.info("CloudantSyncManager: Published pending watch login after durable handoff")
                return .committed
            case .stale:
                setWatchSyncReady(false)
                return .stalePending
            }

        case .unavailable(let unavailableReason):
            setWatchSyncReady(false)
            return .unavailable(reason: unavailableReason)

        case .failed(let error):
            setWatchSyncReady(false)
            return .failed(message: error.localizedDescription)
        }
    }

    private func replicate(
        direction: ReplicationDirection,
        authorizationHeader: String?,
        completionBlock: @escaping ((Error?, Int, Int, Bool) -> Void)
    ) throws {
        let store = try StoreService.shared.currentStore(peer: peer)
        let datastoreManager = store.datastoreManager
        let factory = CDTReplicatorFactory(datastoreManager: datastoreManager)
        let configuration = Configuration.default

        let replication = createReplication(direction: direction, store: store, configuration: configuration)
        replication.add(TheraForgeHTTPInterceptor(authorizationHeader: authorizationHeader))

        let replicator = try factory.oneWay(replication)
        let dataStore = try datastoreManager.datastoreNamed(FileConstants.datastore)

        replicator.sessionConfigDelegate = TheraForgeNetwork.shared
        dataStore.sessionConfigDelegate = TheraForgeNetwork.shared

        executeReplication(
            direction: direction,
            dataStore: dataStore,
            replicator: replicator,
            configuration: configuration,
            completionBlock: completionBlock
        )
    }

    private func createReplication(direction: ReplicationDirection, store: OTFCloudantStore, configuration: Configuration) -> CDTAbstractReplication {
        switch direction {
        case .push:
            return CDTPushReplication(
                source: store.dataStore,
                target: configuration.targetURL,
                username: configuration.username,
                password: configuration.password
            )
        case .pull:
            return CDTPullReplication(
                source: configuration.targetURL,
                target: store.dataStore,
                username: configuration.username,
                password: configuration.password
            )
        }
    }

    private func executeReplication(
        direction: ReplicationDirection,
        dataStore: CDTDatastore,
        replicator: CDTReplicator,
        configuration: Configuration,
        completionBlock: @escaping ((Error?, Int, Int, Bool) -> Void)
    ) {
        let localFingerprintBeforePull = direction == .pull
            ? localDocumentFingerprint(in: dataStore)
            : Set<String>()
        switch direction {
        case .push:
            dataStore.push(
                to: configuration.targetURL,
                replicator: replicator,
                username: configuration.username,
                password: configuration.password
            ) { [weak self] error in
                if let error = error {
                    self?.logger.error("CloudantSyncManager: Push error: \(error.localizedDescription)")
                } else {
                    self?.logger.debug("CloudantSyncManager: Push completed")
                }
                completionBlock(error, replicator.changesProcessed, replicator.changesTotal, false)
            }

        case .pull:
            dataStore.pull(
                from: configuration.targetURL,
                replicator: replicator,
                username: configuration.username,
                password: configuration.password,
                completionHandler: { error in
                    let localFingerprintAfterPull = self.localDocumentFingerprint(in: dataStore)
                    completionBlock(
                        error,
                        replicator.changesProcessed,
                        replicator.changesTotal,
                        localFingerprintAfterPull != localFingerprintBeforePull
                    )
                }
            )
        }
    }

    private func localDocumentFingerprint(in dataStore: CDTDatastore) -> Set<String> {
        Set((dataStore.getAllDocuments() ?? []).map { revision in
            [
                revision.docId ?? "",
                revision.revId ?? "",
                revision.deleted ? "deleted" : "active"
            ].joined(separator: "|")
        })
    }

    /// Falls back to a full watch snapshot when incremental remote-change delivery is not possible.
    private func refreshWatchSnapshot(reason: String, completion: ((Bool) -> Void)? = nil) {
        guard shouldAttemptWatchSnapshotRefresh() else {
            logger.debug("CloudantSyncManager: Skipping watch snapshot refresh after \(reason); no paired watch session available")
            completion?(false)
            return
        }

        guard let cloudantStore else {
            logger.error("CloudantSyncManager: Watch snapshot refresh failed after \(reason); store unavailable")
            completion?(false)
            return
        }

        cloudantStore.synchronizeWatchAppUpdate { [weak self] result in
            switch result {
            case .success(let outcome):
                let delivered = outcome == .delivered
                self?.logger.debug("CloudantSyncManager: Watch snapshot refresh \(delivered ? "delivered" : "queued") after \(reason)")
                completion?(delivered)
            case .failure(let error):
                self?.logger.error("CloudantSyncManager: Watch snapshot refresh failed after \(reason): \(error.localizedDescription)")
                completion?(false)
            }
        }
    }

    /// Checks the minimum iPhone/watch state needed before attempting outbound watch sync.
    private func shouldAttemptWatchSnapshotRefresh() -> Bool {
        guard CareKitStoreManager.shared.isWatchSyncReadyForOutboundMessages() else {
            return false
        }
#if os(iOS)
        guard WCSession.isSupported() else {
            return false
        }
        let session = WCSession.default
        guard session.activationState == .activated else {
            return false
        }
        guard session.isPaired else {
            return false
        }
        guard session.isWatchAppInstalled else {
            return false
        }
        return true
#else
        return false
#endif
    }

}

extension CloudantSyncManager {
    @discardableResult
    func performMaintenanceIfNeeded(trigger: String) -> SyncMaintenanceSummary {
        guard let cloudantStore else {
            return .empty
        }

        return performMaintenanceIfNeeded(trigger: trigger, store: cloudantStore)
    }

    @discardableResult
    func performMaintenanceIfNeeded(
        trigger: String,
        store: OTFCloudantStore,
        defaults: UserDefaults = .standard,
        now: () -> Date = Date.init
    ) -> SyncMaintenanceSummary {
        let dataStore = store.dataStore
        let backfilledTaskDateMetadata = store.backfillTaskDateMetadataIfNeeded()
        if backfilledTaskDateMetadata > 0 {
            logger.info(
                "CloudantSyncManager: Backfilled \(backfilledTaskDateMetadata) task date metadata documents after \(trigger)"
            )
        }

        let prunedOutcomeDocuments = store.pruneStaleOutcomeDocuments()
        if prunedOutcomeDocuments > 0 {
            SyncPerformanceTracker.shared.recordOutcomeMaintenance(prunedOrMigrated: prunedOutcomeDocuments)
            logger.info(
                "CloudantSyncManager: Pruned \(prunedOutcomeDocuments) stale outcome documents after \(trigger)"
            )
        }

        let localMutationCount = defaults.integer(forKey: DefaultsKeys.localMutationCount)
        let lastCompactionDate = defaults.object(forKey: DefaultsKeys.lastCompactionDate) as? Date
        let elapsedSinceCompaction = lastCompactionDate.map { now().timeIntervalSince($0) } ?? .infinity
        let shouldCompact = localMutationCount >= 25 || elapsedSinceCompaction >= 60 * 60 * 12

        guard shouldCompact else {
            return SyncMaintenanceSummary(
                backfilledTaskDateMetadata: backfilledTaskDateMetadata,
                prunedOutcomeDocuments: prunedOutcomeDocuments
            )
        }

        let activeDocumentsBefore = dataStore.getAllDocuments()?.count ?? 0
        do {
            try dataStore.compact()
            defaults.set(now(), forKey: DefaultsKeys.lastCompactionDate)
            defaults.set(0, forKey: DefaultsKeys.localMutationCount)
            logger.info(
                "CloudantSyncManager: Compacted local datastore after \(trigger). Active docs: \(activeDocumentsBefore)"
            )
        } catch {
            logger.error("CloudantSyncManager: Failed to compact datastore after \(trigger): \(error.localizedDescription)")
        }

        return SyncMaintenanceSummary(
            backfilledTaskDateMetadata: backfilledTaskDateMetadata,
            prunedOutcomeDocuments: prunedOutcomeDocuments
        )
    }
}
// swiftlint:enable type_body_length

extension CloudantSyncManager {

    func recordPendingRemoteChangesForTesting(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions: [OTFWatchSyncDeletion] = []
    ) {
        recordPendingRemoteChanges(
            changedDocumentIDs: changedDocumentIDs,
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: typedDeletions
        )
    }

    func discardPendingRemoteChangesForTesting() {
        discardPendingRemoteChanges()
    }

    func pendingRemoteWatchChangeIDsForTesting() -> (changedDocumentIDs: [String], deletedDocumentIDs: [String]) {
        let snapshot = pendingRemoteWatchChangesSnapshot()
        return (
            changedDocumentIDs: snapshot.changedDocumentIDs,
            deletedDocumentIDs: snapshot.deletedDocumentIDs
        )
    }

    func pendingRemoteScheduleRefreshChangeIDsForTesting() -> (
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String]
    ) {
        let snapshot = pendingRemoteScheduleRefreshChangesSnapshot()
        return (
            changedDocumentIDs: snapshot.changedDocumentIDs,
            deletedDocumentIDs: snapshot.deletedDocumentIDs
        )
    }

    func consumeRemotePullScheduleRefreshForTesting(
        didChangeLocalData: Bool,
        changedScheduleContent: Bool
    ) -> (shouldNotifyRemotePull: Bool, refreshContext: ScheduleRefreshContext?) {
        let snapshot = pendingRemoteScheduleRefreshChangesSnapshot()
        let shouldNotifyRemotePull = didChangeLocalData ||
            !snapshot.changedDocumentIDs.isEmpty ||
            changedScheduleContent
        let refreshContext = scheduleRefreshContextForPendingRemoteChanges(
            pendingChanges: snapshot,
            fallbackToFullResync: shouldNotifyRemotePull
        )
        if refreshContext != nil {
            acknowledgePendingRemoteScheduleRefreshChanges(snapshot)
        }
        return (shouldNotifyRemotePull: shouldNotifyRemotePull, refreshContext: refreshContext)
    }

    func consumePendingRemoteScheduleRefreshDeletionForTesting(_ deletedDocumentIDs: [String]) {
        let snapshot = pendingRemoteScheduleRefreshChangesSnapshot(deletedDocumentIDs: deletedDocumentIDs)
        acknowledgePendingRemoteScheduleRefreshChanges(snapshot)
    }

    private func snapshotPendingRemoteChanges() -> (changedDocumentIDs: [String], deletedDocumentIDs: [String]) {
        let snapshot = pendingRemoteWatchChangesSnapshot()
        return (
            changedDocumentIDs: snapshot.changedDocumentIDs,
            deletedDocumentIDs: snapshot.deletedDocumentIDs
        )
    }

    func remoteDeletionDescriptors(for deletedDocumentIDs: [String]) -> [OTFWatchSyncDeletion] {
        remoteDeletionDescriptors(for: deletedDocumentIDs, using: cloudantStore)
    }

    func remoteDeletionDescriptors(
        for deletedDocumentIDs: [String],
        using store: OTFCloudantStore?
    ) -> [OTFWatchSyncDeletion] {
        deletedDocumentIDs.compactMap { remoteDeletionDescriptor(for: $0, using: store) }
    }

    private func remoteDeletionDescriptor(
        for deletedDocumentID: String,
        using store: OTFCloudantStore?
    ) -> OTFWatchSyncDeletion? {
        if let outcomeKey = outcomeLogicalKey(forCanonicalDocumentID: deletedDocumentID) {
            return OTFWatchSyncDeletion(
                documentID: deletedDocumentID,
                entityType: .outcome,
                taskUUID: outcomeKey.taskUUID,
                occurrenceIndex: outcomeKey.occurrenceIndex
            )
        }

        guard let revision = try? store?.dataStore.getDocumentWithId(deletedDocumentID),
              let body = revision.body as? [String: Any],
              body["entityType"] as? String == String(describing: OCKTask.self) else {
            return nil
        }

        return OTFWatchSyncDeletion(documentID: deletedDocumentID, entityType: .task)
    }

    private func scheduleRefreshContextForPendingRemoteChanges(hasRemoteChanges: Bool) -> ScheduleRefreshContext? {
        guard hasRemoteChanges else {
            return nil
        }

        return scheduleRefreshContextForPendingRemoteChanges(
            pendingChanges: pendingRemoteScheduleRefreshChangesSnapshot(),
            fallbackToFullResync: hasRemoteChanges
        )
    }

    private func scheduleRefreshContextForPendingRemoteChanges(
        pendingChanges: PendingRemoteWatchChanges.Snapshot,
        fallbackToFullResync: Bool
    ) -> ScheduleRefreshContext? {
        var affectedDates = [Date]()
        for documentID in pendingChanges.changedDocumentIDs {
            guard let revision = try? cloudantStore?.dataStore.getDocumentWithId(documentID),
                  let body = revision.body as? [String: Any],
                  let entityType = body["entityType"] as? String else {
                return fallbackToFullResync ? ScheduleRefreshContext(changeKind: .fullResync) : nil
            }

            if entityType == String(describing: OCKOutcome.self),
               let outcome = try? revision.data(as: OCKOutcome.self) {
                affectedDates.append(outcome.effectiveDate)
            } else {
                return fallbackToFullResync ? ScheduleRefreshContext(changeKind: .fullResync) : nil
            }
        }

        if !pendingChanges.deletedDocumentIDs.isEmpty {
            guard let deletedContext = scheduleRefreshContextForDeletedOutcomeDocumentIDs(pendingChanges.deletedDocumentIDs) else {
                return fallbackToFullResync ? ScheduleRefreshContext(changeKind: .fullResync) : nil
            }
            affectedDates.append(contentsOf: deletedContext.affectedDates)
        }

        guard !affectedDates.isEmpty else {
            return fallbackToFullResync ? ScheduleRefreshContext(changeKind: .fullResync) : nil
        }

        return ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: affectedDates)
    }

    private func scheduleRefreshContextForDeletedOutcomeDocumentIDs(_ documentIDs: [String]) -> ScheduleRefreshContext? {
        let affectedDates = documentIDs.compactMap { affectedDateForDeletedOutcomeDocumentID($0) }
        guard !affectedDates.isEmpty else {
            return nil
        }

        return ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: affectedDates)
    }

    private func affectedDateForDeletedOutcomeDocumentID(_ documentID: String) -> Date? {
        guard let outcomeKey = outcomeLogicalKey(forCanonicalDocumentID: documentID),
              let task = task(withUUID: outcomeKey.taskUUID),
              let event = task.schedule.event(forOccurrenceIndex: outcomeKey.occurrenceIndex) else {
            return nil
        }

        return event.start
    }

    private func outcomeLogicalKey(forCanonicalDocumentID documentID: String) -> (taskUUID: UUID, occurrenceIndex: Int)? {
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

    private func task(withUUID uuid: UUID) -> OCKTask? {
        let documents = cloudantStore?.dataStore.getAllDocuments() ?? []
        for revision in documents {
            guard let body = revision.body as? [String: Any],
                  body["entityType"] as? String == String(describing: OCKTask.self),
                  let task = try? revision.data(as: OCKTask.self),
                  task.uuid == uuid else {
                continue
            }

            return task
        }

        return nil
    }

    /// Builds and sends a compact payload for remote Cloudant changes that affect the watch.
    private func refreshWatchIncrementallyFromPendingRemoteChanges(reason: String) -> Bool {
        refreshWatchIncrementallyFromPendingRemoteChanges(
            pendingRemoteWatchChangesSnapshot(),
            reason: reason
        )
    }

    private func refreshWatchIncrementallyFromPendingRemoteChanges(
        _ pendingChanges: PendingRemoteWatchChanges.Snapshot,
        reason: String
    ) -> Bool {
        guard shouldAttemptWatchSnapshotRefresh() else {
            return false
        }

        guard !pendingChanges.isEmpty else {
            return false
        }

        do {
            let payload = try makeWatchPayloadForRemoteChanges(
                changedDocumentIDs: pendingChanges.changedDocumentIDs,
                deletedDocumentIDs: pendingChanges.deletedDocumentIDs,
                typedDeletions: pendingChanges.typedDeletions
            )
            guard !payload.isEmpty else {
                return false
            }

            peer.pushIncrementalPayloadWithDeliveryOutcome(payload) { [weak self] result in
                switch result {
                case .success(.delivered):
                    self?.acknowledgePendingRemoteWatchChanges(pendingChanges)
                    SyncPerformanceTracker.shared.recordWatchPayload(
                        direction: "remote_pull_sent",
                        tasks: payload.tasks.count,
                        outcomes: payload.outcomes.count,
                        deletions: payload.deletedDocumentIDs.count
                    )
                    self?.logger.debug("CloudantSyncManager: Incremental watch refresh delivered after \(reason)")
                case .success(.queued):
                    self?.logger.debug("CloudantSyncManager: Incremental watch refresh queued after \(reason); pending changes retained")
                case .failure(let error):
                    self?.logger.error("CloudantSyncManager: Incremental watch refresh failed after \(reason): \(error.localizedDescription)")
                }
            }
            return true
        } catch {
            logger.error("CloudantSyncManager: Failed to build incremental watch refresh after \(reason): \(error.localizedDescription)")
            return false
        }
    }

    /// Sends remote outcome deletions immediately so the watch does not retain stale outcomes.
    private func pushRemoteOutcomeDeletionsToWatchIfPossible(_ documentIDs: [String], reason: String) {
        guard shouldAttemptWatchSnapshotRefresh() else {
            return
        }

        let outcomeDeletionDocumentIDs = Array(
            Set(documentIDs.filter { outcomeLogicalKey(forCanonicalDocumentID: $0) != nil })
        ).sorted()
        guard !outcomeDeletionDocumentIDs.isEmpty else {
            return
        }

        let typedDeletions = remoteDeletionDescriptors(for: outcomeDeletionDocumentIDs)
        let typedDeletionDocumentIDs = Set(typedDeletions.map(\.documentID))
        let legacyDeletedDocumentIDs = outcomeDeletionDocumentIDs.filter {
            !typedDeletionDocumentIDs.contains($0)
        }
        let payload = OTFWatchSyncPayload(
            deletions: typedDeletions,
            deletedDocumentIDs: legacyDeletedDocumentIDs
        )
        let pendingDeletionSnapshot = pendingRemoteWatchChanges.snapshot(deletedDocumentIDs: outcomeDeletionDocumentIDs)
        peer.pushIncrementalPayloadWithDeliveryOutcome(payload) { [weak self] result in
            switch result {
            case .success(.delivered):
                self?.acknowledgePendingRemoteWatchChanges(pendingDeletionSnapshot)
                SyncPerformanceTracker.shared.recordWatchPayload(
                    direction: "remote_delete_sent",
                    tasks: 0,
                    outcomes: 0,
                    deletions: payload.deletedDocumentIDs.count
                )
                self?.logger.debug("CloudantSyncManager: Immediate watch deletion refresh delivered after \(reason)")
            case .success(.queued):
                self?.logger.debug("CloudantSyncManager: Immediate watch deletion refresh queued after \(reason)")
            case .failure(let error):
                self?.logger.error("CloudantSyncManager: Immediate watch deletion refresh failed after \(reason): \(error.localizedDescription)")
            }
        }
    }

    /// Converts changed Cloudant document IDs into the authenticated watch sync payload format.
    func makeWatchPayloadForRemoteChanges(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions: [OTFWatchSyncDeletion] = []
    ) throws -> OTFWatchSyncPayload {
        try makeWatchPayloadForRemoteChanges(
            changedDocumentIDs: changedDocumentIDs,
            deletedDocumentIDs: deletedDocumentIDs,
            typedDeletions: typedDeletions,
            using: cloudantStore
        )
    }

    func makeWatchPayloadForRemoteChanges(
        changedDocumentIDs: [String],
        deletedDocumentIDs: [String],
        typedDeletions: [OTFWatchSyncDeletion] = [],
        using store: OTFCloudantStore?
    ) throws -> OTFWatchSyncPayload {
        let typedDeletionDocumentIDs = Set(typedDeletions.map(\.documentID))
        let legacyDeletedDocumentIDs = deletedDocumentIDs.filter {
            !typedDeletionDocumentIDs.contains($0)
        }
        guard let store else {
            return OTFWatchSyncPayload(
                deletions: typedDeletions,
                deletedDocumentIDs: legacyDeletedDocumentIDs
            )
        }

        var tasks = [OCKTask]()
        var outcomes = [OCKOutcome]()

        for documentID in changedDocumentIDs {
            guard let revision = try? store.dataStore.getDocumentWithId(documentID),
                  let body = revision.body as? [String: Any],
                  let entityType = body["entityType"] as? String else {
                continue
            }

            if entityType == String(describing: OCKTask.self),
               let task = try revision.data(as: OCKTask.self) {
                tasks.append(task)
            } else if entityType == String(describing: OCKOutcome.self),
                      let outcome = try revision.data(as: OCKOutcome.self) {
                outcomes.append(outcome)
            }
        }

        return try store.makeIncrementalSyncPayload(
            tasks: tasks,
            outcomes: outcomes,
            deletions: typedDeletions,
            deletedDocumentIDs: legacyDeletedDocumentIDs
        )
    }
}
