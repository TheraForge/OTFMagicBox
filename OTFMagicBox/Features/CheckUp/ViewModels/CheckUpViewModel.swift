/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFCareKitStore
import OTFUtilities
import OTFTemplateBox

final class CheckUpViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName = "CheckUpConfiguration"
    }

    // MARK: - Publishers

    @Published private(set) var medicationSummary: CategorySummary = .zero
    @Published private(set) var activitySummary: CategorySummary = .zero
    @Published private(set) var checkupSummary: CategorySummary = .zero
    @Published private(set) var appointmentSummary: CategorySummary = .zero
    @Published private(set) var config: CheckUpConfiguration = .fallback

    // MARK: - Properties

    private let decoder: OTFYAMLDecoding
    private let logger = OTFLogger.logger()

    // MARK: - Init

    init(decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine()) {
        self.decoder = decoder
        load()
    }

    // MARK: - Methods

    func load() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: CheckUpConfiguration.self)
        } catch {
            logger.error("CheckUp YAML decode error: \(error)")
            self.config = .fallback
        }
    }

    func fetchTasks() {
        let todayStart = Calendar.current.startOfDay(for: .now)

        guard let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)?.addingTimeInterval(-1) else { return }

        let todayInterval = DateInterval(start: todayStart, end: todayEnd)
        let query = OCKTaskQuery(dateInterval: todayInterval)

        guard let store = CareKitStoreManager.shared.cloudantStore else {
            logger.error("CloudantStore is nil; aborting fetch")
            return
        }

        logger.info("Fetching tasks for interval \(todayStart) → \(todayEnd)")
        store.fetchTasks(query: query, callbackQueue: DispatchQueue.global(qos: .userInitiated)) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.logger.error("Fetch tasks failed: \(error)")
                DispatchQueue.main.async {
                    self.applySummaries(from: [])
                }

            case .success(let tasks):
                let tasksToFetch: [(task: OCKTask, interval: DateInterval)] = tasks.compactMap { task in
                    guard let interval = self.validEventInterval(for: task, within: todayInterval) else { return nil }
                    return (task, interval)
                }

                self.logger.debug("Fetched \(tasks.count) task(s); \(tasksToFetch.count) overlap interval; resolving events")

                guard !tasksToFetch.isEmpty else {
                    DispatchQueue.main.async {
                        self.applySummaries(from: [])
                    }
                    return
                }

                let group = DispatchGroup()
                let lock = NSLock()

                var firstError: Error?
                var allEvents: [OCKEvent<OCKTask, OCKOutcome>] = []

                for (task, interval) in tasksToFetch {
                    group.enter()
                    let eventQuery = OCKEventQuery(dateInterval: interval)

                    store.fetchEvents(task: task, query: eventQuery, previousEvents: []) { eventsResult in
                        defer { group.leave() }

                        switch eventsResult {
                        case .failure(let error):
                            self.logger.error("Fetch Events failed for identifier='\(task.id)': \(error)")
                            lock.lock()
                            if firstError == nil { firstError = error }
                            lock.unlock()

                        case .success(let fetchedEvents):
                            lock.lock()
                            allEvents.append(contentsOf: fetchedEvents)
                            lock.unlock()
                        }
                    }
                }

                group.notify(queue: .main) {
                    if let error = firstError {
                        self.logger.error("One or more event fetches failed: \(error)")
                    }
                    self.applySummaries(from: allEvents)
                }
            }
        }
    }

    private func applySummaries(from events: [OCKEvent<OCKTask, OCKOutcome>]) {
        medicationSummary = buildSummary(from: events, category: .medication)
        activitySummary = buildSummary(from: events, category: .activity)
        checkupSummary = buildSummary(from: events, category: .checkup)
        appointmentSummary = buildSummary(from: events, category: .appointment)
    }

    private func validEventInterval(for task: OCKTask, within requested: DateInterval) -> DateInterval? {
        let elementStarts = task.schedule.elements.map(\.start)
        let elementEnds = task.schedule.elements.compactMap(\.end)

        let activeStart = ([task.effectiveDate] + elementStarts).min() ?? task.effectiveDate
        let activeEnd = elementEnds.max() ?? .distantFuture

        guard activeEnd > activeStart else { return nil }

        let activeInterval = DateInterval(start: activeStart, end: activeEnd)
        guard let intersection = activeInterval.intersection(with: requested), intersection.duration > 0 else {
            return nil
        }

        return intersection
    }

    // MARK: - Helpers

    /// Builds a per-category summary by grouping events by task id and
    /// counting tasks where *all* occurrences were completed.
    private func buildSummary(from events: [OCKEvent<OCKTask, OCKOutcome>], category: CheckUpTaskType) -> CategorySummary {
        // Keep only events for the desired category.
        let filtered = events.filter { $0.task.category == category }

        // Group occurrences by task id to avoid duplicates.
        let groups = Dictionary(grouping: filtered, by: { $0.task.id })

        let total = groups.count
        let completed = groups.values.reduce(0) { count, taskEvents in
            // A task is considered "completed" if *every* occurrence has an outcome.
            let allDone = !taskEvents.isEmpty && taskEvents.allSatisfy { $0.outcome != nil }
            return count + (allDone ? 1 : 0)
        }

        return CategorySummary(totalTasks: total, completedTasks: completed)
    }
}
