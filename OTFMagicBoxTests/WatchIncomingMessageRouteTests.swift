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
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("Watch incoming message route")
struct WatchIncomingMessageRouteTests {
    @Test("Auth command has priority over other message markers")
    func authCommandHasPriorityOverOtherMessageMarkers() {
        let command = WatchAuthCommand(kind: .logout, context: nil, generation: 3)
        var message = WatchLiveHeartRateMessage.startRequest()
        command.message.forEach { message[$0.key] = $0.value }

        guard case .authCommand(let routedCommand) = WatchIncomingMessageRoute(message: message) else {
            Issue.record("Expected auth command route")
            return
        }

        #expect(routedCommand == command)
    }

    @Test("Incremental sync payload routes valid and malformed payloads distinctly")
    func incrementalSyncPayloadRoutesValidAndMalformedPayloadsDistinctly() {
        let payload = OTFWatchSyncPayload(deletedDocumentIDs: ["deleted-doc"])
        let validMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.incrementalRevisionPush: payload.message
        ]
        let invalidMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.incrementalRevisionPush: [
                "tasks": "not-an-array"
            ]
        ]

        guard case .incrementalRevisionPush(let routedPayload) = WatchIncomingMessageRoute(message: validMessage) else {
            Issue.record("Expected incremental revision push route")
            return
        }

        #expect(routedPayload.deletedDocumentIDs == ["deleted-doc"])
        guard case .invalidIncrementalRevisionPush = WatchIncomingMessageRoute(message: invalidMessage) else {
            Issue.record("Expected invalid incremental revision push route")
            return
        }
    }

    @Test("Incremental sync payload rejects empty and malformed typed deletions")
    func incrementalSyncPayloadRejectsEmptyAndMalformedTypedDeletions() {
        let emptyPayloadMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.incrementalRevisionPush: OTFWatchSyncPayload().message
        ]
        let malformedDeletionMessage: [String: Any] = [
            OTFWatchConnectivityMessageKey.incrementalRevisionPush: [
                "deletions": [[
                    "documentID": "not-canonical",
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue
                ]]
            ]
        ]

        guard case .invalidIncrementalRevisionPush = WatchIncomingMessageRoute(message: emptyPayloadMessage) else {
            Issue.record("Expected empty payload to route as invalid")
            return
        }
        guard case .invalidIncrementalRevisionPush = WatchIncomingMessageRoute(message: malformedDeletionMessage) else {
            Issue.record("Expected malformed typed deletion to route as invalid")
            return
        }
    }

    @Test("Incremental sync payload routes canonical outcome deletions")
    func incrementalSyncPayloadRoutesCanonicalOutcomeDeletions() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let documentID = "\(taskUUID.uuidString)_4"
        let message: [String: Any] = [
            OTFWatchConnectivityMessageKey.incrementalRevisionPush: [
                "deletions": [[
                    "documentID": documentID,
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue
                ]]
            ]
        ]

        guard case .incrementalRevisionPush(let payload) = WatchIncomingMessageRoute(message: message) else {
            Issue.record("Expected canonical typed deletion to route as incremental revision push")
            return
        }

        #expect(payload.deletions == [
            OTFWatchSyncDeletion(documentID: documentID, entityType: .outcome)
        ])
    }

    @Test("Routes database, live heart rate, legacy logout, and fallback messages")
    func routesDatabaseLiveHeartRateLegacyLogoutAndFallbackMessages() {
        let databaseMessage = [OTFWatchConnectivityMessageKey.databaseSynced: "done"]
        let liveMessage = WatchLiveHeartRateMessage.startRequest()
        let logoutMessage = ["userNotLoggedIn": "true"]
        let fallbackMessage = ["unhandled": "value"]

        guard case .databaseSynced = WatchIncomingMessageRoute(message: databaseMessage) else {
            Issue.record("Expected database synced route")
            return
        }
        guard case .liveHeartRateStart = WatchIncomingMessageRoute(message: liveMessage) else {
            Issue.record("Expected live heart rate route")
            return
        }
        guard case .legacyLogout = WatchIncomingMessageRoute(message: logoutMessage) else {
            Issue.record("Expected legacy logout route")
            return
        }
        guard case .peerFallback = WatchIncomingMessageRoute(message: fallbackMessage) else {
            Issue.record("Expected peer fallback route")
            return
        }
    }
}
