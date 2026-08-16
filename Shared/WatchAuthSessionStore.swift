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

#if os(iOS)
import OTFUtilities
import WatchConnectivity
#endif

enum WatchAuthCommandKind: String {
    case logout
    case loginReady
}

struct WatchAuthCommand: Equatable {
    let kind: WatchAuthCommandKind
    let context: OTFWatchAuthContext?
    let generation: Int

    init(kind: WatchAuthCommandKind, context: OTFWatchAuthContext?, generation: Int) {
        self.kind = kind
        self.context = context
        self.generation = generation
    }

    init?(message: [String: Any]) {
        guard let rawKind = message[OTFWatchConnectivityMessageKey.watchAuthCommand] as? String,
              let kind = WatchAuthCommandKind(rawValue: rawKind),
              let generation = message[OTFWatchConnectivityMessageKey.authCommandGeneration] as? Int else {
            return nil
        }

        let context = OTFWatchAuthContext(message: message)
        if kind == .loginReady, context == nil {
            return nil
        }

        self.kind = kind
        self.context = context
        self.generation = generation
    }

    var message: [String: Any] {
        var message: [String: Any] = [
            OTFWatchConnectivityMessageKey.watchAuthCommand: kind.rawValue,
            OTFWatchConnectivityMessageKey.authCommandGeneration: generation
        ]
        if let context {
            message = context.addingFields(to: message)
        }
        return message
    }
}

enum WatchAuthApplyResult: Equatable {
    case accepted(needsWipe: Bool)
    case stale
}

enum WatchAuthPublishUnavailableReason: Equatable {
    case unsupported
    case notActivated
    case notPaired
    case watchAppNotInstalled
}

/// Describes the durable-delivery boundary for auth commands sent from iPhone to Watch.
///
/// Login handoff is only considered complete after `updateApplicationContext` succeeds,
/// because that state is retained by WatchConnectivity and can be delivered after the
/// watch app wakes up. `sendMessage` is still used as a fast path when reachable, but it
/// is not the source of truth for committing a pending login session.
enum WatchAuthPublishResult {
    case storedInApplicationContext
    case unavailable(reason: WatchAuthPublishUnavailableReason)
    case failed(Error)

    var didStoreInApplicationContext: Bool {
        if case .storedInApplicationContext = self {
            return true
        }
        return false
    }
}

enum WatchAuthValidationResult: Equatable {
    case accepted
    case missing
    case mismatched
}

enum WatchIncomingPhoneAuthResult: Equatable {
    case accepted(context: OTFWatchAuthContext, needsWipe: Bool)
    case rejected(error: String)
}

final class WatchAuthSessionStore {
    static let shared = WatchAuthSessionStore()

    private enum DefaultsKey {
        static let sessionID = "watchAuthSessionID"
        static let generation = "watchAuthCommandGeneration"
        static let pendingSessionID = "watchAuthPendingSessionID"
        static let pendingGeneration = "watchAuthPendingCommandGeneration"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentGeneration: Int {
        defaults.integer(forKey: DefaultsKey.generation)
    }

    func currentContext() -> OTFWatchAuthContext? {
        guard let sessionID = defaults.string(forKey: DefaultsKey.sessionID),
              !sessionID.isEmpty else {
            return nil
        }
        return OTFWatchAuthContext(sessionID: sessionID, generation: currentGeneration)
    }

    /// Returns true only when the committed phone session can safely be advertised to the watch.
    ///
    /// Pending login sessions intentionally block this path. They must first survive the
    /// background Cloudant sync and be stored in WatchConnectivity's application context.
    func isLoginReadyPublishable(isLoggedIn: Bool) -> Bool {
        guard isLoggedIn, pendingLoginContext() == nil else {
            return false
        }
        return currentContext() != nil
    }

    /// Creates a login session that is not yet accepted as the current watch auth session.
    ///
    /// The pending session lets the iPhone finish its first post-login Cloudant sync and
    /// durably publish the `loginReady` command before the watch is allowed to pull data.
    func beginPendingLoginSession() -> WatchAuthCommand {
        let generation = nextGeneration()
        let sessionID = UUID().uuidString
        defaults.set(sessionID, forKey: DefaultsKey.pendingSessionID)
        defaults.set(generation, forKey: DefaultsKey.pendingGeneration)

        let context = OTFWatchAuthContext(sessionID: sessionID, generation: generation)
        return WatchAuthCommand(kind: .loginReady, context: context, generation: generation)
    }

    /// Returns the durable command that still needs to be published for the pending login.
    func pendingLoginCommand() -> WatchAuthCommand? {
        guard let context = pendingLoginContext() else {
            return nil
        }
        return WatchAuthCommand(kind: .loginReady, context: context, generation: context.generation)
    }

    /// Promotes the pending login to the committed watch auth session after durable publish.
    func commitPendingLoginSession(_ command: WatchAuthCommand) -> WatchAuthApplyResult {
        guard command.kind == .loginReady,
              let commandContext = command.context,
              pendingLoginContext() == commandContext else {
            return .stale
        }

        let result = commit(command)
        if case .accepted = result {
            clearPendingLoginSession()
        }
        return result
    }

    /// Commits a pending login when the caller has already completed the durable handoff.
    func commitPendingLoginSessionAfterSuccessfulSync() -> WatchAuthCommand? {
        guard let command = pendingLoginCommand() else {
            return nil
        }

        guard case .accepted = commitPendingLoginSession(command) else {
            return nil
        }
        return command
    }

    func beginLoginSession() -> WatchAuthCommand {
        let generation = nextGeneration()
        let sessionID = UUID().uuidString
        defaults.set(sessionID, forKey: DefaultsKey.sessionID)
        defaults.set(generation, forKey: DefaultsKey.generation)
        clearPendingLoginSession()

        let context = OTFWatchAuthContext(sessionID: sessionID, generation: generation)
        return WatchAuthCommand(kind: .loginReady, context: context, generation: generation)
    }

    func currentOrBeginLoginCommand() -> WatchAuthCommand {
        if let context = currentContext() {
            return WatchAuthCommand(kind: .loginReady, context: context, generation: context.generation)
        }
        return beginLoginSession()
    }

    func currentOrBeginLoginContext() -> OTFWatchAuthContext {
        currentOrBeginLoginCommand().context!
    }

    @discardableResult
    func makeLogoutCommand() -> WatchAuthCommand {
        let generation = currentGeneration + 1
        defaults.removeObject(forKey: DefaultsKey.sessionID)
        defaults.set(generation, forKey: DefaultsKey.generation)
        clearPendingLoginSession()
        return WatchAuthCommand(kind: .logout, context: nil, generation: generation)
    }

    func transitionResult(for command: WatchAuthCommand) -> WatchAuthApplyResult {
        guard command.generation > currentGeneration else {
            return .stale
        }

        switch command.kind {
        case .logout:
            return .accepted(needsWipe: true)

        case .loginReady:
            guard let context = command.context,
                  context.generation == command.generation else {
                return .stale
            }

            let needsWipe = currentContext()?.sessionID != context.sessionID
            return .accepted(needsWipe: needsWipe)
        }
    }

    func commit(_ command: WatchAuthCommand) -> WatchAuthApplyResult {
        let result = transitionResult(for: command)
        guard case .accepted = result else {
            return result
        }

        switch command.kind {
        case .logout:
            defaults.removeObject(forKey: DefaultsKey.sessionID)
            defaults.set(command.generation, forKey: DefaultsKey.generation)
            clearPendingLoginSession()

        case .loginReady:
            guard let context = command.context else {
                return .stale
            }
            defaults.set(context.sessionID, forKey: DefaultsKey.sessionID)
            defaults.set(command.generation, forKey: DefaultsKey.generation)
            clearPendingLoginSession()
        }

        return result
    }

    func apply(_ command: WatchAuthCommand) -> WatchAuthApplyResult {
        commit(command)
    }

    func transitionResult(forIncomingPhoneContext context: OTFWatchAuthContext) -> WatchAuthApplyResult {
        if currentContext() == context {
            return .accepted(needsWipe: false)
        }

        guard context.generation > currentGeneration else {
            return .stale
        }

        let needsWipe = currentContext()?.sessionID != context.sessionID
        return .accepted(needsWipe: needsWipe)
    }

    func incomingPhoneAuthResult(for message: [String: Any]) -> WatchIncomingPhoneAuthResult {
        guard let context = OTFWatchAuthContext(message: message) else {
            return .rejected(error: "Missing phone auth session")
        }

        switch transitionResult(forIncomingPhoneContext: context) {
        case .stale:
            return .rejected(error: "Stale phone auth session")
        case .accepted(let needsWipe):
            return .accepted(context: context, needsWipe: needsWipe)
        }
    }

    func commitIncomingPhoneContext(_ context: OTFWatchAuthContext) -> WatchAuthApplyResult {
        if currentContext() == context {
            return .accepted(needsWipe: false)
        }

        return commit(WatchAuthCommand(kind: .loginReady, context: context, generation: context.generation))
    }

    func applyIncomingPhoneContext(_ context: OTFWatchAuthContext) -> WatchAuthApplyResult {
        commitIncomingPhoneContext(context)
    }

    func shouldAcceptLegacyLogout() -> Bool {
        currentGeneration == 0
    }

    func validationResult(forIncomingContext context: OTFWatchAuthContext?) -> WatchAuthValidationResult {
        guard let expectedContext = currentContext() else {
            return .missing
        }
        guard let context else {
            return .missing
        }
        guard context == expectedContext else {
            return .mismatched
        }
        return .accepted
    }

    private func nextGeneration() -> Int {
        max(currentGeneration, pendingLoginContext()?.generation ?? 0) + 1
    }

    private func pendingLoginContext() -> OTFWatchAuthContext? {
        guard let sessionID = defaults.string(forKey: DefaultsKey.pendingSessionID),
              !sessionID.isEmpty else {
            return nil
        }
        let generation = defaults.integer(forKey: DefaultsKey.pendingGeneration)
        guard generation > 0 else {
            return nil
        }
        return OTFWatchAuthContext(sessionID: sessionID, generation: generation)
    }

    private func clearPendingLoginSession() {
        defaults.removeObject(forKey: DefaultsKey.pendingSessionID)
        defaults.removeObject(forKey: DefaultsKey.pendingGeneration)
    }
}

#if os(iOS)
final class WatchAuthCommandPublisher {
    static let shared = WatchAuthCommandPublisher()

    private let logger = OTFLogger.logger()
    private let sessionProvider: () -> WCSession
    private let sessionStore: WatchAuthSessionStore

    init(
        sessionProvider: @escaping () -> WCSession = { WCSession.default },
        sessionStore: WatchAuthSessionStore = .shared
    ) {
        self.sessionProvider = sessionProvider
        self.sessionStore = sessionStore
    }

    /// Stores an auth command in WatchConnectivity's durable application context.
    ///
    /// A successful return means the watch can receive the command even if it was not
    /// reachable for an immediate `sendMessage`. Unavailable states are recoverable and
    /// leave pending login sessions uncommitted for a later retry.
    @discardableResult
    func publish(_ command: WatchAuthCommand, cancelOutstandingUserInfoTransfers: Bool) -> WatchAuthPublishResult {
        guard WCSession.isSupported() else {
            logger.debug("Watch auth command skipped; WCSession unsupported")
            return .unavailable(reason: .unsupported)
        }

        let session = sessionProvider()
        guard session.activationState == .activated else {
            return .unavailable(reason: .notActivated)
        }
        guard session.isPaired else {
            return .unavailable(reason: .notPaired)
        }
        guard session.isWatchAppInstalled else {
            return .unavailable(reason: .watchAppNotInstalled)
        }

        if cancelOutstandingUserInfoTransfers {
            session.outstandingUserInfoTransfers.forEach { $0.cancel() }
        }

        do {
            try session.updateApplicationContext(command.message)
        } catch {
            logger.error("Failed to update watch auth application context: \(error.localizedDescription)")
            return .failed(error)
        }

        guard session.isReachable else {
            logger.debug("Watch auth command stored as application context; watch not reachable")
            return .storedInApplicationContext
        }

        session.sendMessage(command.message, replyHandler: nil) { [logger] error in
            logger.info("Immediate watch auth command delivery failed: \(error.localizedDescription)")
        }
        return .storedInApplicationContext
    }

    /// Republishes the last committed auth state after WatchConnectivity availability changes.
    ///
    /// This is intentionally limited to committed sessions. Pending logins are retried by
    /// `CloudantSyncManager`, which can verify the post-login sync completed before commit.
    func flushLatestState(isLoggedIn: Bool = false, canPublishLoginReady: Bool = false) {
        if isLoggedIn {
            guard canPublishLoginReady,
                  sessionStore.isLoginReadyPublishable(isLoggedIn: true),
                  let context = sessionStore.currentContext() else {
                logger.debug("Watch auth loginReady flush skipped; no committed ready session")
                return
            }

            let command = WatchAuthCommand(kind: .loginReady, context: context, generation: context.generation)
            _ = publish(command, cancelOutstandingUserInfoTransfers: false)
        } else if sessionStore.currentGeneration > 0 {
            let command = WatchAuthCommand(
                kind: .logout,
                context: nil,
                generation: sessionStore.currentGeneration
            )
            _ = publish(command, cancelOutstandingUserInfoTransfers: false)
        }
    }
}
#endif
