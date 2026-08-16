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
import OTFCloudClientAPI
import OTFUtilities

struct SSEReconnectDecision {
    let auth: Auth
    let delay: TimeInterval
}

struct SSEReconnectPolicy {
    private let delays: [TimeInterval] = [1, 2, 5, 15, 30]

    func delay(forAttempt attempt: Int) -> TimeInterval {
        delays[min(max(attempt, 0), delays.count - 1)]
    }

    func reconnectDecision(
        eventSourceRequestedReconnect: Bool,
        error: Error?,
        completedOpenedStream: Bool = false,
        statusCode: Int? = nil,
        attempt: Int,
        startedWith startedAuth: Auth,
        currentAuth: Auth?
    ) -> SSEReconnectDecision? {
        let shouldReconnect =
            eventSourceRequestedReconnect ||
            isRecoverableNetworkError(error) ||
            isReconnectableOpenedStreamClose(completedOpenedStream: completedOpenedStream, statusCode: statusCode)

        guard shouldReconnect, let auth = sessionAuthForReconnect(startedWith: startedAuth, currentAuth: currentAuth) else {
            return nil
        }

        return SSEReconnectDecision(auth: auth, delay: delay(forAttempt: attempt))
    }

    func validAuthForReconnect(startedWith startedAuth: Auth, currentAuth: Auth?) -> Auth? {
        guard let currentAuth = sessionAuthForReconnect(startedWith: startedAuth, currentAuth: currentAuth),
              currentAuth.isValid() else {
            return nil
        }
        return currentAuth
    }

    func validAuthAfterSuccessfulRefresh(currentAuth: Auth?) -> Auth? {
        guard let currentAuth, currentAuth.isValid() else {
            return nil
        }
        return currentAuth
    }

    func requiresRefreshForReconnect(startedWith startedAuth: Auth, currentAuth: Auth?) -> Bool {
        guard let currentAuth = sessionAuthForReconnect(startedWith: startedAuth, currentAuth: currentAuth) else {
            return false
        }
        return !currentAuth.isValid()
    }

    func shouldRetryRefreshFailure(_ error: Error, startedWith startedAuth: Auth, currentAuth: Auth?) -> Bool {
        guard requiresRefreshForReconnect(startedWith: startedAuth, currentAuth: currentAuth) else {
            return false
        }
        return isRecoverableNetworkError(error)
    }

    private func sessionAuthForReconnect(startedWith startedAuth: Auth, currentAuth: Auth?) -> Auth? {
        guard let currentAuth else { return nil }
        guard currentAuth.token == startedAuth.token || currentAuth.refreshToken == startedAuth.refreshToken else {
            return nil
        }
        return currentAuth
    }

    private func isRecoverableNetworkError(_ error: Error?) -> Bool {
        guard let error else { return false }

        let nsError = error as NSError
        let recoverableCodes = [
            URLError.timedOut,
            URLError.networkConnectionLost,
            URLError.notConnectedToInternet,
            URLError.cannotFindHost,
            URLError.cannotConnectToHost,
            URLError.dnsLookupFailed,
            URLError.dataNotAllowed,
            URLError.cannotLoadFromNetwork
        ]

        if nsError.domain == NSURLErrorDomain {
            return recoverableCodes.contains(URLError.Code(rawValue: nsError.code))
        }

        if let forgeError = error as? ForgeError,
           let statusCode = forgeError.error.statusCode {
            return recoverableCodes.contains(URLError.Code(rawValue: statusCode))
        }

        return false
    }

    private func isReconnectableOpenedStreamClose(completedOpenedStream: Bool, statusCode: Int?) -> Bool {
        completedOpenedStream && statusCode == 200
    }
}

class SSEAndSyncManager {
    
    static let shared = SSEAndSyncManager()
    private let logger = OTFLogger.logger()
    private let openSyncMaxAge: TimeInterval = 20
    private let keepAliveSyncMaxAge: TimeInterval = 45
    private let dbUpdateDebounce: TimeInterval = 1.5
    private var hasPerformedInitialOpenSync = false
    private let reconnectPolicy = SSEReconnectPolicy()
    private var activeSubscriptionID = UUID()
    private var hasActiveStreamOpened = false
    private var reconnectAttempt = 0
    private var pendingReconnectWorkItem: DispatchWorkItem?
    private let verboseLoggingEnabled = ProcessInfo.processInfo.environment["OTF_SYNC_VERBOSE_LOGS"] == "1"

    // Subscribe to SSE
    public func subscribeToSSEWith(auth: Auth) {
        let subscriptionID = UUID()
        activeSubscriptionID = subscriptionID
        hasActiveStreamOpened = false
        cancelPendingReconnect()
        reconnectAttempt = 0
        hasPerformedInitialOpenSync = false
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnOpen = { [weak self] in
            self?.handleEventSourceOpen()
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.onReceivedMessage = { [weak self] event in
            guard let self else { return }
            if event.type.rawValue == EventType.dbUpdate.rawValue {
                self.requestScheduledSync(reason: "sse dbUpdate", debounce: self.dbUpdateDebounce)
            } else if event.type.rawValue == EventType.keepAlive.rawValue {
                self.handleKeepAlive()
            } else if event.type.rawValue == EventType.userDeleted.rawValue {
                NotificationCenter.default.post(name: .deleteUserAccount, object: nil)
            }
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnComplete = { [weak self] statusCode, reconnect, error in
            self?.handleEventSourceCompletion(
                statusCode: statusCode,
                eventSourceRequestedReconnect: reconnect == true,
                error: error,
                startedWith: auth,
                subscriptionID: subscriptionID
            )
        }
        TheraForgeNetwork.shared.observeOnServerSentEvents(auth: auth)
    }

    public func disconnectFromSSE() {
        activeSubscriptionID = UUID()
        hasActiveStreamOpened = false
        reconnectAttempt = 0
        hasPerformedInitialOpenSync = false
        cancelPendingReconnect()
        NetworkingLayer.shared.eventSource?.disconnect()
    }
    
    private func handleEventSourceOpen() {
        cancelPendingReconnect()
        reconnectAttempt = 0
        hasActiveStreamOpened = true

        let shouldSync =
            !hasPerformedInitialOpenSync ||
            CloudantSyncManager.shared.hasPendingOfflineChanges ||
            isLastSuccessfulSyncStale()

        guard shouldSync else {
            if verboseLoggingEnabled {
                logger.info("SSEAndSyncManager: Skipping sync on SSE open; local store is fresh")
            }
            return
        }

        hasPerformedInitialOpenSync = true
        requestScheduledSync(reason: "sse open", debounce: 0.25)
    }

    private func handleEventSourceCompletion(
        statusCode: Int?,
        eventSourceRequestedReconnect: Bool,
        error: Error?,
        startedWith auth: Auth,
        subscriptionID: UUID
    ) {
        let isActiveSubscription = activeSubscriptionID == subscriptionID
        guard isActiveSubscription else {
            return
        }
        let completedOpenedStream = hasActiveStreamOpened
        hasActiveStreamOpened = false

        let decision = reconnectPolicy.reconnectDecision(
            eventSourceRequestedReconnect: eventSourceRequestedReconnect,
            error: error,
            completedOpenedStream: completedOpenedStream,
            statusCode: statusCode,
            attempt: reconnectAttempt,
            startedWith: auth,
            currentAuth: TheraForgeKeychainService.shared.loadAuth()
        )

        guard let decision else {
            return
        }

        scheduleReconnect(startedWith: auth, subscriptionID: subscriptionID, delay: decision.delay)
        reconnectAttempt += 1
    }

    private func scheduleReconnect(startedWith auth: Auth, subscriptionID: UUID, delay: TimeInterval) {
        cancelPendingReconnect()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.activeSubscriptionID == subscriptionID else {
                return
            }

            let currentAuth = TheraForgeKeychainService.shared.loadAuth()
            if let reconnectAuth = self.reconnectPolicy.validAuthForReconnect(startedWith: auth, currentAuth: currentAuth) {
                self.openReconnect(auth: reconnectAuth)
                return
            }

            guard self.reconnectPolicy.requiresRefreshForReconnect(startedWith: auth, currentAuth: currentAuth) else {
                return
            }

            self.refreshAuthThenReconnect(startedWith: auth, subscriptionID: subscriptionID)
        }

        pendingReconnectWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func refreshAuthThenReconnect(startedWith auth: Auth, subscriptionID: UUID) {
        OTFTheraforgeNetwork.shared.refreshToken { [weak self] result in
            guard let self else { return }
            guard self.activeSubscriptionID == subscriptionID else {
                return
            }

            switch result {
            case .success:
                guard let reconnectAuth = self.reconnectPolicy.validAuthAfterSuccessfulRefresh(
                    currentAuth: TheraForgeKeychainService.shared.loadAuth()
                ) else {
                    return
                }
                self.openReconnect(auth: reconnectAuth)
            case .failure(let error):
                guard self.reconnectPolicy.shouldRetryRefreshFailure(
                    error,
                    startedWith: auth,
                    currentAuth: TheraForgeKeychainService.shared.loadAuth()
                ) else {
                    return
                }

                let delay = self.reconnectPolicy.delay(forAttempt: self.reconnectAttempt)
                self.scheduleReconnect(startedWith: auth, subscriptionID: subscriptionID, delay: delay)
                self.reconnectAttempt += 1
            }
        }
    }

    private func openReconnect(auth: Auth) {
        TheraForgeNetwork.shared.observeOnServerSentEvents(auth: auth)
    }

    private func cancelPendingReconnect() {
        pendingReconnectWorkItem?.cancel()
        pendingReconnectWorkItem = nil
    }

    private func handleKeepAlive() {
        guard shouldRefreshOnKeepAlive() else { return }
        logger.info("SSEAndSyncManager: Scheduling stale keep-alive sync")
        requestScheduledSync(reason: "sse keepAlive stale", debounce: 0.25)
    }

    private func isLastSuccessfulSyncStale() -> Bool {
        guard let lastSuccessfulSyncDate = CloudantSyncManager.shared.lastSuccessfulSyncDate else {
            return true
        }

        return Date().timeIntervalSince(lastSuccessfulSyncDate) >= openSyncMaxAge
    }

    private func shouldRefreshOnKeepAlive() -> Bool {
        if CloudantSyncManager.shared.hasPendingOfflineChanges {
            return true
        }

        guard let lastSuccessfulSyncDate = CloudantSyncManager.shared.lastSuccessfulSyncDate else {
            return true
        }

        return Date().timeIntervalSince(lastSuccessfulSyncDate) >= keepAliveSyncMaxAge
    }

    private func requestScheduledSync(reason: String, debounce: TimeInterval) {
        let syncOrder: SyncOrder = CloudantSyncManager.shared.hasPendingOfflineChanges ? .pushThenPull : .pullOnly
        CloudantSyncManager.shared.scheduleIncrementalSync(
            reason: reason,
            notifyWhenDone: true,
            debounce: debounce,
            syncOrder: syncOrder
        )
    }
}
