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
import CoreMotion
import Combine
import OTFCareKitStore
import OTFCareKit

final class MotionCadenceViewModel: ObservableObject {
    
    // MARK: - Publishers
    
    @Published var isRunning = false
    @Published var elapsed: Double = 0
    @Published var avgCadence: Double?
    
    // MARK: - Properties
    
    var cadenceString: String {
        avgCadence.map { String(format: "%.0f spm", $0) } ?? "—"
    }
    
    var detail: String? {
        task.instructions
    }
    
    var title: String {
        task.title ?? config.titleCadence.localized
    }
    
    var availabilityWarning: String? {
        CMPedometer.isCadenceAvailable() ? nil : config.warnCadenceUnavailable.localized
    }
    
    var saved = false
    
    private var dayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }
    
    private var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    }
    
    private let config: CoreMotionConfiguration
    private let task: OCKAnyTask
    private let eventQuery: OCKEventQuery
    private let storeManager: OCKSynchronizedStoreManager
    private let pedometer = CMPedometer()
    private var timer: Timer?
    private var cadences: [Double] = []
    
    private(set) var selectedDate: Date
    
    // MARK: - Init
    
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager, selectedDate: Date? = nil, config: CoreMotionConfiguration = MotionConfigurationViewModel.shared.config) {
        self.task = task
        self.eventQuery = eventQuery
        self.storeManager = storeManager
        self.selectedDate = selectedDate ?? Date()
        self.config = config
    }
    
    // MARK: - Methods
    
    func toggle() {
        isRunning ? stop() : start()
    }
    
    func start() {
        guard CMPedometer.isCadenceAvailable() else { return }
        isRunning = true; saved = false; cadences.removeAll(); avgCadence = nil; elapsed = 0
        pedometer.startUpdates(from: Date()) { [weak self] data, _ in
            guard let self, let c = data?.currentCadence?.doubleValue else { return }
            DispatchQueue.main.async {
                self.cadences.append(c * 60.0) // convert from steps/s to steps/min
                self.avgCadence = self.cadences.reduce(0, +) / Double(self.cadences.count)
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: max(0.1, config.cadenceTimerStepSeconds), repeats: true) { [weak self] t in
            self?.elapsed += t.timeInterval
        }
    }
    
    func stop() {
        pedometer.stopUpdates()
        timer?.invalidate()
        isRunning = false
    }
    
    func save() {
        let eventsForDay = task.schedule.events(from: dayStart, to: dayEnd)
        guard let event = eventsForDay.first, let avg = avgCadence else { return }
        let values = [OCKOutcomeValue(avg)]
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: event.occurrence, values: values)
        storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { [weak self] result in
            if case .success = result {
                self?.saved = true
            }
        }
    }
}
