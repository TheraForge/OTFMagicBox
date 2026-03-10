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

final class MotionBalanceViewModel: ObservableObject {
    
    // MARK: - Publishers
    
    @Published var elapsed: Double = 0
    @Published var sway: Double = 0
    @Published var isRunning = false
    @Published var saved = false
    
    // MARK: - Properties
    
    var progress: Double { elapsed }
    var detail: String? { task.instructions }
    var duration: Double { config.balanceDurationSeconds }
    
    var title: String {
        task.title ?? config.titleBalance.localized
    }
    
    var availabilityWarning: String? {
        motion.isDeviceMotionAvailable ? nil : config.warnDeviceMotionUnavailable.localized
    }
    
    var grade: String {
        switch sway {
        case 0..<0.02: return "A"
        case 0.02..<0.04: return "B"
        case 0.04..<0.07: return "C"
        default: return "D"
        }
    }
    
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
    private let motion = CMMotionManager()
    private var timer: Timer?
    private var samples: [CMAcceleration] = []
    
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
        guard motion.isDeviceMotionAvailable else { return }
        saved = false; samples.removeAll(); sway = 0; elapsed = 0; isRunning = true
        
        motion.deviceMotionUpdateInterval = 1.0 / max(1.0, config.deviceMotionHz)
        motion.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let g = motion?.gravity, let self else { return }
            self.samples.append(g)
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: max(0.01, config.balanceTimerStepSeconds), repeats: true) { [weak self] t in
            guard let self else { return }
            self.elapsed += t.timeInterval
            self.elapsed = min(self.elapsed, self.duration)
            self.computeSway()
            if self.elapsed >= self.duration { self.stop() }
        }
    }
    
    func stop() {
        timer?.invalidate()
        motion.stopDeviceMotionUpdates()
        isRunning = false
    }
    
    private func computeSway() {
        guard samples.count > 10 else { return }
        // Use gravity components to estimate sway variance
        let xs = samples.map { $0.x }, ys = samples.map { $0.y }, zs = samples.map { $0.z }
        func variance(_ a: [Double]) -> Double {
            let m = a.reduce(0, +)/Double(a.count)
            return a.reduce(0) { $0 + pow($1 - m, 2) } / Double(a.count)
        }
        let v = variance(xs) + variance(ys) + variance(zs)
        sway = sqrt(v)
    }
    
    func save() {
        let eventsForDay = task.schedule.events(from: dayStart, to: dayEnd)
        guard let event = eventsForDay.first else { return }
        let values = [OCKOutcomeValue(sway), OCKOutcomeValue(grade)]
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: event.occurrence, values: values)
        storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { [weak self] result in
            if case .success = result {
                self?.saved = true
            }
        }
    }
}
