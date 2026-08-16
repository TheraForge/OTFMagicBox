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
import CoreLocation
import OTFCareKit
import OTFCareKitStore
import Testing
@testable import OTFMagicBox

@Suite("CoreMotion view models")
struct CoreMotionViewModelTests {
    @Test("Accelerometer view model formats current values with configured precision")
    func accelerometerViewModelFormatsCurrentValuesWithConfiguredPrecision() {
        let model = MotionAccelerometerViewModel(
            task: CoreMotionTaskType.accelerometerTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.x = 1.234
        model.y = -2.345
        model.z = 3.456
        model.rms = 4.567

        #expect(model.title == CoreMotionConfiguration.fallback.titleAccelerometer.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsAccelerometer.localized)
        #expect(model.xString == "1.23")
        #expect(model.yString == "-2.35")
        #expect(model.zString == "3.46")
        #expect(model.rmsString == "4.57")
        #expect(model.sampleCount == 0)
    }

    @Test("Accelerometer save is ignored before samples are collected")
    func accelerometerSaveIsIgnoredBeforeSamplesAreCollected() {
        let model = MotionAccelerometerViewModel(
            task: CoreMotionTaskType.accelerometerTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.save()

        #expect(model.saved == false)
    }

    @Test("Gyroscope view model converts radians to degree strings")
    func gyroscopeViewModelConvertsRadiansToDegreeStrings() {
        let model = MotionGyroscopeViewModel(
            task: CoreMotionTaskType.gyroscopeTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.x = Double.pi / 2
        model.y = -Double.pi
        model.z = Double.pi / 4
        model.peak = Double.pi

        #expect(model.title == CoreMotionConfiguration.fallback.titleGyroscope.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsGyroscope.localized)
        #expect(model.xDegString == "90")
        #expect(model.yDegString == "-180")
        #expect(model.zDegString == "45")
        #expect(model.peakDegString == "180")
        #expect(model.sampleCount == 0)
    }

    @Test("Gyroscope save is ignored before samples are collected")
    func gyroscopeSaveIsIgnoredBeforeSamplesAreCollected() {
        let model = MotionGyroscopeViewModel(
            task: CoreMotionTaskType.gyroscopeTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.save()

        #expect(model.saved == false)
    }

    @Test("Cadence view model formats missing and current cadence")
    func cadenceViewModelFormatsMissingAndCurrentCadence() {
        let model = MotionCadenceViewModel(
            task: CoreMotionTaskType.cadenceTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        #expect(model.title == CoreMotionConfiguration.fallback.titleCadence.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsCadence.localized)
        #expect(model.cadenceString == "—")

        model.avgCadence = 123.45

        #expect(model.cadenceString == "123 spm")
    }

    @Test("Cadence save is ignored before an average exists")
    func cadenceSaveIsIgnoredBeforeAverageExists() {
        let model = MotionCadenceViewModel(
            task: CoreMotionTaskType.cadenceTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.save()

        #expect(model.saved == false)
    }

    @Test("Steps view model formats recorded distance and detects save readiness")
    func stepsViewModelFormatsDistanceAndSaveReadiness() {
        let model = MotionStepsViewModel(
            task: CoreMotionTaskType.stepsTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        #expect(model.title == CoreMotionConfiguration.fallback.titleSteps.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsSteps.localized)
        #expect(model.distanceString == "—")
        #expect(model.canSaveOutcome == false)

        model.steps = 1234
        model.distanceMeters = 2500
        model.floors = 7

        #expect(model.distanceString == "2.50 km")
        #expect(model.canSaveOutcome == true)
    }

    @Test("Steps mark complete is ignored before pedometer values exist")
    func stepsMarkCompleteIsIgnoredBeforePedometerValuesExist() {
        let model = MotionStepsViewModel(
            task: CoreMotionTaskType.stepsTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.markComplete()

        #expect(model.isMarkedComplete == false)
        #expect(model.canSaveOutcome == false)
    }

    @Test("GPS view model formats speed distance altitude and handles invalid readings")
    func gpsViewModelFormatsMotionValues() {
        let model = MotionGPSViewModel(
            task: CoreMotionTaskType.gpsTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        #expect(model.title == CoreMotionConfiguration.fallback.titleGPS.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsGPS.localized)

        model.speed = 5
        model.avgSpeed = 4
        model.totalDistance = 123.45
        model.altitude = 50.25

        #expect(model.speedString == "18.0 km/h")
        #expect(model.avgSpeedString == "14.4 km/h")
        #expect(model.distanceString == "123 m")
        #expect(model.altitudeString == "50 m")

        model.speed = -.infinity
        model.avgSpeed = -.infinity
        model.altitude = .nan

        #expect(model.speedString == "—")
        #expect(model.avgSpeedString == "—")
        #expect(model.altitudeString == "—")
    }

    @Test("GPS location updates accumulate distance and average speed")
    func gpsLocationUpdatesAccumulateDistanceAndAverageSpeed() {
        let model = MotionGPSViewModel(
            task: CoreMotionTaskType.gpsTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )
        let first = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            altitude: 12,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 3,
            timestamp: fixedMotionDate
        )
        let second = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 38.7233, longitude: -9.1393),
            altitude: 18,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5,
            timestamp: fixedMotionDate.addingTimeInterval(10)
        )

        model.locationManager(CLLocationManager(), didUpdateLocations: [first])
        model.locationManager(CLLocationManager(), didUpdateLocations: [second])

        #expect(model.speed == 5)
        #expect(model.avgSpeed == 4)
        #expect(model.altitude == 18)
        #expect(model.totalDistance > 100)
    }

    @Test("GPS save is ignored before distance is recorded")
    func gpsSaveIsIgnoredBeforeDistanceIsRecorded() {
        let model = MotionGPSViewModel(
            task: CoreMotionTaskType.gpsTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.save()

        #expect(model.saved == false)
    }

    @Test(arguments: [
        (0.0, "A"),
        (0.019, "A"),
        (0.02, "B"),
        (0.039, "B"),
        (0.04, "C"),
        (0.069, "C"),
        (0.07, "D")
    ])
    func balanceViewModelGradesSwayThresholds(sway: Double, grade: String) {
        let model = MotionBalanceViewModel(
            task: CoreMotionTaskType.balanceTask(),
            eventQuery: OCKEventQuery(for: fixedMotionDate),
            storeManager: makeSynchronizedStoreManager(),
            selectedDate: fixedMotionDate,
            config: CoreMotionConfiguration.fallback
        )

        model.sway = sway

        #expect(model.grade == grade)
        #expect(model.title == CoreMotionConfiguration.fallback.titleBalance.localized)
        #expect(model.detail == CoreMotionConfiguration.fallback.instructionsBalance.localized)
        #expect(model.duration == CoreMotionConfiguration.fallback.balanceDurationSeconds)
        #expect(model.progress == 0)
    }
}

private let fixedMotionDate = Date(timeIntervalSince1970: 1_800_000_000)

private func makeSynchronizedStoreManager() -> OCKSynchronizedStoreManager {
    let store = OCKStore(name: "CoreMotionViewModelTests-\(UUID().uuidString)", type: .inMemory)
    return OCKSynchronizedStoreManager(wrapping: store)
}
