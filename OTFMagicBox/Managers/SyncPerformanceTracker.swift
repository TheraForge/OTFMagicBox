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
import OTFUtilities

final class SyncPerformanceTracker {

    static let shared = SyncPerformanceTracker()

    private let logger = OTFLogger.logger()
    private let lock = NSLock()
    private var counters = [String: Int]()
    private let verboseLoggingEnabled = ProcessInfo.processInfo.environment["OTF_SYNC_VERBOSE_LOGS"] == "1"

    private init() {}

    func increment(_ key: String, by value: Int = 1) {
        lock.lock()
        counters[key, default: 0] += value
        lock.unlock()
    }

    func recordScheduleLoad(date: Date, fetchedTasks: Int, fromCache: Bool) {
        increment("schedule.loads")
        increment("schedule.tasks.fetched", by: fetchedTasks)
        if fromCache {
            increment("schedule.cache.hits")
        } else {
            increment("schedule.cache.misses")
        }
        guard verboseLoggingEnabled else { return }
        logger.info("SyncPerformanceTracker: iOS schedule \(date.formatted(date: .abbreviated, time: .omitted)) tasks=\(fetchedTasks) cache=\(fromCache)")
    }

    func recordWatchScheduleLoad(date: Date, fetchedTasks: Int, fromCache: Bool) {
        increment("watch.schedule.loads")
        increment("watch.schedule.tasks.fetched", by: fetchedTasks)
        if fromCache {
            increment("watch.schedule.cache.hits")
        } else {
            increment("watch.schedule.cache.misses")
            increment("watch.schedule.fetches")
        }
        guard verboseLoggingEnabled else { return }
        logger.info("SyncPerformanceTracker: watch schedule \(date.formatted(date: .abbreviated, time: .omitted)) tasks=\(fetchedTasks) cache=\(fromCache)")
    }

    func recordWatchPayload(direction: String, tasks: Int, outcomes: Int, deletions: Int) {
        increment("watch.payloads.\(direction)")
        increment("watch.tasks.\(direction)", by: tasks)
        increment("watch.outcomes.\(direction)", by: outcomes)
        increment("watch.deletions.\(direction)", by: deletions)
    }

    func recordSyncTrigger(source: String) {
        increment("cloudant.sync.triggers")
        increment("cloudant.sync.triggers.\(source)")
    }

    func recordTombstone404(count: Int = 1) {
        increment("cloudant.pull.tombstone404", by: count)
    }

    func recordOutcomeMaintenance(prunedOrMigrated count: Int) {
        guard count > 0 else { return }
        increment("cloudant.maintenance.outcomes.cleaned", by: count)
    }

    func logSummary(context: String) {
        guard verboseLoggingEnabled else { return }

        lock.lock()
        let snapshot = counters
        lock.unlock()

        guard !snapshot.isEmpty else { return }

        let formattedSnapshot = snapshot
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        logger.info("SyncPerformanceTracker: \(context) \(formattedSnapshot)")
    }
}
