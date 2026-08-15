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

@Suite("Watch sync payload")
struct WatchSyncPayloadTests {
    @Test("Watch sync payload treats empty messages as invalid")
    func watchSyncPayloadTreatsEmptyMessagesAsInvalid() {
        let payload = OTFWatchSyncPayload()

        #expect(payload.isEmpty)
        #expect(OTFWatchSyncPayload(message: payload.message) == nil)
        #expect(OTFWatchSyncPayload(message: [:]) == nil)
    }

    @Test("Watch sync payload round trips typed and legacy deletions")
    func watchSyncPayloadRoundTripsTypedAndLegacyDeletions() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let outcomeDeletion = OTFWatchSyncDeletion(
            documentID: "\(taskUUID.uuidString)_2",
            entityType: .outcome,
            taskUUID: taskUUID,
            occurrenceIndex: 2
        )
        let taskDeletion = OTFWatchSyncDeletion(documentID: "task-deleted", entityType: .task)
        let payload = OTFWatchSyncPayload(
            deletions: [outcomeDeletion, taskDeletion],
            deletedDocumentIDs: ["legacy-deleted"]
        )

        let decodedPayload = try #require(OTFWatchSyncPayload(message: payload.message))

        #expect(decodedPayload.deletions.contains(outcomeDeletion))
        #expect(decodedPayload.deletions.contains(taskDeletion))
        #expect(decodedPayload.legacyDeletedDocumentIDs == ["legacy-deleted"])
        #expect(Set(decodedPayload.deletedDocumentIDs) == [
            outcomeDeletion.documentID,
            taskDeletion.documentID,
            "legacy-deleted"
        ])
    }

    @Test("Watch sync payload preserves explicit legacy deletion IDs")
    func watchSyncPayloadPreservesExplicitLegacyDeletionIDs() throws {
        let deletion = OTFWatchSyncDeletion(documentID: "task-deleted", entityType: .task)
        let payload = OTFWatchSyncPayload(
            deletions: [deletion],
            deletedDocumentIDs: [deletion.documentID, "legacy-deleted"]
        )

        let decodedPayload = try #require(OTFWatchSyncPayload(message: payload.message))

        #expect(decodedPayload.deletions == [deletion])
        #expect(decodedPayload.legacyDeletedDocumentIDs == [deletion.documentID, "legacy-deleted"])
        #expect(Set(decodedPayload.deletedDocumentIDs) == [deletion.documentID, "legacy-deleted"])
    }

    @Test("Watch sync payload accepts canonical outcome deletion IDs without explicit metadata")
    func watchSyncPayloadAcceptsCanonicalOutcomeDeletionIDsWithoutExplicitMetadata() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let documentID = "\(taskUUID.uuidString)_3"
        let message: [String: Any] = [
            "deletions": [[
                "documentID": documentID,
                "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue
            ]]
        ]

        let payload = try #require(OTFWatchSyncPayload(message: message))

        #expect(payload.deletions == [
            OTFWatchSyncDeletion(documentID: documentID, entityType: .outcome)
        ])
        #expect(payload.deletedDocumentIDs == [documentID])
    }

    @Test("Watch sync payload rejects malformed typed deletions")
    func watchSyncPayloadRejectsMalformedTypedDeletions() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let canonicalOutcomeID = "\(taskUUID.uuidString)_3"
        let invalidMessages: [[String: Any]] = [
            [
                "deletions": [[
                    "documentID": "not-canonical",
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue
                ]]
            ],
            [
                "deletions": [[
                    "documentID": canonicalOutcomeID,
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue,
                    "taskUUID": taskUUID.uuidString
                ]]
            ],
            [
                "deletions": [[
                    "documentID": canonicalOutcomeID,
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue,
                    "occurrenceIndex": 3
                ]]
            ],
            [
                "deletions": [[
                    "documentID": canonicalOutcomeID,
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue,
                    "taskUUID": "not-a-uuid",
                    "occurrenceIndex": 3
                ]]
            ],
            [
                "deletions": [[
                    "documentID": canonicalOutcomeID,
                    "entityType": OTFWatchSyncDeletion.EntityType.outcome.rawValue,
                    "taskUUID": taskUUID.uuidString,
                    "occurrenceIndex": "3"
                ]]
            ]
        ]

        for message in invalidMessages {
            #expect(OTFWatchSyncPayload(message: message) == nil)
        }
    }
}
