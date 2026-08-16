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
import OTFCDTDatastore
import OTFUtilities

/// Resolves document conflicts using a Last-Writer-Wins (LWW) strategy.
///
/// When conflicts occur during Cloudant replication (e.g., a document was modified on
/// multiple devices before syncing), this resolver selects the winning revision based
/// on the document's timestamp.
///
/// ## Strategy
/// The most recent revision wins, regardless of whether it's deleted or not.
/// When one side is a tombstone without body timestamps, the resolver falls back to the
/// Cloudant revision generation so a newer uncheck does not resurrect an older outcome.
///
/// ## Timestamp Extraction
/// Timestamps are extracted from the document body in the following order:
/// 1. `deletedDate` as ISO8601 string or Unix timestamp
/// 2. `updatedDate` as ISO8601 string or Unix timestamp
/// 3. `createdDate` as ISO8601 string or Unix timestamp
/// 4. Revision generation when a comparable timestamp is missing
/// 5. Stable deleted/revision ID tie-breakers
class OutcomeConflictResolver: NSObject, CDTConflictResolver {

    private let logger = OTFLogger.logger()

    /// Lazy-loaded ISO8601 date formatter (thread-safe by default in iOS 7+).
    private lazy var iso8601Formatter = ISO8601DateFormatter()

    // MARK: - CDTConflictResolver

    func resolve(_ docId: String, conflicts: [CDTDocumentRevision]) -> CDTDocumentRevision? {
        logger.info("OutcomeConflictResolver: Resolving \(conflicts.count) conflicts for doc: \(docId)")

        let sorted = conflicts.sorted { isPreferred($0, over: $1) }

        guard let winner = sorted.first else {
            logger.info("OutcomeConflictResolver: No conflicts to resolve, returning first")
            return conflicts.first
        }

        let deletedStatus = winner.deleted ? "deleted" : "active"
        let winnerDate = extractDate(from: winner)
        let winnerDateDescription = winnerDate.map { "\($0)" } ?? "nil"
        logger.info("OutcomeConflictResolver: Winner is \(deletedStatus) revision \(winner.revId ?? "nil") with date \(winnerDateDescription)")

        return winner
    }

    // MARK: - Private Methods

    private func isPreferred(_ candidate: CDTDocumentRevision, over existing: CDTDocumentRevision) -> Bool {
        let candidateDate = extractDate(from: candidate)
        let existingDate = extractDate(from: existing)

        if let candidateDate, let existingDate, candidateDate != existingDate {
            return candidateDate > existingDate
        }

        let candidateGeneration = revisionGeneration(candidate.revId)
        let existingGeneration = revisionGeneration(existing.revId)
        if candidateGeneration != existingGeneration {
            return candidateGeneration > existingGeneration
        }

        if candidate.deleted != existing.deleted {
            return candidate.deleted
        }

        if candidateDate != existingDate {
            return (candidateDate ?? .distantPast) > (existingDate ?? .distantPast)
        }

        return (candidate.revId ?? "") > (existing.revId ?? "")
    }

    private func revisionGeneration(_ revId: String?) -> Int {
        guard let revId,
              let generation = Int(revId.split(separator: "-", maxSplits: 1).first ?? "") else {
            return 0
        }
        return generation
    }

    /// Extracts the most recent date from a document revision's body.
    private func extractDate(from revision: CDTDocumentRevision) -> Date? {
        guard let body = revision.body as? [String: Any] else {
            return nil
        }

        for key in ["deletedDate", "updatedDate", "createdDate"] {
            if let date = dateValue(body[key]) {
                return date
            }
        }

        return nil
    }

    private func dateValue(_ value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }

        if let dateString = value as? String {
            return iso8601Formatter.date(from: dateString)
        }

        if let timestamp = value as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }

        return nil
    }
}
