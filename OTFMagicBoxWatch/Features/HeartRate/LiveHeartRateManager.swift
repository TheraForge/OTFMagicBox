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

import HealthKit
import WatchConnectivity
import WatchKit

final class LiveHeartRateManager: NSObject, ObservableObject {

    private enum FileConstants {
        static let bpmKey = "bpm"
        static let timestampKey = "timestamp"
    }

    static let shared = LiveHeartRateManager()

    @Published private(set) var bpm: Int = 0
    @Published private(set) var isRunning = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var isStarting = false

    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartRequest),
            name: .healthSensorsLiveHeartRateStart,
            object: nil
        )
    }

    func start() {
        guard !isStarting, !isRunning else { return }
        isStarting = true

        authorizeIfNeeded { [weak self] authorized in
            guard let self else { return }

            guard authorized else {
                self.resetWorkoutState(resetBpm: false)
                return
            }

            self.beginWorkout()
        }
    }

    func stop() {
        let currentSession = session
        let currentBuilder = builder
        let endDate = Date()

        resetWorkoutState(resetBpm: false)

        currentSession?.end()
        currentBuilder?.endCollection(withEnd: endDate) { _, _ in
            currentBuilder?.finishWorkout { _, _ in }
        }

        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    @objc private func handleStartRequest() {
        start()
    }

    private func authorizeIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }

        let workoutType = HKObjectType.workoutType()
        let readTypes: Set<HKObjectType> = [heartRateType, workoutType]
        let shareTypes: Set<HKSampleType> = [workoutType]

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    private func beginWorkout() {
        guard !isRunning else { return }
        resetWorkoutState(resetBpm: true)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            resetWorkoutState(resetBpm: false)
            return
        }

        guard let session else {
            resetWorkoutState(resetBpm: false)
            return
        }

        builder = session.associatedWorkoutBuilder()
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        session.delegate = self
        builder?.delegate = self

        let startDate = Date()
        session.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { [weak self] success, _ in
            guard let self else { return }

            if !success {
                self.resetWorkoutState(resetBpm: false)
                return
            }

            DispatchQueue.main.async {
                self.isStarting = false
                self.isRunning = true
            }
        }
    }

    private func updateHeartRate(from statistics: HKStatistics?) {
        guard let quantity = statistics?.mostRecentQuantity() else { return }
        let value = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let bpmValue = Int(value.rounded())
        DispatchQueue.main.async {
            self.bpm = bpmValue
        }
        sendBpm(bpmValue)
    }

    private func sendBpm(_ bpm: Int) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.isReachable else { return }
        let payload: [String: Any] = [
            FileConstants.bpmKey: bpm,
            FileConstants.timestampKey: Date().timeIntervalSince1970
        ]
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    private func resetWorkoutState(resetBpm: Bool) {
        session?.delegate = nil
        builder?.delegate = nil
        session = nil
        builder = nil

        DispatchQueue.main.async {
            self.isStarting = false
            self.isRunning = false
            if resetBpm {
                self.bpm = 0
            }
        }
    }
}

extension LiveHeartRateManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            DispatchQueue.main.async {
                self.isStarting = false
                self.isRunning = true
            }

        case .ended:
            resetWorkoutState(resetBpm: false)

        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        resetWorkoutState(resetBpm: false)
    }
}

extension LiveHeartRateManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate), collectedTypes.contains(type) else { return }
        let statistics = workoutBuilder.statistics(for: type)
        updateHeartRate(from: statistics)
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
