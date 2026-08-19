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
@preconcurrency import OTFCareKitStore
@testable import OTFMagicBox

@Suite("CareKit day snapshot store")
struct CareKitDaySnapshotStoreTests {
    @Test("Task snapshots are cached until force refresh")
    func taskSnapshotsAreCachedUntilForceRefresh() async throws {
        var taskFetchCount = 0
        let firstTask = makeCategorizedTask(id: "first", category: .medication)
        let refreshedTask = makeCategorizedTask(id: "refreshed", category: .activity)
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { _, callbackQueue, completion in
                taskFetchCount += 1
                let tasks = taskFetchCount == 1 ? [firstTask] : [refreshedTask]
                callbackQueue.async { completion(.success(tasks)) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        let firstSnapshot = try await taskSnapshot(from: store, for: snapshotDay)
        let cachedSnapshot = try await taskSnapshot(from: store, for: snapshotDay)
        let forcedSnapshot = try await taskSnapshot(from: store, for: snapshotDay, forceRefresh: true)

        #expect(firstSnapshot.tasks.map(\.id) == ["first"])
        #expect(cachedSnapshot.tasks.map(\.id) == ["first"])
        #expect(forcedSnapshot.tasks.map(\.id) == ["refreshed"])
        #expect(taskFetchCount == 2)
    }

    @Test("Concurrent task snapshot requests share one fetch")
    func concurrentTaskSnapshotRequestsShareOneFetch() async throws {
        var taskFetchCount = 0
        var capturedCompletion: ((Result<[OCKTask], OCKStoreError>) -> Void)?
        let recorder = SnapshotResultRecorder<DayTaskSnapshot>()
        let task = makeCategorizedTask(id: "coalesced", category: .medication)
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { _, _, completion in
                taskFetchCount += 1
                capturedCompletion = completion
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        store.snapshot(for: snapshotDay) { result in
            Task { await recorder.append(result) }
        }
        store.snapshot(for: snapshotDay) { result in
            Task { await recorder.append(result) }
        }

        #expect(taskFetchCount == 1)
        let completion = try #require(capturedCompletion)
        completion(.success([task]))

        try await waitForResults(recorder, count: 2)
        let snapshots = try await recorder.successes()

        #expect(snapshots.count == 2)
        #expect(snapshots.allSatisfy { $0.tasks.map(\.id) == ["coalesced"] })
    }

    @Test("Task snapshots exclude bounded schedules without an event on the requested day")
    func taskSnapshotsExcludeBoundedSchedulesWithoutAnEventOnRequestedDay() async throws {
        let calendar = Calendar.current
        let scheduleStart = calendar.startOfDay(for: snapshotDay).addingTimeInterval(9 * 60 * 60)
        let requestedDay = try #require(
            calendar.date(byAdding: .day, value: 1, to: scheduleStart)
        )
        let scheduleEnd = try #require(
            calendar.date(byAdding: .day, value: 14, to: scheduleStart)
        )
        let sparseSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: scheduleStart,
                end: scheduleEnd,
                interval: DateComponents(weekOfYear: 1),
                duration: .hours(1)
            )
        ])
        let sparseTask = OCKTask(
            id: "weekly-task",
            title: "Weekly task",
            carePlanUUID: nil,
            schedule: sparseSchedule
        )
        let store = CareKitDaySnapshotStore(
            calendar: calendar,
            taskFetcher: { _, callbackQueue, completion in
                callbackQueue.async { completion(.success([sparseTask])) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        let snapshot = try await taskSnapshot(from: store, for: requestedDay)

        #expect(sparseTask.schedule.exists(onDay: requestedDay))
        #expect(snapshot.tasks.isEmpty)
    }

    @Test("Task snapshots include an event starting at the final second of the requested day")
    func taskSnapshotsIncludeEventAtFinalSecondOfRequestedDay() async throws {
        let requestedDay = fixedSnapshotCalendar.startOfDay(for: snapshotDay)
        let startOfNextDay = try #require(
            fixedSnapshotCalendar.date(byAdding: .day, value: 1, to: requestedDay)
        )
        let finalSecond = startOfNextDay.addingTimeInterval(-1)
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: finalSecond,
                end: startOfNextDay,
                interval: DateComponents(day: 1),
                duration: .minutes(1)
            )
        ])
        let task = OCKTask(
            id: "final-second-task",
            title: "Final second task",
            carePlanUUID: nil,
            schedule: schedule
        )
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { _, callbackQueue, completion in
                callbackQueue.async { completion(.success([task])) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        let snapshot = try await taskSnapshot(from: store, for: requestedDay)

        #expect(task.hasScheduledEvents(onDay: requestedDay, calendar: fixedSnapshotCalendar))
        #expect(snapshot.tasks.map(\.id) == ["final-second-task"])
    }

    @Test("Task snapshots exclude an all-day event starting on the next day")
    func taskSnapshotsExcludeAllDayEventStartingOnNextDay() async throws {
        let calendar = Calendar.current
        let requestedDay = calendar.startOfDay(for: snapshotDay)
        let startOfNextDay = try #require(
            calendar.date(byAdding: .day, value: 1, to: requestedDay)
        )
        let scheduleEnd = try #require(
            calendar.date(byAdding: .day, value: 2, to: requestedDay)
        )
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: startOfNextDay,
                end: scheduleEnd,
                interval: DateComponents(day: 1),
                duration: .allDay
            )
        ])
        let task = OCKTask(
            id: "next-day-task",
            title: "Next day task",
            carePlanUUID: nil,
            schedule: schedule
        )
        let expandedEvents = schedule.events(from: requestedDay, to: startOfNextDay)
        let store = CareKitDaySnapshotStore(
            calendar: calendar,
            taskFetcher: { _, callbackQueue, completion in
                callbackQueue.async { completion(.success([task])) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        let snapshot = try await taskSnapshot(from: store, for: requestedDay)

        #expect(expandedEvents.contains { $0.start == startOfNextDay })
        #expect(!task.hasScheduledEvents(onDay: requestedDay, calendar: calendar))
        #expect(snapshot.tasks.isEmpty)
    }

    @Test("Targeted invalidation preserves unaffected cached days")
    func targetedInvalidationPreservesUnaffectedCachedDays() async throws {
        var taskFetchCount = 0
        let dayAfterSnapshotDay = try #require(fixedSnapshotCalendar.date(byAdding: .day, value: 1, to: snapshotDay))
        let endOfSnapshotDay = dayAfterSnapshotDay.addingTimeInterval(-1)
        let firstTask = makeCategorizedTask(
            id: "first-day",
            start: snapshotDay,
            end: endOfSnapshotDay,
            category: .medication
        )
        let secondTask = makeCategorizedTask(id: "second-day", start: dayAfterSnapshotDay, category: .activity)
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { _, callbackQueue, completion in
                taskFetchCount += 1
                callbackQueue.async { completion(.success([firstTask, secondTask])) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        _ = try await taskSnapshot(from: store, for: snapshotDay)
        let initialPreservedSnapshot = try await taskSnapshot(from: store, for: dayAfterSnapshotDay)

        store.invalidate(using: ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [snapshotDay]))
        #expect(store.cachedSnapshot(for: snapshotDay) == nil)
        #expect(store.cachedSnapshot(for: dayAfterSnapshotDay)?.tasks.map(\.id) == initialPreservedSnapshot.tasks.map(\.id))

        let invalidatedSnapshot = try await taskSnapshot(from: store, for: snapshotDay)
        let preservedSnapshot = try await taskSnapshot(from: store, for: dayAfterSnapshotDay)

        #expect(taskFetchCount == 3)
        #expect(invalidatedSnapshot.tasks.map(\.id) == ["first-day"])
        #expect(preservedSnapshot.tasks.map(\.id) == initialPreservedSnapshot.tasks.map(\.id))
    }

    @Test("Full invalidation refreshes all cached days")
    func fullInvalidationRefreshesAllCachedDays() async throws {
        var taskFetchCount = 0
        let dayAfterSnapshotDay = try #require(fixedSnapshotCalendar.date(byAdding: .day, value: 1, to: snapshotDay))
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { query, callbackQueue, completion in
                taskFetchCount += 1
                let queryInterval = query.dateInterval ?? DateInterval(start: snapshotDay, duration: 24 * 60 * 60)
                let day = fixedSnapshotCalendar.startOfDay(for: queryInterval.start)
                let task = makeCategorizedTask(
                    id: "fetch-\(taskFetchCount)",
                    start: day,
                    end: queryInterval.end,
                    category: .medication
                )
                callbackQueue.async { completion(.success([task])) }
            },
            outcomeFetcher: successfulOutcomeFetcher([])
        )

        let initialSnapshot = try await taskSnapshot(from: store, for: snapshotDay)
        let initialNextDaySnapshot = try await taskSnapshot(from: store, for: dayAfterSnapshotDay)

        store.invalidate(using: ScheduleRefreshContext(changeKind: .fullResync))
        #expect(store.cachedSnapshot(for: snapshotDay) == nil)
        #expect(store.cachedSnapshot(for: dayAfterSnapshotDay) == nil)

        let refreshedSnapshot = try await taskSnapshot(from: store, for: snapshotDay)
        let refreshedNextDaySnapshot = try await taskSnapshot(from: store, for: dayAfterSnapshotDay)

        #expect(taskFetchCount == 4)
        #expect(initialSnapshot.tasks.map { $0.id } == ["fetch-1"])
        #expect(initialNextDaySnapshot.tasks.map { $0.id } == ["fetch-2"])
        #expect(refreshedSnapshot.tasks.map { $0.id } == ["fetch-3"])
        #expect(refreshedNextDaySnapshot.tasks.map { $0.id } == ["fetch-4"])
    }

    @Test("Summary snapshots are cached until force refresh")
    func summarySnapshotsAreCachedUntilForceRefresh() async throws {
        var taskFetchCount = 0
        var outcomeFetchCount = 0
        let task = makeCategorizedTask(id: "medication", category: .medication)
        let completedOutcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )
        let store = CareKitDaySnapshotStore(
            calendar: fixedSnapshotCalendar,
            taskFetcher: { _, callbackQueue, completion in
                taskFetchCount += 1
                callbackQueue.async { completion(.success([task])) }
            },
            outcomeFetcher: { _, callbackQueue, completion in
                outcomeFetchCount += 1
                let outcomes = outcomeFetchCount == 1 ? [completedOutcome] : []
                callbackQueue.async { completion(.success(outcomes)) }
            }
        )

        let firstSummary = try await summarySnapshot(from: store, for: snapshotDay)
        let cachedSummary = try await summarySnapshot(from: store, for: snapshotDay)
        let forcedSummary = try await summarySnapshot(from: store, for: snapshotDay, forceRefresh: true)

        #expect(firstSummary.summary(for: .medication).completedTasks == 1)
        #expect(cachedSummary.summary(for: .medication).completedTasks == 1)
        #expect(forcedSummary.summary(for: .medication).completedTasks == 0)
        #expect(taskFetchCount == 2)
        #expect(outcomeFetchCount == 2)
    }

    @Test("Summary snapshots count completed tasks by category")
    func summarySnapshotsCountCompletedTasksByCategory() {
        let medication = makeCategorizedTask(id: "medication", category: .medication)
        let activity = makeCategorizedTask(id: "activity", category: .activity)
        let appointment = makeCategorizedTask(id: "appointment", category: .appointment)
        let outcomes = [
            OCKOutcome(taskUUID: medication.uuid, taskOccurrenceIndex: 0, values: [OCKOutcomeValue(true)]),
            OCKOutcome(taskUUID: activity.uuid, taskOccurrenceIndex: 99, values: [OCKOutcomeValue(true)])
        ]

        let snapshot = DaySummarySnapshotBuilder(calendar: fixedSnapshotCalendar).makeSummarySnapshot(
            for: snapshotDay,
            tasks: [medication, activity, appointment],
            outcomes: outcomes
        )

        #expect(snapshot.summary(for: .medication).totalTasks == 1)
        #expect(snapshot.summary(for: .medication).completedTasks == 1)
        #expect(snapshot.summary(for: .activity).totalTasks == 1)
        #expect(snapshot.summary(for: .activity).completedTasks == 0)
        #expect(snapshot.summary(for: .appointment).totalTasks == 1)
        #expect(snapshot.summary(for: .appointment).completedTasks == 0)
        #expect(snapshot.summary(for: .checkup).totalTasks == 0)
        #expect(snapshot.summary(for: .checkup).completedTasks == 0)
    }
}

private actor SnapshotResultRecorder<Value> {
    private var results = [Result<Value, OCKStoreError>]()

    var count: Int {
        results.count
    }

    func append(_ result: Result<Value, OCKStoreError>) {
        results.append(result)
    }

    func successes() throws -> [Value] {
        try results.map { result in
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }
    }
}

private let fixedSnapshotCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

private let snapshotDay = Date(timeIntervalSince1970: 1_800_000_000)

private func taskSnapshot(
    from store: CareKitDaySnapshotStore,
    for date: Date,
    forceRefresh: Bool = false
) async throws -> DayTaskSnapshot {
    let result = await withCheckedContinuation { continuation in
        store.snapshot(for: date, forceRefresh: forceRefresh) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let snapshot):
        return snapshot
    case .failure(let error):
        throw error
    }
}

private func summarySnapshot(
    from store: CareKitDaySnapshotStore,
    for date: Date,
    forceRefresh: Bool = false
) async throws -> DaySummarySnapshot {
    let result = await withCheckedContinuation { continuation in
        store.summary(for: date, forceRefresh: forceRefresh) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let snapshot):
        return snapshot
    case .failure(let error):
        throw error
    }
}

private func waitForResults<Value>(_ recorder: SnapshotResultRecorder<Value>, count: Int) async throws {
    for _ in 0..<100 {
        if await recorder.count >= count {
            return
        }
        try await Task.sleep(nanoseconds: 10_000_000)
    }
    #expect(await recorder.count == count)
}

private func successfulOutcomeFetcher(_ outcomes: [OCKOutcome]) -> CareKitDaySnapshotStore.OutcomeFetcher {
    { _, callbackQueue, completion in
        callbackQueue.async { completion(.success(outcomes)) }
    }
}

private func makeCategorizedTask(
    id: String,
    start: Date = snapshotDay,
    end: Date? = nil,
    category: CheckUpTaskType
) -> OCKTask {
    var task = makeTask(id: id, start: start, end: end)
    task.groupIdentifier = groupIdentifier(category: category)
    return task
}

private func groupIdentifier(category: CheckUpTaskType) -> String? {
    let keys = GroupIdentifierKeys(category: category, viewType: .simple)
    guard let data = try? JSONEncoder().encode(keys) else { return nil }
    return String(data: data, encoding: .utf8)
}
