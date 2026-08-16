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
@testable import OTFMagicBox

@Suite("Watch pending login retry", .serialized)
struct WatchPendingLoginRetryTests {
    @Test("Watch auth session store exposes pending login without committing")
    func watchAuthSessionStoreExposesPendingLoginWithoutCommitting() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)

        let pendingCommand = store.beginPendingLoginSession()

        #expect(store.pendingLoginCommand() == pendingCommand)
        #expect(store.currentContext() == nil)
        #expect(store.currentGeneration == 0)
        #expect(!store.isLoginReadyPublishable(isLoggedIn: true))
    }

    @Test("Watch auth session store clears pending login after commit")
    func watchAuthSessionStoreClearsPendingLoginAfterCommit() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()

        #expect(store.commitPendingLoginSession(pendingCommand) == .accepted(needsWipe: true))

        #expect(store.pendingLoginCommand() == nil)
        #expect(store.currentContext() == pendingCommand.context)
        #expect(store.isLoginReadyPublishable(isLoggedIn: true))
    }

    @Test("Watch auth session store logout clears pending login session")
    func watchAuthSessionStoreLogoutClearsPendingLoginSession() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        _ = store.beginPendingLoginSession()

        let logoutCommand = store.makeLogoutCommand()

        #expect(logoutCommand.kind == .logout)
        #expect(store.pendingLoginCommand() == nil)
        #expect(store.currentContext() == nil)
        #expect(store.currentGeneration == 1)
    }

    @Test("Cloudant sync manager keeps pending login when publish is unavailable")
    func cloudantSyncManagerKeepsPendingLoginWhenPublishUnavailable() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()
        var readiness: Bool?
        var publishedCommand: WatchAuthCommand?

        let outcome = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossibleForTesting(
            reason: "unit test unavailable",
            isLoggedIn: true,
            sessionStore: store,
            setWatchSyncReady: { readiness = $0 },
            publish: { command, cancelOutstanding in
                publishedCommand = command
                #expect(!cancelOutstanding)
                return .unavailable(reason: .watchAppNotInstalled)
            }
        )

        #expect(outcome == .unavailable(reason: .watchAppNotInstalled))
        #expect(publishedCommand == pendingCommand)
        #expect(store.pendingLoginCommand() == pendingCommand)
        #expect(store.currentContext() == nil)
        #expect(readiness == false)
    }

    @Test("Cloudant sync manager keeps pending login when publish fails")
    func cloudantSyncManagerKeepsPendingLoginWhenPublishFails() {
        struct TestError: LocalizedError {
            var errorDescription: String? { "application context failed" }
        }

        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()
        var readiness: Bool?

        let outcome = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossibleForTesting(
            reason: "unit test failure",
            isLoggedIn: true,
            sessionStore: store,
            setWatchSyncReady: { readiness = $0 },
            publish: { _, _ in .failed(TestError()) }
        )

        #expect(outcome == .failed(message: "application context failed"))
        #expect(store.pendingLoginCommand() == pendingCommand)
        #expect(store.currentContext() == nil)
        #expect(readiness == false)
    }

    @Test("Cloudant sync manager commits pending login after durable publish")
    func cloudantSyncManagerCommitsPendingLoginAfterDurablePublish() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        let pendingCommand = store.beginPendingLoginSession()
        var readiness: Bool?
        var publishedCommand: WatchAuthCommand?
        var cancelOutstandingUserInfoTransfers: Bool?

        let outcome = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossibleForTesting(
            reason: "unit test success",
            isLoggedIn: true,
            sessionStore: store,
            setWatchSyncReady: { readiness = $0 },
            publish: { command, cancelOutstanding in
                publishedCommand = command
                cancelOutstandingUserInfoTransfers = cancelOutstanding
                return .storedInApplicationContext
            }
        )

        #expect(outcome == .committed)
        #expect(store.currentContext() == pendingCommand.context)
        #expect(store.pendingLoginCommand() == nil)
        #expect(publishedCommand == pendingCommand)
        #expect(readiness == true)
        #expect(cancelOutstandingUserInfoTransfers == false)
    }

    @Test("Cloudant sync manager skips retry when no pending login exists")
    func cloudantSyncManagerSkipsRetryWhenNoPendingLoginExists() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "watch-auth")
        defer { defaultsFixture.cleanup() }
        let defaults = defaultsFixture.defaults
        let store = WatchAuthSessionStore(defaults: defaults)
        var didPublish = false

        let outcome = CloudantSyncManager.shared.retryPendingWatchLoginPublishIfPossibleForTesting(
            reason: "unit test no pending",
            isLoggedIn: true,
            sessionStore: store,
            setWatchSyncReady: { _ in },
            publish: { _, _ in
                didPublish = true
                return .storedInApplicationContext
            }
        )

        #expect(outcome == .skippedNoPendingLogin)
        #expect(!didPublish)
    }
}
