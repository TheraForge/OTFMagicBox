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

import SwiftUI
import Combine
import CoreMotion
import OTFCareKitStore
import OTFCareKit

final class MotionStepsViewModel: ObservableObject {
    
    // MARK: - Publishers
    
    @Published var steps: Int?
    @Published var distanceMeters: Double?
    @Published var floors: Int?
    @Published var isMarkedComplete = false
    
    // MARK: - Properties
    
    var title: String {
        task.title ?? config.titleSteps.localized
    }
    
    var detail: String? {
        task.instructions
    }
    
    var supportsFloors: Bool {
        CMPedometer.isFloorCountingAvailable()
    }
    
    var distanceString: String {
        guard let meters = distanceMeters else { return "—" }
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }
    
    var hintText: String {
        "From \(Self.dateFormatter.string(from: dayStart)) to now."
    }
    
    var canSaveOutcome: Bool {
        steps != nil || distanceMeters != nil || floors != nil
    }
    
    var availabilityWarning: String? {
        CMPedometer.isStepCountingAvailable() ? nil : config.warnStepsUnavailable.localized
    }
    
    private var dayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }
    
    private var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let config: CoreMotionConfiguration
    private let task: OCKAnyTask
    private let eventQuery: OCKEventQuery
    private let storeManager: OCKSynchronizedStoreManager
    private let pedometer = CMPedometer()
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) var selectedDate: Date
    
    // MARK: - Init
    
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager, selectedDate: Date? = nil, config: CoreMotionConfiguration = MotionConfigurationViewModel.shared.config) {
        self.task = task
        self.eventQuery = eventQuery
        self.storeManager = storeManager
        self.selectedDate = selectedDate ?? Date()
        self.config = config
        
        storeManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncCompletionState() }
            .store(in: &cancellables)
        
        refresh()
    }
    
    // MARK: - Methods
    
    func refresh() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.queryPedometerData(from: dayStart, to: Date()) { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.steps = data?.numberOfSteps.intValue
                self?.distanceMeters = data?.distance?.doubleValue
                self?.floors = data?.floorsAscended?.intValue
            }
        }
        syncCompletionState()
    }
    
    func markComplete() {
        let eventsForDay = task.schedule.events(from: dayStart, to: dayEnd)
        guard let event = eventsForDay.first else { return }
        
        var values: [OCKOutcomeValue] = []
        if let steps = steps { values.append(OCKOutcomeValue(steps)) }
        if let distanceMeters = distanceMeters { values.append(OCKOutcomeValue(distanceMeters)) }
        if let floors = floors { values.append(OCKOutcomeValue(floors)) }
        
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: event.occurrence, values: values)
        storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { [weak self] result in
            if case .success = result {
                self?.isMarkedComplete = true
            }
        }
    }
    
    private func syncCompletionState() {
        let eventsForDay = task.schedule.events(from: dayStart, to: dayEnd)
        guard eventsForDay.first != nil else {
            isMarkedComplete = false
            return
        }
    }
}
