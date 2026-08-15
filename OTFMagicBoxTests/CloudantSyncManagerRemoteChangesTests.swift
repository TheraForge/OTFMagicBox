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

@Suite("Cloudant sync manager remote changes", .serialized)
struct CloudantSyncManagerRemoteChangesTests {
    @Test("Remote Schedule Refresh Pending State Is Consumed Without Clearing Watch Pending State")
    func remoteScheduleRefreshPendingStateIsConsumedWithoutClearingWatchPendingState() {
        let manager = CloudantSyncManager.shared
        manager.discardPendingRemoteChangesForTesting()
        defer { manager.discardPendingRemoteChangesForTesting() }

        manager.recordPendingRemoteChangesForTesting(
            changedDocumentIDs: ["changed-1"],
            deletedDocumentIDs: []
        )

        let firstDecision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )

        #expect(firstDecision.shouldNotifyRemotePull)
        #expect(firstDecision.refreshContext?.changeKind == .fullResync)
        #expect(manager.pendingRemoteScheduleRefreshChangeIDsForTesting().changedDocumentIDs.isEmpty)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().changedDocumentIDs == ["changed-1"])

        let secondDecision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )

        #expect(!(secondDecision.shouldNotifyRemotePull))
        #expect((secondDecision.refreshContext) == nil)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().changedDocumentIDs == ["changed-1"])
    }

    @Test("Remote Deletion Schedule Refresh Can Be Consumed While Watch Deletion Remains Pending")
    func remoteDeletionScheduleRefreshCanBeConsumedWhileWatchDeletionRemainsPending() {
        let manager = CloudantSyncManager.shared
        manager.discardPendingRemoteChangesForTesting()
        defer { manager.discardPendingRemoteChangesForTesting() }

        manager.recordPendingRemoteChangesForTesting(
            changedDocumentIDs: [],
            deletedDocumentIDs: ["deleted-outcome"]
        )

        manager.consumePendingRemoteScheduleRefreshDeletionForTesting(["deleted-outcome"])

        #expect(manager.pendingRemoteScheduleRefreshChangeIDsForTesting().deletedDocumentIDs.isEmpty)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().deletedDocumentIDs == ["deleted-outcome"])

        let nextDecision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )

        #expect(!(nextDecision.shouldNotifyRemotePull))
        #expect((nextDecision.refreshContext) == nil)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().deletedDocumentIDs == ["deleted-outcome"])
    }

    @Test("Remote Outcome Change Creates Targeted Schedule Refresh Context")
    func remoteOutcomeChangeCreatesTargetedScheduleRefreshContext() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let manager = CloudantSyncManager.shared
        let originalStore = manager.cloudantStore
        manager.discardPendingRemoteChangesForTesting()
        manager.cloudantStore = store
        defer {
            manager.cloudantStore = originalStore
            manager.discardPendingRemoteChangesForTesting()
        }

        let effectiveDate = Date(timeIntervalSince1970: 1_800_200_000)
        var outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )
        outcome.effectiveDate = effectiveDate
        let revision = CDTDocumentRevision.revision(fromEntity: outcome)
        let documentID = try #require(revision.docId)
        try store.dataStore.createDocument(from: revision)

        manager.recordPendingRemoteChangesForTesting(
            changedDocumentIDs: [documentID],
            deletedDocumentIDs: []
        )

        let decision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )
        let context = try #require(decision.refreshContext)

        #expect(decision.shouldNotifyRemotePull)
        #expect(context.changeKind == .outcomeOnly)
        #expect(context.affectedDates == [Calendar.current.startOfDay(for: effectiveDate)])
        #expect(manager.pendingRemoteScheduleRefreshChangeIDsForTesting().changedDocumentIDs.isEmpty)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().changedDocumentIDs == [documentID])
    }

    @Test("Remote Task Change Falls Back To Full Schedule Refresh Without Clearing Watch Pending State")
    func remoteTaskChangeFallsBackToFullScheduleRefreshWithoutClearingWatchPendingState() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let manager = CloudantSyncManager.shared
        let originalStore = manager.cloudantStore
        manager.discardPendingRemoteChangesForTesting()
        manager.cloudantStore = store
        defer {
            manager.cloudantStore = originalStore
            manager.discardPendingRemoteChangesForTesting()
        }

        let taskID = "remote-changed-task"
        let task = makeTask(
            id: taskID,
            start: Date(timeIntervalSince1970: 1_800_500_000),
            end: nil
        )
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))

        manager.recordPendingRemoteChangesForTesting(
            changedDocumentIDs: [taskID],
            deletedDocumentIDs: []
        )

        let decision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )

        #expect(decision.shouldNotifyRemotePull)
        #expect(decision.refreshContext?.changeKind == .fullResync)
        #expect(manager.pendingRemoteScheduleRefreshChangeIDsForTesting().changedDocumentIDs.isEmpty)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().changedDocumentIDs == [taskID])
    }

    @Test("Remote Canonical Outcome Deletion Creates Targeted Schedule Refresh Context")
    func remoteCanonicalOutcomeDeletionCreatesTargetedScheduleRefreshContext() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let manager = CloudantSyncManager.shared
        let originalStore = manager.cloudantStore
        manager.discardPendingRemoteChangesForTesting()
        manager.cloudantStore = store
        defer {
            manager.cloudantStore = originalStore
            manager.discardPendingRemoteChangesForTesting()
        }

        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let taskStart = Date(timeIntervalSince1970: 1_800_300_000)
        var task = makeTask(id: "task-for-deleted-outcome", start: taskStart, end: nil)
        task.uuid = taskUUID
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))
        let deletedOutcomeDocumentID = "\(taskUUID.uuidString)_0"

        manager.recordPendingRemoteChangesForTesting(
            changedDocumentIDs: [],
            deletedDocumentIDs: [deletedOutcomeDocumentID]
        )

        let decision = manager.consumeRemotePullScheduleRefreshForTesting(
            didChangeLocalData: false,
            changedScheduleContent: false
        )
        let context = try #require(decision.refreshContext)

        #expect(!(decision.shouldNotifyRemotePull))
        #expect(context.changeKind == .outcomeOnly)
        #expect(context.affectedDates == [Calendar.current.startOfDay(for: taskStart)])
        #expect(manager.pendingRemoteScheduleRefreshChangeIDsForTesting().deletedDocumentIDs.isEmpty)
        #expect(manager.pendingRemoteWatchChangeIDsForTesting().deletedDocumentIDs == [deletedOutcomeDocumentID])
    }

    @Test("Remote Payload Builder Preserves Deletion Payload Without Store")
    func remotePayloadBuilderPreservesDeletionPayloadWithoutStore() throws {
        let taskDeletion = OTFWatchSyncDeletion(documentID: "task-deleted", entityType: .task)
        let payload = try CloudantSyncManager.shared.makeWatchPayloadForRemoteChanges(
            changedDocumentIDs: ["missing-change"],
            deletedDocumentIDs: ["task-deleted", "legacy-deleted"],
            typedDeletions: [taskDeletion],
            using: nil
        )

        #expect(payload.tasks.isEmpty)
        #expect(payload.outcomes.isEmpty)
        #expect(payload.deletions == [taskDeletion])
        #expect(payload.legacyDeletedDocumentIDs == ["legacy-deleted"])
        #expect(Set(payload.deletedDocumentIDs) == ["task-deleted", "legacy-deleted"])
    }

    @Test("Remote Payload Builder Includes Changed Tasks And Outcomes From Store")
    func remotePayloadBuilderIncludesChangedTasksAndOutcomesFromStore() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let taskID = "changed-task"
        let task = makeTask(
            id: taskID,
            start: Date(timeIntervalSince1970: 1_800_600_000),
            end: nil
        )
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))

        var outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(12)]
        )
        outcome.effectiveDate = Date(timeIntervalSince1970: 1_800_600_000)
        let outcomeRevision = CDTDocumentRevision.revision(fromEntity: outcome)
        let outcomeDocumentID = try #require(outcomeRevision.docId)
        try store.dataStore.createDocument(from: outcomeRevision)

        let payload = try CloudantSyncManager.shared.makeWatchPayloadForRemoteChanges(
            changedDocumentIDs: [taskID, outcomeDocumentID, "missing-document"],
            deletedDocumentIDs: [],
            using: store
        )

        #expect(payload.tasks.count == 1)
        #expect(payload.outcomes.count == 1)
        let decodedTask = try JSONDecoder().decode(OCKTask.self, from: try #require(payload.tasks.first))
        let decodedOutcome = try JSONDecoder().decode(OCKOutcome.self, from: try #require(payload.outcomes.first))

        #expect((decodedTask as OCKAnyTask).id == taskID)
        #expect(decodedTask.title == taskID)
        #expect(decodedTask.uuid == task.uuid)
        #expect(decodedOutcome.taskUUID == task.uuid)
        #expect(decodedOutcome.taskOccurrenceIndex == 0)
        #expect(decodedOutcome.effectiveDate == outcome.effectiveDate)
        #expect(decodedOutcome.values.first?.integerValue == 12)
        #expect(payload.deletions.isEmpty)
        #expect(payload.legacyDeletedDocumentIDs.isEmpty)
    }

    @Test("Remote Payload Builder Keeps Typed Deletions Out Of Legacy Deleted IDs")
    func remotePayloadBuilderKeepsTypedDeletionsOutOfLegacyDeletedIDs() throws {
        let typedDeletion = OTFWatchSyncDeletion(documentID: "typed-task", entityType: .task)

        let payload = try CloudantSyncManager.shared.makeWatchPayloadForRemoteChanges(
            changedDocumentIDs: [],
            deletedDocumentIDs: ["typed-task", "legacy-only"],
            typedDeletions: [typedDeletion],
            using: nil
        )

        #expect(payload.deletions == [typedDeletion])
        #expect(payload.legacyDeletedDocumentIDs == ["legacy-only"])
        #expect(Set(payload.deletedDocumentIDs) == ["typed-task", "legacy-only"])
    }

    @Test("Remote Deleted I Ds Produce Typed Outcome And Task Deletions With Unknown Legacy Fallback")
    func remoteDeletedIDsProduceTypedOutcomeAndTaskDeletionsWithUnknownLegacyFallback() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store

        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let outcomeDocumentID = "\(taskUUID.uuidString)_2"
        let taskDocumentID = "deleted-task"
        let unknownDocumentID = "unknown-deletion"
        let task = makeTask(
            id: taskDocumentID,
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: nil
        )
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))

        let typedDeletions = CloudantSyncManager.shared.remoteDeletionDescriptors(
            for: [outcomeDocumentID, taskDocumentID, unknownDocumentID],
            using: store
        )
        let payload = try CloudantSyncManager.shared.makeWatchPayloadForRemoteChanges(
            changedDocumentIDs: [],
            deletedDocumentIDs: [outcomeDocumentID, taskDocumentID, unknownDocumentID],
            typedDeletions: typedDeletions,
            using: store
        )

        #expect(payload.deletions.count == 2)
        #expect(payload.deletions.contains(
            OTFWatchSyncDeletion(
                documentID: outcomeDocumentID,
                entityType: .outcome,
                taskUUID: taskUUID,
                occurrenceIndex: 2
            )
        ))
        #expect(payload.deletions.contains(
            OTFWatchSyncDeletion(documentID: taskDocumentID, entityType: .task)
        ))
        #expect(payload.legacyDeletedDocumentIDs == [unknownDocumentID])
        #expect(Set(payload.deletedDocumentIDs) == [outcomeDocumentID, taskDocumentID, unknownDocumentID])
    }
}
