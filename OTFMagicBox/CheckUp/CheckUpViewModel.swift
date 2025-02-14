/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFCareKitUI

struct TaskEvents {
    let interval: DateInterval
    let events: [OCKEvent<OCKTask, OCKOutcome>]?
    var progress: Double {
        guard let events = events, !events.isEmpty else { return 0 }
        let performed = events.filter({ $0.outcome != nil })
        return Double(performed.count) / Double(events.count)
    }
}

struct CategoryTasksAndEvents {
    let category: TaskCategory
    let eventsOfTasks: [TaskEvents]
    var completedTasks: [OCKTask] {
        let completed = eventsOfTasks.filter({ $0.progress == 1 })
        return completed.compactMap({ $0.events?.first?.task })
    }
    var progress: Double {
        guard !eventsOfTasks.isEmpty else {
            return 0
        }
        return Double(completedTasks.count) / Double(eventsOfTasks.count)
    }
}

final class CheckUpViewModel: ObservableObject {
    @Published private(set) var medicationTasksAndEvents  = CategoryTasksAndEvents(category: .medication, eventsOfTasks: [])
    @Published private(set) var activityTasksAndEvents    = CategoryTasksAndEvents(category: .activity, eventsOfTasks: [])
    @Published private(set) var checkupTasksAndEvents     = CategoryTasksAndEvents(category: .checkup, eventsOfTasks: [])
    @Published private(set) var appointmentTasksAndEvents = CategoryTasksAndEvents(category: .appointment, eventsOfTasks: [])

    func fetchTasks() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-1)
        let todayInterval = DateInterval(start: todayStart, end: todayEnd)
        let query = OCKTaskQuery(dateInterval: DateInterval(start: todayStart, end: todayEnd))

        CareKitStoreManager.shared.cloudantStore?.fetchTasks(query: query,
                                                             callbackQueue: DispatchQueue.global(qos: .userInitiated)) { result in
            if case let .success(tasks) = result {
                let group = DispatchGroup()
                var error: Error?
                var events: [OCKEvent<OCKTask, OCKOutcome>] = []

                for task in tasks {
                    group.enter()
                    let query = OCKEventQuery(dateInterval: todayInterval)

                    CareKitStoreManager.shared.cloudantStore?.fetchEvents(task: task, query: query, previousEvents: []) {
                        switch $0 {
                        case .failure(let fetchError):
                            error = fetchError
                        case .success(let fetchedEvents):
                            events.append(contentsOf: fetchedEvents)
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    if error != nil {
                        return
                    }

                    let medTasksAndEvents = events.getTasksAndEventsOf(category: .medication, for: todayInterval)
                    self.medicationTasksAndEvents = CategoryTasksAndEvents(category: .medication, eventsOfTasks: medTasksAndEvents)

                    let actTasksAndEvents = events.getTasksAndEventsOf(category: .activity, for: todayInterval)
                    self.activityTasksAndEvents = CategoryTasksAndEvents(category: .activity, eventsOfTasks: actTasksAndEvents)

                    let checkupTasksAndEvents = events.getTasksAndEventsOf(category: .checkup, for: todayInterval)
                    self.checkupTasksAndEvents = CategoryTasksAndEvents(category: .checkup, eventsOfTasks: checkupTasksAndEvents)

                    let appointTasksAndEvents = events.getTasksAndEventsOf(category: .appointment, for: todayInterval)
                    self.appointmentTasksAndEvents = CategoryTasksAndEvents(category: .appointment, eventsOfTasks: appointTasksAndEvents)
                }
            }
        }
    }
}
