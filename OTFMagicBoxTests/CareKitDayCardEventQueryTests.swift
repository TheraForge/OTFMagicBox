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

import Combine
import Foundation
import Testing
@preconcurrency import OTFCareKit
@preconcurrency import OTFCareKitStore
@testable import OTFMagicBox

@Suite("CareKit day card event query")
struct CareKitDayCardEventQueryTests {
    @MainActor
    @Test("A final-second event populates the task card controller")
    func finalSecondEventPopulatesTaskCardController() async throws {
        let calendar = Calendar.current
        let requestedDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 21)))
        let startOfNextDay = try #require(calendar.date(byAdding: .day, value: 1, to: requestedDay))
        let finalSecond = startOfNextDay.addingTimeInterval(-1)
        let task = makeBoundaryTask(
            id: "evening-blood-pressure",
            title: "Evening blood pressure",
            start: finalSecond,
            end: startOfNextDay,
            duration: .minutes(1)
        )
        let store = OCKStore(
            name: "CareKitDayCardEventQueryTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storedTask = try await addTask(task, to: store)
        let query = CareKitScheduleDay(containing: requestedDay, calendar: calendar).eventQuery

        let fetchedEvents = try await fetchEvents(for: storedTask.id, query: query, from: store)
        let controller = OCKSimpleTaskController(
            storeManager: OCKSynchronizedStoreManager(wrapping: store)
        )
        let renderedTaskEvents = await fetchTaskEvents(
            with: controller,
            task: storedTask,
            query: query
        )
        let renderedEvents = renderedTaskEvents.flatMap { $0 }

        #expect(fetchedEvents.map(\.scheduleEvent.start) == [finalSecond])
        #expect(renderedEvents.map(\.scheduleEvent.start) == [finalSecond])
        #expect(controller.viewModel?.title == "Evening blood pressure")
    }

    @MainActor
    @Test("An all-day card query excludes the following day's expansion")
    func allDayCardQueryExcludesFollowingDayExpansion() async throws {
        let calendar = Calendar.current
        let requestedDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 21)))
        let startOfNextDay = try #require(calendar.date(byAdding: .day, value: 1, to: requestedDay))
        let end = try #require(calendar.date(byAdding: .day, value: 2, to: requestedDay))
        let task = makeBoundaryTask(
            id: "daily-medication-review",
            title: "Daily medication review",
            start: requestedDay,
            end: end,
            duration: .allDay
        )
        let store = OCKStore(
            name: "CareKitDayCardAllDayQueryTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storedTask = try await addTask(task, to: store)
        let query = CareKitScheduleDay(containing: requestedDay, calendar: calendar).eventQuery

        let expandedEvents = storedTask.schedule.events(from: requestedDay, to: startOfNextDay)
        let fetchedEvents = try await fetchEvents(for: storedTask.id, query: query, from: store)
        let controller = OCKSimpleTaskController(
            storeManager: OCKSynchronizedStoreManager(wrapping: store)
        )
        let renderedTaskEvents = await fetchTaskEvents(
            with: controller,
            task: storedTask,
            query: query
        )
        let renderedEvents = renderedTaskEvents.flatMap { $0 }

        #expect(expandedEvents.map(\.start).contains(startOfNextDay))
        #expect(fetchedEvents.map(\.scheduleEvent.start) == [requestedDay])
        #expect(renderedEvents.map(\.scheduleEvent.start) == [requestedDay])
    }
}

private func makeBoundaryTask(
    id: String,
    title: String,
    start: Date,
    end: Date,
    duration: OCKScheduleElement.Duration
) -> OCKTask {
    let schedule = OCKSchedule(composing: [
        OCKScheduleElement(
            start: start,
            end: end,
            interval: DateComponents(day: 1),
            duration: duration
        )
    ])
    return OCKTask(id: id, title: title, carePlanUUID: nil, schedule: schedule)
}

@MainActor
private func addTask(_ task: OCKTask, to store: OCKStore) async throws -> OCKTask {
    try await withCheckedThrowingContinuation { continuation in
        store.addTask(task, callbackQueue: .main) { result in
            continuation.resume(with: result)
        }
    }
}

@MainActor
private func fetchEvents(
    for taskID: String,
    query: OCKEventQuery,
    from store: OCKStore
) async throws -> [OCKEvent<OCKTask, OCKOutcome>] {
    try await withCheckedThrowingContinuation { continuation in
        store.fetchEvents(taskID: taskID, query: query, callbackQueue: .main) { result in
            continuation.resume(with: result)
        }
    }
}

@MainActor
private func fetchTaskEvents(
    with controller: OCKSimpleTaskController,
    task: OCKTask,
    query: OCKEventQuery
) async -> OCKTaskEvents {
    var cancellable: AnyCancellable?
    let taskEvents = await withCheckedContinuation { continuation in
        cancellable = controller.$taskEvents
            .dropFirst()
            .first()
            .sink { events in
                continuation.resume(returning: events)
            }
        controller.fetchAndObserveEvents(forTasks: [task], eventQuery: query)
    }
    withExtendedLifetime(cancellable) {}
    return taskEvents
}
