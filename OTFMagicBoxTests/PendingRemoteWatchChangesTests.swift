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

@Suite("Pending remote watch changes")
struct PendingRemoteWatchChangesTests {
    @Test("Pending Remote Watch Changes Keeps Changes Until Acknowledged")
    func pendingRemoteWatchChangesKeepsChangesUntilAcknowledged() {
        let pendingChanges = PendingRemoteWatchChanges()

        pendingChanges.record(
            changedDocumentIDs: ["changed-1"],
            deletedDocumentIDs: ["deleted-1"]
        )

        let snapshot = pendingChanges.snapshot()

        #expect(!(snapshot.isEmpty))
        #expect(Set(snapshot.changedDocumentIDs) == ["changed-1"])
        #expect(Set(snapshot.deletedDocumentIDs) == ["deleted-1"])

        let stillPending = pendingChanges.snapshot()
        #expect(Set(stillPending.changedDocumentIDs) == ["changed-1"])
        #expect(Set(stillPending.deletedDocumentIDs) == ["deleted-1"])

        pendingChanges.acknowledge(snapshot)

        #expect(pendingChanges.snapshot().isEmpty)
        #expect(!(pendingChanges.hasPendingChanges))
    }

    @Test("Pending Remote Watch Changes Acknowledges Only Sent Snapshot")
    func pendingRemoteWatchChangesAcknowledgesOnlySentSnapshot() {
        let pendingChanges = PendingRemoteWatchChanges()

        pendingChanges.record(
            changedDocumentIDs: ["changed-1"],
            deletedDocumentIDs: ["deleted-1"]
        )
        let sentSnapshot = pendingChanges.snapshot()

        pendingChanges.record(
            changedDocumentIDs: ["changed-2"],
            deletedDocumentIDs: ["deleted-2"]
        )

        pendingChanges.acknowledge(sentSnapshot)

        let remaining = pendingChanges.snapshot()
        #expect(Set(remaining.changedDocumentIDs) == ["changed-2"])
        #expect(Set(remaining.deletedDocumentIDs) == ["deleted-2"])
        #expect(pendingChanges.hasPendingChanges)
    }

    @Test("Pending Remote Watch Changes Keeps Changed ID Recorded Again After Snapshot")
    func pendingRemoteWatchChangesKeepsChangedIDRecordedAgainAfterSnapshot() {
        let pendingChanges = PendingRemoteWatchChanges()
        pendingChanges.record(changedDocumentIDs: ["changed-1"], deletedDocumentIDs: [])
        let sentSnapshot = pendingChanges.snapshot()

        pendingChanges.record(changedDocumentIDs: ["changed-1"], deletedDocumentIDs: [])
        pendingChanges.acknowledge(sentSnapshot)

        let remaining = pendingChanges.snapshot()
        #expect(Set(remaining.changedDocumentIDs) == ["changed-1"])
        #expect(remaining.deletedDocumentIDs.isEmpty)
        #expect(pendingChanges.hasPendingChanges)
    }

    @Test("Pending Remote Watch Changes Keeps Deleted ID Recorded Again After Snapshot")
    func pendingRemoteWatchChangesKeepsDeletedIDRecordedAgainAfterSnapshot() {
        let pendingChanges = PendingRemoteWatchChanges()
        pendingChanges.record(changedDocumentIDs: [], deletedDocumentIDs: ["deleted-1"])
        let sentSnapshot = pendingChanges.snapshot()

        pendingChanges.record(changedDocumentIDs: [], deletedDocumentIDs: ["deleted-1"])
        pendingChanges.acknowledge(sentSnapshot)

        let remaining = pendingChanges.snapshot()
        #expect(remaining.changedDocumentIDs.isEmpty)
        #expect(Set(remaining.deletedDocumentIDs) == ["deleted-1"])
        #expect(pendingChanges.hasPendingChanges)
    }

    @Test("Pending Remote Watch Changes Retains Typed Deletion Descriptors")
    func pendingRemoteWatchChangesRetainsTypedDeletionDescriptors() {
        let pendingChanges = PendingRemoteWatchChanges()
        let deletion = OTFWatchSyncDeletion(documentID: "deleted-task", entityType: .task)

        pendingChanges.record(
            changedDocumentIDs: [],
            deletedDocumentIDs: ["deleted-task", "unknown"],
            typedDeletions: [deletion]
        )

        let snapshot = pendingChanges.snapshot()

        #expect(snapshot.typedDeletions == [deletion])
        #expect(Set(snapshot.deletedDocumentIDs) == ["deleted-task", "unknown"])
    }

    @Test("Pending Remote Watch Changes Acknowledges Typed Deletion With Deleted ID")
    func pendingRemoteWatchChangesAcknowledgesTypedDeletionWithDeletedID() {
        let pendingChanges = PendingRemoteWatchChanges()
        let deletion = OTFWatchSyncDeletion(documentID: "deleted-task", entityType: .task)
        pendingChanges.record(
            changedDocumentIDs: [],
            deletedDocumentIDs: ["deleted-task"],
            typedDeletions: [deletion]
        )
        let sentSnapshot = pendingChanges.snapshot()

        pendingChanges.acknowledge(sentSnapshot)

        #expect(pendingChanges.snapshot().typedDeletions.isEmpty)
        #expect(!(pendingChanges.hasPendingChanges))
    }

    @Test("Pending Remote Watch Changes Targeted Deletion Snapshot Does Not Include Other Pending State")
    func pendingRemoteWatchChangesTargetedDeletionSnapshotDoesNotIncludeOtherPendingState() {
        let pendingChanges = PendingRemoteWatchChanges()
        let requestedDeletion = OTFWatchSyncDeletion(documentID: "deleted-b", entityType: .task)
        pendingChanges.record(
            changedDocumentIDs: ["changed-1"],
            deletedDocumentIDs: ["deleted-c", "deleted-a", "deleted-b"],
            typedDeletions: [requestedDeletion]
        )

        let snapshot = pendingChanges.snapshot(deletedDocumentIDs: ["deleted-b", "missing"])

        #expect(snapshot.changedDocumentIDs.isEmpty)
        #expect(snapshot.deletedDocumentIDs == ["deleted-b"])
        #expect(snapshot.typedDeletions == [requestedDeletion])
    }

    @Test("Pending Remote Watch Changes Targeted Acknowledge Leaves Unsent Changes")
    func pendingRemoteWatchChangesTargetedAcknowledgeLeavesUnsentChanges() {
        let pendingChanges = PendingRemoteWatchChanges()
        let acknowledgedDeletion = OTFWatchSyncDeletion(documentID: "deleted-1", entityType: .task)
        let retainedDeletion = OTFWatchSyncDeletion(documentID: "deleted-2", entityType: .task)
        pendingChanges.record(
            changedDocumentIDs: ["changed-1"],
            deletedDocumentIDs: ["deleted-1", "deleted-2"],
            typedDeletions: [acknowledgedDeletion, retainedDeletion]
        )

        let targetedSnapshot = pendingChanges.snapshot(deletedDocumentIDs: ["deleted-1"])
        pendingChanges.acknowledge(targetedSnapshot)

        let remaining = pendingChanges.snapshot()
        #expect(remaining.changedDocumentIDs == ["changed-1"])
        #expect(remaining.deletedDocumentIDs == ["deleted-2"])
        #expect(remaining.typedDeletions == [retainedDeletion])
        #expect(pendingChanges.hasPendingChanges)
    }

    @Test("Pending Remote Watch Changes Ignores Typed Descriptor Without Matching Deleted ID")
    func pendingRemoteWatchChangesIgnoresTypedDescriptorWithoutMatchingDeletedID() {
        let pendingChanges = PendingRemoteWatchChanges()
        pendingChanges.record(
            changedDocumentIDs: [],
            deletedDocumentIDs: ["deleted-1"],
            typedDeletions: [OTFWatchSyncDeletion(documentID: "other-deleted", entityType: .task)]
        )

        let snapshot = pendingChanges.snapshot()

        #expect(snapshot.deletedDocumentIDs == ["deleted-1"])
        #expect(snapshot.typedDeletions.isEmpty)
    }

    @Test("Pending Remote Watch Changes Discard All Clears Changed And Deleted I Ds")
    func pendingRemoteWatchChangesDiscardAllClearsChangedAndDeletedIDs() {
        let pendingChanges = PendingRemoteWatchChanges()

        pendingChanges.record(
            changedDocumentIDs: ["changed-1", "changed-2"],
            deletedDocumentIDs: ["deleted-1", "deleted-2"]
        )

        pendingChanges.discardAll()

        #expect(pendingChanges.snapshot().isEmpty)
        #expect(!(pendingChanges.hasPendingChanges))
    }
}
