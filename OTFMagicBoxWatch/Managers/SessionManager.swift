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
import OTFCareKitStore
import OTFCareKit
import OTFUtilities

class SessionManager: NSObject, WCSessionDelegate {

    let peer: OTFWatchConnectivityPeer
    let store: OTFCloudantStore

    @Published var tasks = [OCKAnyTask]()

    private let logger = OTFLogger.logger()

    init(peer: OTFWatchConnectivityPeer, store: OTFCloudantStore) {
        self.peer = peer
        self.store = store
        super.init()
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        logger.info("WCSession activation did complete with state: \(activationState.rawValue)")

        if let error {
            logger.info("WCSession activation error: \(error.localizedDescription)")
        }

        switch activationState {
        case .activated:
            logger.info("WCSession activated successfully")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [store, logger] in
                OCKStoreManager.shared.beginApplyingRemoteWatchChanges()
                store.synchronize { error in
                    if let error {
                        logger.info("Store synchronization error: \(error.localizedDescription)")
                    } else {
                        logger.info("Store synchronized successfully")
                    }
                    DispatchQueue.main.async {
                        OCKStoreManager.shared.notifyRemoteOutcomeChange("iphone activation sync")
                        NotificationCenter.default.postScheduleRefresh(
                            ScheduleRefreshContext(changeKind: .fullResync)
                        )
                        NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                        OCKStoreManager.shared.endApplyingRemoteWatchChanges()
                    }
                }
            }

        case .inactive:
            logger.info("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")

        case .notActivated:
            logger.info("Unexpected .notActivated state received after trying to activate the WCSession")

        @unknown default:
            logger.info("Unexpected WCSession state received after trying to activate")
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncomingMessage(userInfo, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncomingMessage(applicationContext, replyHandler: nil)
    }

    /// Routes inbound iPhone messages through auth validation before applying store changes.
    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {

        logger.debug("Did receive message from MOBILE APP: \(message)")

        switch WatchIncomingMessageRoute(message: message) {
        case .authCommand(let command):
            handleAuthCommand(command, replyHandler: replyHandler)

        case .incrementalRevisionPush(let payload):
            prepareForPhoneAuthContext(in: message, replyHandler: replyHandler) { [weak self] in
                self?.applyIncrementalSyncPayload(payload, replyHandler: replyHandler)
            }

        case .invalidIncrementalRevisionPush:
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Invalid incremental sync payload"])

        case .databaseSynced:
            prepareForPhoneAuthContext(in: message, replyHandler: replyHandler) { [weak self] in
                self?.synchronizeAfterDatabaseSynced(replyHandler: replyHandler)
            }

        case .liveHeartRateStart:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .healthSensorsLiveHeartRateStart, object: nil)
            }
            replyHandler?(["received": true])

        case .legacyLogout:
            handleLegacyLogout(replyHandler: replyHandler)

        case .peerFallback:
            guard let replyHandler else { return }

            prepareForPhoneAuthContext(in: message, replyHandler: replyHandler) { [weak self] in
                guard let self else { return }
                self.peer.reply(to: message, store: self.store, sendReply: replyHandler)
            }
        }
    }

    /// Applies authenticated incremental phone changes to the watch-local store.
    private func applyIncrementalSyncPayload(
        _ payload: OTFWatchSyncPayload,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        OCKStoreManager.shared.beginApplyingRemoteWatchChanges()
        do {
            let result = try store.applyIncrementalSync(payload: payload)
            let didApplyChanges = result.tasks > 0 || result.outcomes > 0 || result.deletions > 0
            SyncPerformanceTracker.shared.recordWatchPayload(
                direction: "watch_received",
                tasks: result.tasks,
                outcomes: result.outcomes,
                deletions: result.deletions
            )
            DispatchQueue.main.async {
                if result.outcomes > 0 || result.deletions > 0 {
                    OCKStoreManager.shared.notifyRemoteOutcomeChange("iphone incremental import")
                }
                if didApplyChanges {
                    if let scheduleRefreshContext = WatchSyncScheduleRefreshContextResolver.context(
                        for: result,
                        payload: payload,
                        store: self.store
                    ) {
                        NotificationCenter.default.postScheduleRefresh(scheduleRefreshContext)
                    }
                    NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                }
                OCKStoreManager.shared.endApplyingRemoteWatchChanges()
            }
            replyHandler?([
                "received": true,
                OTFWatchConnectivityMessageKey.revisionPushResult: [
                    "tasks": result.tasks,
                    "outcomes": result.outcomes,
                    "deletions": result.deletions,
                    "skipped": result.skipped,
                    "skippedDeletions": result.skippedDeletions
                ]
            ])
        } catch {
            OCKStoreManager.shared.endApplyingRemoteWatchChanges()
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: error.localizedDescription])
        }
    }

    private func synchronizeAfterDatabaseSynced(replyHandler: (([String: Any]) -> Void)?) {
        OCKStoreManager.shared.beginApplyingRemoteWatchChanges()
        store.synchronize { [logger] error in
            if let error {
                logger.info("Store synchronization error after database synced message: \(error.localizedDescription)")
            } else {
                logger.info("Store synchronized successfully after database synced message")
            }
            DispatchQueue.main.async {
                OCKStoreManager.shared.notifyRemoteOutcomeChange("iphone full sync")
                NotificationCenter.default.postScheduleRefresh(
                    ScheduleRefreshContext(changeKind: .fullResync)
                )
                NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                OCKStoreManager.shared.endApplyingRemoteWatchChanges()
                replyHandler?(["received": true])
            }
        }
    }

    private func handleLegacyLogout(replyHandler: (([String: Any]) -> Void)?) {
        logger.info("Received userNotLoggedIn message; deleting local records")
        guard WatchAuthSessionStore.shared.shouldAcceptLegacyLogout() else {
            replyHandler?(["received": true, "staleAuthCommand": true])
            return
        }

        deleteLocalRecordsForAuthTransition { [weak self] error in
            guard let self else { return }
            guard self.replyIfAuthTransitionWipeFailed(error, replyHandler: replyHandler) == false else {
                return
            }
            self.postLoggedOut(replyHandler: replyHandler)
        }
    }

    private func handleAuthCommand(_ command: WatchAuthCommand, replyHandler: (([String: Any]) -> Void)?) {
        switch WatchAuthSessionStore.shared.transitionResult(for: command) {
        case .stale:
            replyHandler?(["received": true, "staleAuthCommand": true])

        case .accepted(let needsWipe):
            guard needsWipe else {
                commitAuthCommandAndContinue(command, replyHandler: replyHandler)
                return
            }

            logger.info("Watch auth session changed; deleting local records")
            deleteLocalRecordsForAuthTransition { [weak self] error in
                guard let self else { return }
                guard self.replyIfAuthTransitionWipeFailed(error, replyHandler: replyHandler) == false else {
                    return
                }
                self.commitAuthCommandAndContinue(command, replyHandler: replyHandler)
            }
        }
    }

    private func commitAuthCommandAndContinue(
        _ command: WatchAuthCommand,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        switch WatchAuthSessionStore.shared.commit(command) {
        case .stale:
            replyHandler?(["received": true, "staleAuthCommand": true])

        case .accepted:
            if command.kind == .loginReady {
                synchronizeAfterLoginReady(replyHandler: replyHandler)
            } else {
                postLoggedOut(replyHandler: replyHandler)
            }
        }
    }

    /// Clears local watch records when a new phone auth session replaces the previous one.
    private func deleteLocalRecordsForAuthTransition(completion: @escaping (String?) -> Void) {
        OCKStoreManager.shared.beginApplyingRemoteWatchChanges()
        store.deleteRecords { [logger] error in
            if let error {
                logger.info("Watch auth local record delete failed: \(error)")
            }
            OCKStoreManager.shared.endApplyingRemoteWatchChanges()
            completion(error)
        }
    }

    private func replyIfAuthTransitionWipeFailed(
        _ error: String?,
        replyHandler: (([String: Any]) -> Void)?
    ) -> Bool {
        guard let error else {
            return false
        }

        replyHandler?([
            OTFWatchConnectivityMessageKey.revisionError: "Watch auth local wipe failed: \(error)"
        ])
        return true
    }

    /// Pulls the phone-prepared Cloudant data after accepting a durable loginReady command.
    private func synchronizeAfterLoginReady(replyHandler: (([String: Any]) -> Void)?) {
        OCKStoreManager.shared.beginApplyingRemoteWatchChanges()
        store.synchronize { [logger] error in
            if let error {
                logger.info("Store synchronization error after loginReady: \(error.localizedDescription)")
            } else {
                logger.info("Store synchronized successfully after loginReady")
            }
            DispatchQueue.main.async {
                OCKStoreManager.shared.notifyRemoteOutcomeChange("iphone loginReady sync")
                NotificationCenter.default.postScheduleRefresh(
                    ScheduleRefreshContext(changeKind: .fullResync)
                )
                NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                OCKStoreManager.shared.endApplyingRemoteWatchChanges()
                replyHandler?(["received": true])
            }
        }
    }

    private func postLoggedOut(replyHandler: (([String: Any]) -> Void)?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userLoggedOut, object: nil)
            replyHandler?(["received": true])
        }
    }

    /// Validates auth context carried by phone-originated sync payloads before applying them.
    private func prepareForPhoneAuthContext(
        in message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        apply: @escaping () -> Void
    ) {
        switch WatchAuthSessionStore.shared.incomingPhoneAuthResult(for: message) {
        case .rejected(let error):
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: error])

        case .accepted(let context, let needsWipe):
            guard needsWipe else {
                commitIncomingPhoneContextAndApply(context, replyHandler: replyHandler, apply: apply)
                return
            }

            logger.info("Phone auth session changed before sync payload; deleting local records")
            deleteLocalRecordsForAuthTransition { [weak self] error in
                guard let self else { return }
                guard self.replyIfAuthTransitionWipeFailed(error, replyHandler: replyHandler) == false else {
                    return
                }

                self.commitIncomingPhoneContextAndApply(context, replyHandler: replyHandler, apply: apply)
            }
        }
    }

    /// Commits a validated phone auth context, then applies the queued sync operation.
    private func commitIncomingPhoneContextAndApply(
        _ context: OTFWatchAuthContext,
        replyHandler: (([String: Any]) -> Void)?,
        apply: () -> Void
    ) {
        switch WatchAuthSessionStore.shared.commitIncomingPhoneContext(context) {
        case .stale:
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Stale phone auth session"])
        case .accepted:
            apply()
        }
    }

}
