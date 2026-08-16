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
import OTFUtilities
import OTFCloudClientAPI
import OTFCloudantStore
import OTFCareKitStore
import WatchConnectivity

class SessionManager: NSObject, WCSessionDelegate {

    private let logger = OTFLogger.logger()
    var peer: OTFWatchConnectivityPeer?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.debug("WCSession activation did complete: \(activationState.rawValue)")
        if activationState == .activated {
            let isLoggedIn = TheraForgeKeychainService.shared.loadAuth() != nil
            WatchAuthCommandPublisher.shared.flushLatestState(
                isLoggedIn: isLoggedIn,
                canPublishLoginReady: isLoggedIn && CareKitStoreManager.shared.isWatchSyncReadyForOutboundMessages()
            )
            _ = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossible(reason: "wc activation did complete")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.debug("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.debug("WCSession did deactivate")
    }

    /// Watch availability can change after login, so retry any pending durable login handoff.
    func sessionWatchStateDidChange(_ session: WCSession) {
        logger.debug("WCSession watch state did change")
        _ = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossible(reason: "wc watch state changed")
    }

    /// Reachability changes are another chance to publish a pending login context.
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.debug("WCSession reachability did change")
        _ = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossible(reason: "wc reachability changed")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncomingMessage(userInfo, replyHandler: nil)
    }

    #if DEBUG
    func handleIncomingMessageForTesting(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }
    #endif

    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        logger.debug("Did receive message from Watch App: \(message)")
        if let payloadMessage = message[OTFWatchConnectivityMessageKey.incrementalRevisionPush] as? [String: Any] {
            guard !rejectIfStaleWatchAuthContext(in: message, replyHandler: replyHandler) else {
                return
            }

            guard let payload = OTFWatchSyncPayload(message: payloadMessage) else {
                replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Invalid incremental sync payload"])
                return
            }

            applyIncrementalWatchPayload(payload, replyHandler: replyHandler)
        } else if message[OTFWatchConnectivityMessageKey.databaseSynced] is String {
            guard !rejectIfStaleWatchAuthContext(in: message, replyHandler: replyHandler) else {
                return
            }

            guard let store = currentStoreForWatchSync() else {
                replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Store unavailable for watch sync"])
                return
            }

            CareKitStoreManager.shared.beginApplyingRemoteWatchChanges()
            store.synchronize { _ in
                DispatchQueue.main.async {
                    CareKitStoreManager.shared.notifyRemoteOutcomeChange("watch full sync")
                    CareKitStoreManager.shared.endApplyingRemoteWatchChanges()
                    self.notifyWatchSyncApplied(ScheduleRefreshContext(changeKind: .fullResync))
                    CareKitStoreManager.shared.scheduleCloudantSyncForExplicitLocalMutation(reason: "watch full sync")
                    replyHandler?(["received": true])
                }
            }
        } else if let sample = WatchLiveHeartRateMessage.sample(from: message) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .healthSensorsLiveHeartRate,
                    object: nil,
                    userInfo: WatchLiveHeartRateMessage.bpmPayload(
                        bpm: sample.bpm,
                        timestamp: Date(timeIntervalSince1970: sample.timestamp)
                    )
                )
            }
            replyHandler?(["received": true])
        } else {
            guard let store = currentStoreForWatchSync() else {
                replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Store unavailable for watch sync"])
                return
            }

            guard let replyHandler else {
                return
            }

            guard !rejectIfStaleWatchAuthContext(in: message, replyHandler: replyHandler) else {
                return
            }

            peer?.reply(to: message, store: store) { reply in
                replyHandler(reply)
            }
        }
    }

    private func notifyWatchSyncApplied(_ scheduleRefreshContext: ScheduleRefreshContext?) {
        if let scheduleRefreshContext {
            NotificationCenter.default.postScheduleRefresh(scheduleRefreshContext)
        }
        NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
    }

    private func currentStoreForWatchSync() -> OTFCloudantStore? {
        CareKitStoreManager.shared.currentCloudantStoreForWatchSync()
    }

    /// Rejects watch-originated sync messages that do not match the committed auth session.
    private func rejectIfStaleWatchAuthContext(
        in message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?
    ) -> Bool {
        let context = OTFWatchAuthContext(message: message)
        switch WatchAuthSessionStore.shared.validationResult(forIncomingContext: context) {
        case .accepted:
            return false
        case .missing:
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Missing watch auth session"])
            return true
        case .mismatched:
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Stale watch auth session"])
            return true
        }
    }

    /// Applies authenticated incremental changes received from the watch to the phone store.
    private func applyIncrementalWatchPayload(_ payload: OTFWatchSyncPayload, replyHandler: (([String: Any]) -> Void)?) {
        guard let store = currentStoreForWatchSync() else {
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: "Store unavailable for watch sync"])
            return
        }

        CareKitStoreManager.shared.beginApplyingRemoteWatchChanges()

        do {
            let result = try store.applyIncrementalSync(payload: payload)
            let didApplyChanges = result.tasks > 0 || result.outcomes > 0 || result.deletions > 0
            SyncPerformanceTracker.shared.recordWatchPayload(
                direction: "received",
                tasks: result.tasks,
                outcomes: result.outcomes,
                deletions: result.deletions
            )
            DispatchQueue.main.async {
                if result.outcomes > 0 || result.deletions > 0 {
                    CareKitStoreManager.shared.notifyRemoteOutcomeChange("watch incremental import")
                }
                CareKitStoreManager.shared.endApplyingRemoteWatchChanges()
                if didApplyChanges {
                    self.notifyWatchSyncApplied(
                        WatchSyncScheduleRefreshContextResolver.context(for: result, payload: payload, store: store)
                    )
                    CareKitStoreManager.shared.scheduleCloudantSyncForExplicitLocalMutation(
                        reason: "watch incremental import",
                        debounce: 0.5
                    )
                }
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
            CareKitStoreManager.shared.endApplyingRemoteWatchChanges()
            replyHandler?([OTFWatchConnectivityMessageKey.revisionError: error.localizedDescription])
        }
    }

}
