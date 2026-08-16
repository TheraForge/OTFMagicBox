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

import OTFCloudantStore
import WatchConnectivity
import WatchKit
import OTFCareKit
import OTFCareKitStore
import Combine
import OTFUtilities

class OCKStoreManager: NSObject {
    static let shared = OCKStoreManager()

    let peer = OTFWatchConnectivityPeer()
    let coordinator: OCKStoreCoordinator
    let synchronizedStoreManager: OCKSynchronizedStoreManager

    private(set) var cloudantStore: OTFCloudantStore?
    private(set) var session: SessionManager?

    private var storeNotificationCancellable: AnyCancellable?
    private let logger = OTFLogger.logger()
    private var suppressOutgoingSync = 0

    override private init() {
        let coordinator = OCKStoreCoordinator()
        self.coordinator = coordinator
        self.synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        super.init()

        peer.outboundMessageContextProvider = {
            WatchAuthSessionStore.shared.currentContext()
        }

        do {
            let store = try WatchStoreService.shared.currentStore(peer: peer)
            self.cloudantStore = store

            coordinator.attach(store: store)
            self.session = SessionManager(peer: peer, store: store)

            peer.automaticallySynchronizes = false

            logger.info("Successfully created OTFCloudantStore for Watch")

            storeNotificationCancellable = synchronizedStoreManager
                .notificationPublisher
                .sink { [weak self] notification in
                    self?.handleStoreNotification(notification)
                }
        } catch {
            logger.info("Failed to create OTFCloudantStore for Watch: \(error.localizedDescription)")
            self.cloudantStore = nil
            self.session = nil
        }
    }

    var hasValidStore: Bool {
        cloudantStore != nil
    }

    func beginApplyingRemoteWatchChanges() {
        suppressOutgoingSync += 1
    }

    func endApplyingRemoteWatchChanges() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.suppressOutgoingSync = max(0, self.suppressOutgoingSync - 1)
        }
    }

    func notifyRemoteOutcomeChange(_ reason: String) {
        guard let cloudantStore else {
            logger.error("OCKStoreManager: Cannot notify remote outcome change without a store")
            return
        }

        synchronizedStoreManager.outcomeStore(cloudantStore, didEncounterUnknownChange: reason)
    }

    func wipe() throws {
        guard let cloudantStore else {
            logger.debug("wipe() called but cloudantStore is nil")
            return
        }

        logger.info("Deleting local_db datastore")
        try cloudantStore.datastoreManager.deleteDatastoreNamed("local_db")
    }

    /// Converts local watch store mutations into authenticated incremental payloads for iPhone.
    private func handleStoreNotification(_ notification: OCKStoreNotification) {
        guard suppressOutgoingSync == 0, let cloudantStore else {
            return
        }

        do {
            switch notification {
            case let taskNotification as OCKTaskNotification:
                let deletions: [OTFWatchSyncDeletion]
                if taskNotification.category == .delete {
                    if let task = taskNotification.task as? OCKTask {
                        deletions = WatchStoreDeletionDescriptorBuilder.taskDeletionDescriptors(for: task)
                    } else {
                        deletions = [
                            OTFWatchSyncDeletion(
                                documentID: WatchStoreDeletionDescriptorBuilder.documentID(
                                    for: taskNotification.task
                                ),
                                entityType: .task
                            )
                        ]
                    }
                } else {
                    deletions = []
                }
                let payload = try cloudantStore.makeIncrementalSyncPayload(
                    tasks: taskNotification.category == .delete ? [] : [taskNotification.task as? OCKTask].compactMap { $0 },
                    deletions: deletions
                )
                pushPayload(payload)

            case let outcomeNotification as OCKOutcomeNotification:
                let deletions: [OTFWatchSyncDeletion]
                if outcomeNotification.category == .delete {
                    if let outcome = outcomeNotification.outcome as? OCKOutcome {
                        deletions = WatchStoreDeletionDescriptorBuilder.outcomeDeletionDescriptors(
                            for: outcome,
                            documentIDs: deletedDocumentIDs(for: outcome)
                        )
                    } else {
                        deletions = [
                            OTFWatchSyncDeletion(
                                documentID: WatchStoreDeletionDescriptorBuilder.documentID(
                                    for: outcomeNotification.outcome
                                ),
                                entityType: .outcome
                            )
                        ]
                    }
                } else {
                    deletions = []
                }
                let payload = try cloudantStore.makeIncrementalSyncPayload(
                    outcomes: outcomeNotification.category == .delete ? [] : [outcomeNotification.outcome as? OCKOutcome].compactMap { $0 },
                    deletions: deletions
                )
                pushPayload(payload)

            default:
                break
            }
        } catch {
            logger.error("OCKStoreManager: Failed to create incremental payload: \(error.localizedDescription)")
        }
    }

    /// Sends a watch-originated payload immediately when possible, or lets the peer queue it.
    private func pushPayload(_ payload: OTFWatchSyncPayload) {
        guard !payload.isEmpty else {
            return
        }

        peer.pushIncrementalPayloadWithDeliveryOutcome(payload) { [weak self] result in
            switch result {
            case .success(.delivered):
                SyncPerformanceTracker.shared.recordWatchPayload(
                    direction: "watch_sent",
                    tasks: payload.tasks.count,
                    outcomes: payload.outcomes.count,
                    deletions: payload.deletedDocumentIDs.count
                )
            case .success(.queued):
                self?.logger.debug("OCKStoreManager: Incremental iPhone sync queued")
            case .failure(let error):
                self?.logger.error("OCKStoreManager: Incremental iPhone sync failed: \(error.localizedDescription)")
            }
        }
    }

    private func deletedDocumentIDs(for outcome: OCKOutcome) -> [String] {
        cloudantStore?.outcomeDeletionDocumentIDs(for: outcome) ?? [
            WatchStoreDeletionDescriptorBuilder.documentID(for: outcome)
        ]
    }
}
