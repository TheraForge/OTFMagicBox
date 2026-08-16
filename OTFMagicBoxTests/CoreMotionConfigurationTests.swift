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
import OTFCareKitStore
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("CoreMotion configuration")
struct CoreMotionConfigurationTests {
    @Test("Motion configuration view model loads decoded configuration")
    func motionConfigurationViewModelLoadsDecodedConfig() {
        let config = makeCoreMotionConfiguration(titleSteps: "Today Steps", accelerometerHz: 25)
        let decoder = CoreMotionFakeYAMLDecoder(stubs: ["CoreMotionConfiguration": config])

        let model = MotionConfigurationViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["CoreMotionConfiguration"])
        #expect(model.config.titleSteps.localized == "Today Steps")
        #expect(model.config.accelerometerHz == 25)
    }

    @Test("Motion configuration view model falls back after decoder failure")
    func motionConfigurationViewModelFallsBackAfterDecoderFailure() {
        let decoder = CoreMotionFakeYAMLDecoder(error: CoreMotionFakeYAMLDecoderError.requestedFailure)

        let model = MotionConfigurationViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["CoreMotionConfiguration"])
        #expect(model.config.titleSteps.localized == CoreMotionConfiguration.fallback.titleSteps.localized)
        #expect(model.config.accelerometerHz == CoreMotionConfiguration.fallback.accelerometerHz)
    }

    @Test("CoreMotion configuration migrates partial raw values and fills defaults")
    func coreMotionConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeJSON(RawCoreMotionConfiguration.self, from: [
            "version": "2.0.0",
            "accelerometerHz": 12.5,
            "titleSteps": localized("Daily Movement")
        ])

        let config = CoreMotionConfiguration(from: raw)

        #expect(config.accelerometerHz == 12.5)
        #expect(config.titleSteps.localized == "Daily Movement")
        #expect(config.gyroscopeHz == CoreMotionConfiguration.fallback.gyroscopeHz)
        #expect(config.warnStepsUnavailable.localized == CoreMotionConfiguration.fallback.warnStepsUnavailable.localized)
    }

    @Test("CoreMotion task identities remain stable")
    func coreMotionTaskIdentitiesRemainStable() {
        #expect(CoreMotionTaskType.allCases.map(\.id) == [
            "steps",
            "cadence",
            "balance",
            "accelerometer",
            "gyroscope",
            "gps"
        ])
    }

    @Test("CoreMotion task titles use configured fallback labels")
    func coreMotionTaskTitlesUseConfiguredFallbackLabels() {
        let config = CoreMotionConfiguration.fallback

        #expect(CoreMotionTaskType.allCases.map(\.title) == [
            config.titleSteps.localized,
            config.titleCadence.localized,
            config.titleBalance.localized,
            config.titleAccelerometer.localized,
            config.titleGyroscope.localized,
            config.titleGPS.localized
        ])
    }

    @Test("CoreMotion preview task builders expose stable metadata")
    func coreMotionPreviewTaskBuildersExposeStableMetadata() {
        let config = CoreMotionConfiguration.fallback
        let cases: [(task: OCKAnyTask, id: String, title: String, instructions: String)] = [
            (
                CoreMotionTaskType.stepsTask(),
                "motion.steps",
                config.titleSteps.localized,
                config.instructionsSteps.localized
            ),
            (
                CoreMotionTaskType.cadenceTask(),
                "motion.cadence",
                config.titleCadence.localized,
                config.instructionsCadence.localized
            ),
            (
                CoreMotionTaskType.balanceTask(),
                "motion.balance",
                config.titleBalance.localized,
                config.instructionsBalance.localized
            ),
            (
                CoreMotionTaskType.accelerometerTask(),
                "sensor.accel",
                config.titleAccelerometer.localized,
                config.instructionsAccelerometer.localized
            ),
            (
                CoreMotionTaskType.gyroscopeTask(),
                "sensor.gyro",
                config.titleGyroscope.localized,
                config.instructionsGyroscope.localized
            ),
            (
                CoreMotionTaskType.gpsTask(),
                "sensor.gps",
                config.titleGPS.localized,
                config.instructionsGPS.localized
            )
        ]

        for testCase in cases {
            #expect(testCase.task.id == testCase.id)
            #expect(testCase.task.title == testCase.title)
            #expect(testCase.task.instructions == testCase.instructions)
        }
    }

    @Test("CoreMotion preview task builders share expected repeating schedule shape")
    func coreMotionPreviewTaskBuildersShareExpectedRepeatingScheduleShape() throws {
        let tasks = [
            CoreMotionTaskType.stepsTask(),
            CoreMotionTaskType.cadenceTask(),
            CoreMotionTaskType.balanceTask(),
            CoreMotionTaskType.accelerometerTask(),
            CoreMotionTaskType.gyroscopeTask(),
            CoreMotionTaskType.gpsTask()
        ]

        for task in tasks {
            let schedule = task.schedule

            #expect(schedule.elements.count == 2)
            #expect(schedule.elements.first?.interval.day == 1)
            #expect(schedule.elements.last?.interval.day == 2)
        }
    }
}

private enum CoreMotionFakeYAMLDecoderError: Error {
    case requestedFailure
    case missingStub(String)
}

private final class CoreMotionFakeYAMLDecoder: OTFYAMLDecoding {
    private let stubs: [String: Any]
    private let error: Error?
    private(set) var decodedFiles: [String] = []

    init(stubs: [String: Any] = [:], error: Error? = nil) {
        self.stubs = stubs
        self.error = error
    }

    func decode<T>(_ fileName: String, as type: T.Type) throws -> T where T: Decodable {
        decodedFiles.append(fileName)
        if let error {
            throw error
        }
        guard let value = stubs[fileName] as? T else {
            throw CoreMotionFakeYAMLDecoderError.missingStub(fileName)
        }
        return value
    }
}

private func decodeJSON<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

private func localized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}

private func makeCoreMotionConfiguration(
    titleSteps: OTFStringLocalized = CoreMotionConfiguration.fallback.titleSteps,
    accelerometerHz: Double = CoreMotionConfiguration.fallback.accelerometerHz
) -> CoreMotionConfiguration {
    CoreMotionConfiguration(
        version: CoreMotionConfiguration.fallback.version,
        accelerometerHz: accelerometerHz,
        gyroscopeHz: CoreMotionConfiguration.fallback.gyroscopeHz,
        deviceMotionHz: CoreMotionConfiguration.fallback.deviceMotionHz,
        balanceDurationSeconds: CoreMotionConfiguration.fallback.balanceDurationSeconds,
        balanceTimerStepSeconds: CoreMotionConfiguration.fallback.balanceTimerStepSeconds,
        cadenceTimerStepSeconds: CoreMotionConfiguration.fallback.cadenceTimerStepSeconds,
        gpsDesiredAccuracy: CoreMotionConfiguration.fallback.gpsDesiredAccuracy,
        gpsDistanceFilterMeters: CoreMotionConfiguration.fallback.gpsDistanceFilterMeters,
        accelerometerDecimals: CoreMotionConfiguration.fallback.accelerometerDecimals,
        gyroscopeDecimals: CoreMotionConfiguration.fallback.gyroscopeDecimals,
        speedDecimals: CoreMotionConfiguration.fallback.speedDecimals,
        altitudeDecimals: CoreMotionConfiguration.fallback.altitudeDecimals,
        distanceDecimals: CoreMotionConfiguration.fallback.distanceDecimals,
        speedUnitFactorFromMps: CoreMotionConfiguration.fallback.speedUnitFactorFromMps,
        speedUnitSymbol: CoreMotionConfiguration.fallback.speedUnitSymbol,
        distanceUnitSymbol: CoreMotionConfiguration.fallback.distanceUnitSymbol,
        altitudeUnitSymbol: CoreMotionConfiguration.fallback.altitudeUnitSymbol,
        titleSteps: titleSteps,
        titleCadence: CoreMotionConfiguration.fallback.titleCadence,
        titleBalance: CoreMotionConfiguration.fallback.titleBalance,
        titleAccelerometer: CoreMotionConfiguration.fallback.titleAccelerometer,
        titleGyroscope: CoreMotionConfiguration.fallback.titleGyroscope,
        titleGPS: CoreMotionConfiguration.fallback.titleGPS,
        instructionsSteps: CoreMotionConfiguration.fallback.instructionsSteps,
        instructionsCadence: CoreMotionConfiguration.fallback.instructionsCadence,
        instructionsBalance: CoreMotionConfiguration.fallback.instructionsBalance,
        instructionsAccelerometer: CoreMotionConfiguration.fallback.instructionsAccelerometer,
        instructionsGyroscope: CoreMotionConfiguration.fallback.instructionsGyroscope,
        instructionsGPS: CoreMotionConfiguration.fallback.instructionsGPS,
        metricX: CoreMotionConfiguration.fallback.metricX,
        metricY: CoreMotionConfiguration.fallback.metricY,
        metricZ: CoreMotionConfiguration.fallback.metricZ,
        metricRMS: CoreMotionConfiguration.fallback.metricRMS,
        metricPeak: CoreMotionConfiguration.fallback.metricPeak,
        metricSpeed: CoreMotionConfiguration.fallback.metricSpeed,
        metricAvgSpeed: CoreMotionConfiguration.fallback.metricAvgSpeed,
        metricDistance: CoreMotionConfiguration.fallback.metricDistance,
        metricAltitude: CoreMotionConfiguration.fallback.metricAltitude,
        metricCadence: CoreMotionConfiguration.fallback.metricCadence,
        metricDuration: CoreMotionConfiguration.fallback.metricDuration,
        metricSteps: CoreMotionConfiguration.fallback.metricSteps,
        metricFloors: CoreMotionConfiguration.fallback.metricFloors,
        metricSway: CoreMotionConfiguration.fallback.metricSway,
        metricGrade: CoreMotionConfiguration.fallback.metricGrade,
        captionSway: CoreMotionConfiguration.fallback.captionSway,
        buttonStart: CoreMotionConfiguration.fallback.buttonStart,
        buttonStop: CoreMotionConfiguration.fallback.buttonStop,
        buttonStartWalk: CoreMotionConfiguration.fallback.buttonStartWalk,
        buttonSave: CoreMotionConfiguration.fallback.buttonSave,
        buttonSaved: CoreMotionConfiguration.fallback.buttonSaved,
        buttonRefresh: CoreMotionConfiguration.fallback.buttonRefresh,
        buttonMarkComplete: CoreMotionConfiguration.fallback.buttonMarkComplete,
        buttonCompleted: CoreMotionConfiguration.fallback.buttonCompleted,
        warnAccelerometerUnavailable: CoreMotionConfiguration.fallback.warnAccelerometerUnavailable,
        warnGyroUnavailable: CoreMotionConfiguration.fallback.warnGyroUnavailable,
        warnDeviceMotionUnavailable: CoreMotionConfiguration.fallback.warnDeviceMotionUnavailable,
        warnStepsUnavailable: CoreMotionConfiguration.fallback.warnStepsUnavailable,
        warnCadenceUnavailable: CoreMotionConfiguration.fallback.warnCadenceUnavailable,
        warnLocationServicesOff: CoreMotionConfiguration.fallback.warnLocationServicesOff,
        warnLocationNotDetermined: CoreMotionConfiguration.fallback.warnLocationNotDetermined,
        warnLocationDenied: CoreMotionConfiguration.fallback.warnLocationDenied,
        warnLocationRestricted: CoreMotionConfiguration.fallback.warnLocationRestricted
    )
}
