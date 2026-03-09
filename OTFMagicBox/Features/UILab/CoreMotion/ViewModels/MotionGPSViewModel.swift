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
import CoreLocation
import Combine
import OTFCareKitStore
import OTFCareKit

final class MotionGPSViewModel: NSObject, ObservableObject {

    // MARK: - Publishers

    @Published var speed: Double = 0
    @Published var avgSpeed: Double = 0
    @Published var totalDistance: Double = 0
    @Published var altitude: Double = 0
    @Published var isRunning = false
    @Published var saved = false

    @Published private(set) var servicesEnabled: Bool = true
    @Published private(set) var authStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Properties

    var title: String {
        task.title ?? config.titleGPS.localized
    }

    var detail: String? {
        task.instructions
    }

    var speedString: String {
        let value = speed * config.speedUnitFactorFromMps
        return (speed.isFinite && speed >= 0) ? String(format: "%.\(config.speedDecimals)f \(config.speedUnitSymbol)", value) : "—"
    }

    var avgSpeedString: String {
        let value = avgSpeed * config.speedUnitFactorFromMps
        return (avgSpeed.isFinite && avgSpeed >= 0) ? String(format: "%.\(config.speedDecimals)f \(config.speedUnitSymbol)", value) : "—"
    }

    var distanceString: String {
        String(format: "%.\(config.distanceDecimals)f \(config.distanceUnitSymbol)", totalDistance)
    }

    var altitudeString: String {
        altitude.isFinite ? String(format: "%.\(config.altitudeDecimals)f \(config.altitudeUnitSymbol)", altitude) : "—"
    }

    var availabilityWarning: String? {
        guard servicesEnabled else { return config.warnLocationServicesOff.localized }
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse: return nil
        case .notDetermined: return config.warnLocationNotDetermined.localized
        case .denied: return config.warnLocationDenied.localized
        case .restricted: return config.warnLocationRestricted.localized
        @unknown default: return config.warnLocationNotDetermined.localized
        }
    }

    private var dayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    }

    private let config: CoreMotionConfiguration
    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var speedAccumulator: Double = 0
    private var speedSamples: Int = 0
    private var pendingStart = false

    private let task: OCKAnyTask
    private let eventQuery: OCKEventQuery
    private let storeManager: OCKSynchronizedStoreManager

    private(set) var selectedDate: Date

    // MARK: - Init

    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager, selectedDate: Date?, config: CoreMotionConfiguration = MotionConfigurationViewModel.shared.config) {
        self.task = task
        self.eventQuery = eventQuery
        self.storeManager = storeManager
        self.selectedDate = selectedDate ?? Date()
        self.config = config
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = Self.mapAccuracy(config.gpsDesiredAccuracy)
        manager.distanceFilter = config.gpsDistanceFilterMeters

        refreshSystemState()

        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            authStatus = manager.authorizationStatus
        }
    }

    // MARK: - Methods

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            saved = false
            totalDistance = 0
            speed = 0
            avgSpeed = 0
            altitude = 0
            lastLocation = nil
            speedAccumulator = 0
            speedSamples = 0
            isRunning = true
            manager.startUpdatingLocation()
        case .notDetermined:
            pendingStart = true
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        isRunning = false
    }

    func save() {
        let eventsForDay = task.schedule.events(from: dayStart, to: dayEnd)
        guard let event = eventsForDay.first, totalDistance > 0 else { return }
        let values = [OCKOutcomeValue(totalDistance), OCKOutcomeValue(avgSpeed * 3.6)]
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: event.occurrence, values: values)
        storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { [weak self] result in
            if case .success = result { self?.saved = true }
        }
    }

    // MARK: - Private Methods

    private func refreshSystemState() {
        DispatchQueue.global(qos: .utility).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                self.servicesEnabled = enabled
                self.authStatus = self.manager.authorizationStatus
            }
        }
    }

    private static func mapAccuracy(_ key: String) -> CLLocationAccuracy {
        switch key.lowercased() {
        case "bestfornavigation": return kCLLocationAccuracyBestForNavigation
        case "tenmeters": return kCLLocationAccuracyNearestTenMeters
        case "hundredmeters": return kCLLocationAccuracyHundredMeters
        case "kilometer": return kCLLocationAccuracyKilometer
        case "threekilometers", "threekilometres": return kCLLocationAccuracyThreeKilometers
        default: return kCLLocationAccuracyBest
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MotionGPSViewModel: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        refreshSystemState()
        if pendingStart, authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways, servicesEnabled {
            pendingStart = false
            start()
        }
        objectWillChange.send()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        if let last = lastLocation { totalDistance += loc.distance(from: last) }
        lastLocation = loc

        let spd = max(0, loc.speed)
        speed = spd
        altitude = loc.altitude
        speedAccumulator += spd
        speedSamples += 1
        avgSpeed = speedAccumulator / Double(speedSamples)
    }
}
