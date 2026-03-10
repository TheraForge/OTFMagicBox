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
import OTFCloudantStore
import OTFCloudClientAPI
import OTFCDTDatastore
import OTFUtilities

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

// MARK: - CloudantSyncManager

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
class CloudantSyncManager {

    private enum FileConstants {
        static let datastore = "local_db"
    }

    // MARK: - Singleton

    static let shared = CloudantSyncManager()

    // MARK: - Public Properties

    var cloudantStore: OTFCloudantStore?
    let peer = OTFWatchConnectivityPeer()

    var storeManager: OCKSynchronizedStoreManager {
        CareKitStoreManager.shared.synchronizedStoreManager
    }

    // MARK: - Private Properties

    private var changesTracker: ChangesTracker?
    private let conflictResolver = OutcomeConflictResolver()
    private let logger = OTFLogger.logger()

    // MARK: - Initialization

    private init() {
        resetLocalDatabaseIfSafe()
        cloudantStore = try? StoreService.shared.currentStore(peer: peer)
        cloudantStore?.ensureClientSideIndexes()
        logger.info("CloudantSyncManager: Initialized with indexes")
    }
    
    /// Resets local database only if safe (online AND no pending offline changes).
    /// This prevents bloat while protecting offline edits from accidental deletion.
    private func resetLocalDatabaseIfSafe() {
        let hasPendingChanges = UserDefaults.standard.bool(forKey: Constants.Storage.kPendingOfflineChanges)

        guard NetworkHelper.isImmediatelyAvailable() else {
            logger.info("CloudantSyncManager: Preserving local data (offline)")
            return
        }
        
        guard !hasPendingChanges else {
            logger.info("CloudantSyncManager: Preserving local data (pending offline changes)")
            return
        }
        
        do {
            let store = try StoreService.shared.currentStore(peer: peer)
            try store.datastoreManager.deleteDatastoreNamed(FileConstants.datastore)
            logger.info("CloudantSyncManager: Local database refreshed (online, no pending changes)")
        } catch {
            logger.error("CloudantSyncManager: Failed to refresh database: \(error)")
        }
    }
    
    /// Marks that there are pending offline changes that need to be pushed.
    /// Called when local changes occur while offline.
    func markPendingOfflineChanges() {
        UserDefaults.standard.set(true, forKey: Constants.Storage.kPendingOfflineChanges)
    }
    
    /// Clears the pending offline changes flag after successful push.
    private func clearPendingOfflineChanges() {
        UserDefaults.standard.set(false, forKey: Constants.Storage.kPendingOfflineChanges)
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
        guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
            logger.error("CloudantSyncManager: Missing credentials")
            completion?(ForgeError.missingCredential)
            return
        }

        if auth.isValid() {
            startSync(notifyWhenDone: notifyWhenDone, completion: completion)
        } else {
            refreshTokenAndSync(notifyWhenDone: notifyWhenDone, completion: completion)
        }
    }

    // MARK: - Private Methods
    
    private func refreshTokenAndSync(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        OTFTheraforgeNetwork.shared.refreshToken { [weak self] result in
            switch result {
            case .success:
                self?.startSync(notifyWhenDone: notifyWhenDone, completion: completion)
            case .failure(let error):
                self?.logger.error("CloudantSyncManager: Token refresh failed: \(error.localizedDescription)")
                completion?(error)
            }
        }
    }

    private func startSync(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        startChangesTracker()
        changesTracker?.performDeletionSweep { [weak self] in
            self?.performPushThenPull(notifyWhenDone: notifyWhenDone, completion: completion)
        }
    }

    private func performPushThenPull(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        do {
            try replicate(direction: .push) { [weak self] pushError in
                guard let self = self else {
                    completion?(pushError)
                    return
                }

                if let error = pushError {
                    self.logger.error("CloudantSyncManager: Push failed: \(error.localizedDescription)")
                    self.didFinishSync(error: error, completion: completion)
                    return
                }

                self.clearPendingOfflineChanges()
                self.performPull(notifyWhenDone: notifyWhenDone, completion: completion)
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start push: \(error.localizedDescription)")
            didFinishSync(error: error, completion: completion)
        }
    }

    private func performPull(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        do {
            try replicate(direction: .pull) { [weak self] pullError in
                guard let self = self else {
                    completion?(pullError)
                    return
                }

                self.handlePullCompletion(
                    error: pullError,
                    notifyWhenDone: notifyWhenDone,
                    completion: completion
                )
            }
        } catch {
            logger.error("CloudantSyncManager: Failed to start pull: \(error.localizedDescription)")
            didFinishSync(error: error, completion: completion)
        }
    }

    private func handlePullCompletion(error: Error?, notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        // 404 errors for deleted documents are cosmetic, not real failures
        let is404Error = error?.localizedDescription.contains("404") == true || (error as NSError?)?.code == 404

        if let error = error, !is404Error {
            logger.error("CloudantSyncManager: Pull failed: \(error.localizedDescription)")
        } else {
            resolveConflicts()

            #if DEBUG
            if is404Error {
                logger.info("CloudantSyncManager: Pull completed with 404 (deleted docs) - normal")
            } else {
                logger.info("CloudantSyncManager: Synced successfully")
            }
            #endif
        }

        if notifyWhenDone {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
            }
        }

        didFinishSync(error: is404Error ? nil : error, completion: completion)
    }

    private func startChangesTracker() {
        guard changesTracker == nil else {
            changesTracker?.start()
            return
        }

        guard let dataStore = try? cloudantStore?.datastoreManager.datastoreNamed(FileConstants.datastore) else {
            logger.error("CloudantSyncManager: Failed to get datastore for ChangesTracker")
            return
        }

        changesTracker = ChangesTracker(datastore: dataStore, remoteURL: Configuration.default.targetURL)
        changesTracker?.start()
    }

    /// Resolves conflicting document revisions after a pull replication.
    private func resolveConflicts() {
        guard let dataStore = try? cloudantStore?.datastoreManager.datastoreNamed(FileConstants.datastore) else {
            logger.info("CloudantSyncManager: Could not get datastore for conflict resolution")
            return
        }

        guard let conflictedIds = dataStore.getConflictedDocumentIds() as? [String],
              !conflictedIds.isEmpty else {
            logger.info("CloudantSyncManager: No conflicts found")
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

    private func didFinishSync(error: Error?, completion: ((Error?) -> Void)?) {
        DispatchQueue.main.async {
            completion?(error)
        }
    }

    private func replicate(direction: ReplicationDirection, completionBlock: @escaping ((Error?) -> Void)) throws {
        let store = try StoreService.shared.currentStore(peer: peer)
        let datastoreManager = store.datastoreManager
        let factory = CDTReplicatorFactory(datastoreManager: datastoreManager)
        let configuration = Configuration.default

        let replication = createReplication(direction: direction, store: store, configuration: configuration)
        replication.add(TheraForgeHTTPInterceptor())

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
        completionBlock: @escaping ((Error?) -> Void)
    ) {
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
                    self?.logger.info("CloudantSyncManager: Push completed")
                }
                completionBlock(error)
            }

        case .pull:
            dataStore.pull(
                from: configuration.targetURL,
                replicator: replicator,
                username: configuration.username,
                password: configuration.password,
                completionHandler: completionBlock
            )
        }
    }
}
