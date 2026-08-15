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
import Testing
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("Watch auth session store")
struct WatchAuthSessionStoreTests {
    @Test("Watch auth command round trips login-ready messages")
    func watchAuthCommandRoundTripsLoginReadyMessages() throws {
        let context = OTFWatchAuthContext(sessionID: "session-a", generation: 4)
        let command = WatchAuthCommand(kind: .loginReady, context: context, generation: 4)

        let decodedCommand = try #require(WatchAuthCommand(message: command.message))

        #expect(decodedCommand == command)
        #expect(decodedCommand.context == context)
    }

    @Test("Watch auth command rejects login-ready messages without context")
    func watchAuthCommandRejectsLoginReadyMessagesWithoutContext() {
        let message: [String: Any] = [
            OTFWatchConnectivityMessageKey.watchAuthCommand: WatchAuthCommandKind.loginReady.rawValue,
            OTFWatchConnectivityMessageKey.authCommandGeneration: 1
        ]

        #expect(WatchAuthCommand(message: message) == nil)
    }

    @Test("Watch auth command rejects messages with unknown kind or missing generation")
    func watchAuthCommandRejectsMessagesWithUnknownKindOrMissingGeneration() {
        let unknownKindMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.watchAuthCommand: "refresh",
            OTFWatchConnectivityMessageKey.authCommandGeneration: 1
        ]
        let missingGenerationMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.watchAuthCommand: WatchAuthCommandKind.logout.rawValue
        ]

        #expect(WatchAuthCommand(message: unknownKindMessage) == nil)
        #expect(WatchAuthCommand(message: missingGenerationMessage) == nil)
    }

    @Test("Watch auth command accepts logout messages without context")
    func watchAuthCommandAcceptsLogoutMessagesWithoutContext() throws {
        let message: [String: Any] = [
            OTFWatchConnectivityMessageKey.watchAuthCommand: WatchAuthCommandKind.logout.rawValue,
            OTFWatchConnectivityMessageKey.authCommandGeneration: 5
        ]

        let command = try #require(WatchAuthCommand(message: message))

        #expect(command.kind == .logout)
        #expect(command.context == nil)
        #expect(command.generation == 5)
    }

    @Test("Watch Auth Session Store Creates New Login Session And Context")
    func watchAuthSessionStoreCreatesNewLoginSessionAndContext() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let command = store.beginLoginSession()

        #expect(command.kind == .loginReady)
        #expect((command.context) != nil)
        #expect(store.currentContext()?.sessionID == command.context?.sessionID)
        #expect(store.currentContext()?.generation == 1)
    }

    @Test("Watch Auth Session Store Keeps Pending Login Invisible Until Committed")
    func watchAuthSessionStoreKeepsPendingLoginInvisibleUntilCommitted() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let command = store.beginPendingLoginSession()

        #expect(command.kind == .loginReady)
        #expect((command.context) != nil)
        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)

        #expect(store.commitPendingLoginSession(command) == .accepted(needsWipe: true))
        #expect(store.currentContext() == command.context)
        #expect(store.currentGeneration == 1)
    }

    @Test("Watch Auth Session Store Keeps Pending Login Invisible Across Restart")
    func watchAuthSessionStoreKeepsPendingLoginInvisibleAcrossRestart() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let firstStore = WatchAuthSessionStore(defaults: defaults)

        _ = firstStore.beginPendingLoginSession()
        let restartedStore = WatchAuthSessionStore(defaults: defaults)

        #expect((restartedStore.currentContext()) == nil)
        #expect(restartedStore.currentGeneration == 0)
        #expect(!(restartedStore.isLoginReadyPublishable(isLoggedIn: true)))
    }

    @Test("Watch Auth Session Store Starts Pending Login After Current Session Without Replacing It")
    func watchAuthSessionStoreStartsPendingLoginAfterCurrentSessionWithoutReplacingIt() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let currentContext = try #require(store.beginLoginSession().context)

        let pendingCommand = store.beginPendingLoginSession()

        #expect(pendingCommand.generation == currentContext.generation + 1)
        #expect(store.currentContext() == currentContext)
        #expect(store.pendingLoginCommand() == pendingCommand)
        #expect(!store.isLoginReadyPublishable(isLoggedIn: true))
    }

    @Test("Watch Auth Command Publisher Does Not Create Context Before Login Ready")
    func watchAuthCommandPublisherDoesNotCreateContextBeforeLoginReady() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let publisher = WatchAuthCommandPublisher(sessionStore: store)

        publisher.flushLatestState(isLoggedIn: true, canPublishLoginReady: false)

        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
    }

    @Test("Watch Auth Command Publisher Does Not Create Context When Flush Claims Ready Without Committed Session")
    func watchAuthCommandPublisherDoesNotCreateContextWhenFlushClaimsReadyWithoutCommittedSession() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let publisher = WatchAuthCommandPublisher(sessionStore: store)

        publisher.flushLatestState(isLoggedIn: true, canPublishLoginReady: true)

        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
    }

    @Test("Watch Auth Command Publisher Does Not Create Context Before Login Ready When Pending Login Exists")
    func watchAuthCommandPublisherDoesNotCreateContextBeforeLoginReadyWhenPendingLoginExists() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let publisher = WatchAuthCommandPublisher(sessionStore: store)

        _ = store.beginPendingLoginSession()
        publisher.flushLatestState(isLoggedIn: true, canPublishLoginReady: false)

        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
    }

    @Test("Watch Auth Session Store Does Not Treat Auth With Pending Login As Ready")
    func watchAuthSessionStoreDoesNotTreatAuthWithPendingLoginAsReady() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        _ = store.beginPendingLoginSession()

        #expect(!(store.isLoginReadyPublishable(isLoggedIn: true)))
    }

    @Test("Watch Auth Session Store Treats Committed Login As Ready After Sync")
    func watchAuthSessionStoreTreatsCommittedLoginAsReadyAfterSync() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let command = store.beginPendingLoginSession()

        #expect(store.commitPendingLoginSession(command) == .accepted(needsWipe: true))

        #expect(store.isLoginReadyPublishable(isLoggedIn: true))
        #expect(!(store.isLoginReadyPublishable(isLoggedIn: false)))
        #expect(WatchAuthSessionStore(defaults: defaults).isLoginReadyPublishable(isLoggedIn: true))
    }

    @Test("Watch Auth Session Store Can Recover Pending Login After Later Sync")
    func watchAuthSessionStoreCanRecoverPendingLoginAfterLaterSync() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let firstStore = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = firstStore.beginPendingLoginSession()
        let restartedStore = WatchAuthSessionStore(defaults: defaults)

        let recoveredCommand = try #require(restartedStore.commitPendingLoginSessionAfterSuccessfulSync())

        #expect(recoveredCommand == pendingCommand)
        #expect(restartedStore.currentContext() == pendingCommand.context)
        #expect(restartedStore.isLoginReadyPublishable(isLoggedIn: true))
    }

    @Test("Watch Auth Session Store Reuses Current Login Command Once Created")
    func watchAuthSessionStoreReusesCurrentLoginCommandOnceCreated() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let firstCommand = store.currentOrBeginLoginCommand()
        let secondCommand = store.currentOrBeginLoginCommand()

        #expect(firstCommand == secondCommand)
        #expect(store.currentContext() == firstCommand.context)
        #expect(store.currentGeneration == firstCommand.generation)
    }

    @Test("Watch Auth Session Store Has No Recovery Command Without Pending Login")
    func watchAuthSessionStoreHasNoRecoveryCommandWithoutPendingLogin() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        #expect((store.commitPendingLoginSessionAfterSuccessfulSync()) == nil)
    }

    @Test("Watch Auth Session Store Rejects Mismatched Pending Login Commit")
    func watchAuthSessionStoreRejectsMismatchedPendingLoginCommit() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()
        let pendingContext = try #require(pendingCommand.context)
        let mismatchedCommand = WatchAuthCommand(
            kind: .loginReady,
            context: OTFWatchAuthContext(sessionID: "\(pendingContext.sessionID)-other", generation: pendingContext.generation),
            generation: pendingCommand.generation
        )

        #expect(store.commitPendingLoginSession(mismatchedCommand) == .stale)
        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
        #expect(store.commitPendingLoginSessionAfterSuccessfulSync() == pendingCommand)
    }

    @Test("Watch Auth Session Store Rejects Logout As Pending Login Commit")
    func watchAuthSessionStoreRejectsLogoutAsPendingLoginCommit() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()
        let logoutCommand = WatchAuthCommand(kind: .logout, context: nil, generation: pendingCommand.generation)

        #expect(store.commitPendingLoginSession(logoutCommand) == .stale)
        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
        #expect(store.commitPendingLoginSessionAfterSuccessfulSync() == pendingCommand)
    }

    @Test("Watch Auth Session Store Validates Transition Without Persisting")
    func watchAuthSessionStoreValidatesTransitionWithoutPersisting() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let command = WatchAuthCommand(
            kind: .loginReady,
            context: OTFWatchAuthContext(sessionID: "session-a", generation: 1),
            generation: 1
        )

        #expect(store.transitionResult(for: command) == .accepted(needsWipe: true))
        #expect((store.currentContext()) == nil)

        #expect(store.commit(command) == .accepted(needsWipe: true))
        #expect(store.currentContext()?.sessionID == "session-a")
        #expect(store.currentGeneration == 1)
    }

    @Test("Watch Auth Session Store Does Not Wipe For Newer Generation Of Same Session")
    func watchAuthSessionStoreDoesNotWipeForNewerGenerationOfSameSession() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let currentContext = try #require(store.beginLoginSession().context)
        let updatedContext = OTFWatchAuthContext(sessionID: currentContext.sessionID, generation: 2)
        let command = WatchAuthCommand(kind: .loginReady, context: updatedContext, generation: 2)

        #expect(store.transitionResult(for: command) == .accepted(needsWipe: false))
        #expect(store.commit(command) == .accepted(needsWipe: false))
        #expect(store.currentContext() == updatedContext)
    }

    @Test("Watch Auth Session Store Rejects Login Ready With Mismatched Context Generation")
    func watchAuthSessionStoreRejectsLoginReadyWithMismatchedContextGeneration() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let command = WatchAuthCommand(
            kind: .loginReady,
            context: OTFWatchAuthContext(sessionID: "session-a", generation: 2),
            generation: 1
        )

        #expect(store.transitionResult(for: command) == .stale)
        #expect(store.commit(command) == .stale)
        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 0)
    }

    @Test("Watch Auth Session Store Validates Incoming Phone Context Without Persisting")
    func watchAuthSessionStoreValidatesIncomingPhoneContextWithoutPersisting() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let context = OTFWatchAuthContext(sessionID: "phone-session", generation: 1)

        #expect(store.transitionResult(forIncomingPhoneContext: context) == .accepted(needsWipe: true))
        #expect((store.currentContext()) == nil)

        #expect(store.commitIncomingPhoneContext(context) == .accepted(needsWipe: true))
        #expect(store.currentContext() == context)
    }

    @Test("Watch Auth Session Store Accepts Matching Incoming Phone Context Without Wipe")
    func watchAuthSessionStoreAcceptsMatchingIncomingPhoneContextWithoutWipe() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let context = try #require(store.beginLoginSession().context)

        #expect(store.transitionResult(forIncomingPhoneContext: context) == .accepted(needsWipe: false))
        #expect(store.incomingPhoneAuthResult(for: context.addingFields(to: [:])) == .accepted(
            context: context,
            needsWipe: false
        ))
    }

    @Test("Watch Auth Session Store Rejects Legacy Logout After Newer Generation")
    func watchAuthSessionStoreRejectsLegacyLogoutAfterNewerGeneration() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        #expect(store.shouldAcceptLegacyLogout())
        _ = store.beginLoginSession()

        #expect(!(store.shouldAcceptLegacyLogout()))
    }

    @Test("Watch Auth Session Store Logout Clears Session And Advances Generation")
    func watchAuthSessionStoreLogoutClearsSessionAndAdvancesGeneration() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        _ = store.beginLoginSession()

        let command = store.makeLogoutCommand()

        #expect(command.kind == .logout)
        #expect((command.context) == nil)
        #expect((store.currentContext()) == nil)
        #expect(store.currentGeneration == 2)
    }

    @Test("Watch Auth Session Store Ignores Stale Logout After Newer Login")
    func watchAuthSessionStoreIgnoresStaleLogoutAfterNewerLogin() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let staleLogout = WatchAuthCommand(kind: .logout, context: nil, generation: 2)
        let newerLogin = WatchAuthCommand(
            kind: .loginReady,
            context: OTFWatchAuthContext(sessionID: "session-b", generation: 3),
            generation: 3
        )

        #expect(store.apply(newerLogin) == .accepted(needsWipe: true))
        #expect(store.apply(staleLogout) == .stale)
        #expect(store.currentContext()?.sessionID == "session-b")
        #expect(store.currentGeneration == 3)
    }

    @Test("Watch Auth Session Store Rejects Missing Incoming Context")
    func watchAuthSessionStoreRejectsMissingIncomingContext() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        _ = store.beginLoginSession()

        #expect(store.validationResult(forIncomingContext: nil) == .missing)
    }

    @Test("Watch Auth Session Store Rejects Stale Incoming Context")
    func watchAuthSessionStoreRejectsStaleIncomingContext() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        _ = store.beginLoginSession()
        let stale = OTFWatchAuthContext(sessionID: "old-session", generation: 1)

        #expect(store.validationResult(forIncomingContext: stale) == .mismatched)
    }

    @Test("Watch Auth Session Store Creates Context For Existing Logged In User")
    func watchAuthSessionStoreCreatesContextForExistingLoggedInUser() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let context = store.currentOrBeginLoginContext()

        #expect(context.generation == 1)
        #expect(store.currentContext() == context)
    }

    @Test("Watch Auth Session Store Applies Newer Incoming Phone Context Before Data")
    func watchAuthSessionStoreAppliesNewerIncomingPhoneContextBeforeData() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let context = OTFWatchAuthContext(sessionID: "phone-session", generation: 1)

        #expect(store.applyIncomingPhoneContext(context) == .accepted(needsWipe: true))
        #expect(store.currentContext() == context)
    }

    @Test("Watch Auth Session Store Rejects Older Phone Context After Logout")
    func watchAuthSessionStoreRejectsOlderPhoneContextAfterLogout() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let oldContext = try #require(store.beginLoginSession().context)
        _ = store.makeLogoutCommand()

        #expect(store.applyIncomingPhoneContext(oldContext) == .stale)
        #expect((store.currentContext()) == nil)
    }

    @Test("Watch Fallback Rejects Missing Phone Auth Context")
    func watchFallbackRejectsMissingPhoneAuthContext() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let result = store.incomingPhoneAuthResult(for: ["legacyRevisionRequest": true])

        #expect(result == .rejected(error: "Missing phone auth session"))
    }

    @Test("Watch Fallback Rejects Stale Phone Auth Context")
    func watchFallbackRejectsStalePhoneAuthContext() throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        _ = store.beginLoginSession()
        let staleContext = OTFWatchAuthContext(sessionID: "old-session", generation: 1)

        let result = store.incomingPhoneAuthResult(
            for: staleContext.addingFields(to: ["legacyRevisionRequest": true])
        )

        #expect(result == .rejected(error: "Stale phone auth session"))
    }

}
