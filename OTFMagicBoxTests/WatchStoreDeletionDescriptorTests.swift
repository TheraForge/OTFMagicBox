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
import OTFCDTDatastore
import OTFCloudantStore
import OTFCareKitStore
@testable import OTFMagicBox

@Suite("Watch store deletion descriptors")
struct WatchStoreDeletionDescriptorTests {
    @Test("Task deletion descriptor uses task ID and task entity type")
    func taskDeletionDescriptorUsesTaskIDAndTaskEntityType() throws {
        let task = makeTask(
            id: "deleted-task",
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: nil
        )

        let descriptors = WatchStoreDeletionDescriptorBuilder.taskDeletionDescriptors(for: task)
        let descriptor = try #require(descriptors.only)

        #expect(descriptor.documentID == "deleted-task")
        #expect(descriptor.entityType == .task)
        #expect(descriptor.taskUUID == nil)
        #expect(descriptor.occurrenceIndex == nil)
    }

    @Test("Outcome deletion descriptors preserve document IDs and occurrence metadata")
    func outcomeDeletionDescriptorsPreserveDocumentIDsAndOccurrenceMetadata() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let outcome = OCKOutcome(
            taskUUID: taskUUID,
            taskOccurrenceIndex: 2,
            values: [OCKOutcomeValue(true)]
        )

        let descriptors = WatchStoreDeletionDescriptorBuilder.outcomeDeletionDescriptors(
            for: outcome,
            documentIDs: ["doc-a", "doc-b"]
        )

        #expect(descriptors == [
            OTFWatchSyncDeletion(
                documentID: "doc-a",
                entityType: .outcome,
                taskUUID: taskUUID,
                occurrenceIndex: 2
            ),
            OTFWatchSyncDeletion(
                documentID: "doc-b",
                entityType: .outcome,
                taskUUID: taskUUID,
                occurrenceIndex: 2
            )
        ])
    }

    @Test("Outcome deletion descriptors preserve empty Cloudant lookup results")
    func outcomeDeletionDescriptorsPreserveEmptyCloudantLookupResults() {
        let outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )

        let descriptors = WatchStoreDeletionDescriptorBuilder.outcomeDeletionDescriptors(
            for: outcome,
            documentIDs: []
        )

        #expect(descriptors.isEmpty)
    }

    @Test("Typed task document ID matches Cloudant revision fallback behavior")
    func typedTaskDocumentIDMatchesCloudantRevisionFallbackBehavior() {
        let task = makeTask(
            id: "task-doc-id",
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: nil
        )
        let expected = CDTDocumentRevision.revision(fromEntity: task).docId ?? (task as OCKAnyTask).id

        #expect(WatchStoreDeletionDescriptorBuilder.documentID(for: task) == expected)
    }

    @Test("Typed outcome document ID matches Cloudant revision fallback behavior")
    func typedOutcomeDocumentIDMatchesCloudantRevisionFallbackBehavior() {
        let outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 1,
            values: [OCKOutcomeValue(true)]
        )
        let expected = CDTDocumentRevision.revision(fromEntity: outcome).docId ?? (outcome as OCKAnyOutcome).id

        #expect(WatchStoreDeletionDescriptorBuilder.documentID(for: outcome) == expected)
    }
}

private extension Array {
    var only: Element? {
        count == 1 ? self[0] : nil
    }
}
