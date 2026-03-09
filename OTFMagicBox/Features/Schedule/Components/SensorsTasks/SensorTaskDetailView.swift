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

import SwiftUI
import Combine
import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI
import HealthKit

struct SensorTaskDetailView: View {

    @StateObject private var viewModel: SensorTaskDetailViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: SensorTaskDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            GenericHealthCardView(
                metric: viewModel.metric,
                onSendOutcome: { value in
                    viewModel.sendOutcome(value) { success in
                        if success {
                            dismiss()
                        }
                    }
                },
                sendOutcomeDisabled: viewModel.sendOutcomeDisabled
            )
        }
    }
}

final class SensorTaskDetailViewModel: ObservableObject {

    @Published private(set) var sendOutcomeDisabled = false

    let metric: HealthKitDataManager.HealthMetric

    private let task: OCKAnyTask
    private let selectedDate: Date
    private let storeManager: OCKSynchronizedStoreManager
    private var cancellable: AnyCancellable?

    init(
        task: OCKAnyTask,
        selectedDate: Date,
        storeManager: OCKSynchronizedStoreManager,
        dataManager: HealthKitDataManager = HealthKitDataManager(),
        metric: HealthKitDataManager.HealthMetric
    ) {
        self.task = task
        self.selectedDate = selectedDate
        self.storeManager = storeManager
        self.metric = metric
        _ = dataManager

        cancellable = storeManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSendState()
            }

        refreshSendState()
    }

    func sendOutcome(_ value: MetricValue, completion: ((Bool) -> Void)? = nil) {
        sendOutcomeDisabled = true
        SensorTaskOutcomeHelper.sendOutcome(
            value: value,
            task: task,
            on: selectedDate,
            storeManager: storeManager
        ) { [weak self] success in
            if success {
                self?.refreshSendState()
                completion?(true)
            } else {
                self?.sendOutcomeDisabled = false
                completion?(false)
            }
        }
    }

    private var dayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? selectedDate
    }

    private func refreshSendState() {
        var query = OCKOutcomeQuery(for: dayStart)
        query.taskUUIDs = [task.uuid]
        query.limit = 1

        storeManager.store.fetchAnyOutcomes(query: query, callbackQueue: .main) { [weak self] result in
            switch result {
            case .success(let outcomes):
                self?.sendOutcomeDisabled = !outcomes.isEmpty
            case .failure:
                self?.sendOutcomeDisabled = false
            }
        }
    }
}

enum SensorTaskOutcomeHelper {
    static func event(for task: OCKAnyTask, on date: Date) -> OCKScheduleEvent? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        return task.schedule.events(from: dayStart, to: dayEnd).first
    }

    static func sendOutcome(
        value: MetricValue,
        task: OCKAnyTask,
        on date: Date,
        storeManager: OCKSynchronizedStoreManager,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let event = event(for: task, on: date) else {
            completion?(false)
            return
        }

        let outcomeValue = OCKOutcomeValue(value.value, units: value.unit)
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: event.occurrence, values: [outcomeValue])

        storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }
}
