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

@Suite("Outcome conflict resolver")
struct OutcomeConflictResolverTests {
    @Test("Outcome Conflict Resolver Prefers Newer Tombstone Generation When Timestamp Is Missing")
    func outcomeConflictResolverPrefersNewerTombstoneGenerationWhenTimestampIsMissing() {
        let active = makeRevision(
            revId: "2-active",
            body: ["updatedDate": "2026-01-01T12:00:00Z"],
            deleted: false
        )
        let deleted = makeRevision(
            revId: "3-deleted",
            body: nil,
            deleted: true
        )

        let winner = OutcomeConflictResolver().resolve("outcome-1", conflicts: [active, deleted])

        #expect(winner?.revId == "3-deleted")
        #expect(winner?.deleted == true)
    }

    @Test("Outcome Conflict Resolver Prefers Newest Timestamp When Both Revisions Have Dates")
    func outcomeConflictResolverPrefersNewestTimestampWhenBothRevisionsHaveDates() {
        let olderActive = makeRevision(
            revId: "4-older",
            body: ["updatedDate": "2026-01-01T12:00:00Z"],
            deleted: false
        )
        let newerActive = makeRevision(
            revId: "3-active",
            body: ["updatedDate": "2026-01-01T12:05:00Z"],
            deleted: false
        )

        let winner = OutcomeConflictResolver().resolve("outcome-1", conflicts: [olderActive, newerActive])

        #expect(winner?.revId == "3-active")
        #expect(winner?.deleted == false)
    }

    @Test("Outcome Conflict Resolver Uses Stable Tie Breaker And Prefers Deletion")
    func outcomeConflictResolverUsesStableTieBreakerAndPrefersDeletion() {
        let active = makeRevision(
            revId: "3-active",
            body: ["updatedDate": "2026-01-01T12:00:00Z"],
            deleted: false
        )
        let deleted = makeRevision(
            revId: "3-deleted",
            body: nil,
            deleted: true
        )

        let winner = OutcomeConflictResolver().resolve("outcome-1", conflicts: [active, deleted])

        #expect(winner?.revId == "3-deleted")
        #expect(winner?.deleted == true)
    }
}
