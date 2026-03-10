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
import OTFTemplateBox
import RawModel
import OTFUtilities

@RawGenerable
struct CoreMotionConfiguration: Codable {
    // Versioning
    let version: String

    // Sampling / timing
    let accelerometerHz: Double
    let gyroscopeHz: Double
    let deviceMotionHz: Double
    let balanceDurationSeconds: Double
    let balanceTimerStepSeconds: Double
    let cadenceTimerStepSeconds: Double

    // GPS
    let gpsDesiredAccuracy: String
    let gpsDistanceFilterMeters: Double

    // Formatting
    let accelerometerDecimals: Int
    let gyroscopeDecimals: Int
    let speedDecimals: Int
    let altitudeDecimals: Int
    let distanceDecimals: Int

    // Units
    let speedUnitFactorFromMps: Double
    let speedUnitSymbol: String
    let distanceUnitSymbol: String
    let altitudeUnitSymbol: String

    // Titles (fallbacks)
    let titleSteps: OTFStringLocalized
    let titleCadence: OTFStringLocalized
    let titleBalance: OTFStringLocalized
    let titleAccelerometer: OTFStringLocalized
    let titleGyroscope: OTFStringLocalized
    let titleGPS: OTFStringLocalized

    // Instructions
    let instructionsSteps: OTFStringLocalized
    let instructionsCadence: OTFStringLocalized
    let instructionsBalance: OTFStringLocalized
    let instructionsAccelerometer: OTFStringLocalized
    let instructionsGyroscope: OTFStringLocalized
    let instructionsGPS: OTFStringLocalized

    // Labels
    let metricX: OTFStringLocalized
    let metricY: OTFStringLocalized
    let metricZ: OTFStringLocalized
    let metricRMS: OTFStringLocalized
    let metricPeak: OTFStringLocalized
    let metricSpeed: OTFStringLocalized
    let metricAvgSpeed: OTFStringLocalized
    let metricDistance: OTFStringLocalized
    let metricAltitude: OTFStringLocalized
    let metricCadence: OTFStringLocalized
    let metricDuration: OTFStringLocalized
    let metricSteps: OTFStringLocalized
    let metricFloors: OTFStringLocalized
    let metricSway: OTFStringLocalized
    let metricGrade: OTFStringLocalized
    let captionSway: OTFStringLocalized

    // Buttons
    let buttonStart: OTFStringLocalized
    let buttonStop: OTFStringLocalized
    let buttonStartWalk: OTFStringLocalized
    let buttonSave: OTFStringLocalized
    let buttonSaved: OTFStringLocalized
    let buttonRefresh: OTFStringLocalized
    let buttonMarkComplete: OTFStringLocalized
    let buttonCompleted: OTFStringLocalized

    // Warnings
    let warnAccelerometerUnavailable: OTFStringLocalized
    let warnGyroUnavailable: OTFStringLocalized
    let warnDeviceMotionUnavailable: OTFStringLocalized
    let warnStepsUnavailable: OTFStringLocalized
    let warnCadenceUnavailable: OTFStringLocalized
    let warnLocationServicesOff: OTFStringLocalized
    let warnLocationNotDetermined: OTFStringLocalized
    let warnLocationDenied: OTFStringLocalized
    let warnLocationRestricted: OTFStringLocalized
}

extension CoreMotionConfiguration: OTFVersionedDecodable {
    typealias Raw = RawCoreMotionConfiguration

    static let fallback = CoreMotionConfiguration(
        version: "2.0.0",
        accelerometerHz: 50,
        gyroscopeHz: 50,
        deviceMotionHz: 50,
        balanceDurationSeconds: 20,
        balanceTimerStepSeconds: 0.025,
        cadenceTimerStepSeconds: 0.5,
        gpsDesiredAccuracy: "best",
        gpsDistanceFilterMeters: 5,
        accelerometerDecimals: 2,
        gyroscopeDecimals: 0,
        speedDecimals: 1,
        altitudeDecimals: 0,
        distanceDecimals: 0,
        speedUnitFactorFromMps: 3.6,
        speedUnitSymbol: "km/h",
        distanceUnitSymbol: "m",
        altitudeUnitSymbol: "m",
        titleSteps: "Daily Steps",
        titleCadence: "Walking Cadence",
        titleBalance: "Balance (Stillness) Test",
        titleAccelerometer: "Accelerometer",
        titleGyroscope: "Gyroscope",
        titleGPS: "GPS (Location)",
        instructionsSteps: "Keep your iPhone with you to record steps, distance and floors.",
        instructionsCadence: "Walk naturally and we’ll average your steps per minute.",
        instructionsBalance: "Stand still for ~20s holding the phone at chest level.",
        instructionsAccelerometer: "Move the phone to see X/Y/Z and RMS.",
        instructionsGyroscope: "Rotate the phone to see angular velocity.",
        instructionsGPS: "Start walking to see speed and distance.",
        metricX: "X",
        metricY: "Y",
        metricZ: "Z",
        metricRMS: "RMS (g)",
        metricPeak: "Peak (°/s)",
        metricSpeed: "Speed",
        metricAvgSpeed: "Avg Speed",
        metricDistance: "Distance",
        metricAltitude: "Altitude",
        metricCadence: "Cadence",
        metricDuration: "Duration",
        metricSteps: "Steps",
        metricFloors: "Floors",
        metricSway: "Sway",
        metricGrade: "Grade",
        captionSway: "Sway (lower is better)",
        buttonStart: "Start",
        buttonStop: "Stop",
        buttonStartWalk: "Start Walk",
        buttonSave: "Save Result",
        buttonSaved: "Saved",
        buttonRefresh: "Refresh",
        buttonMarkComplete: "Mark Complete",
        buttonCompleted: "Completed",
        warnAccelerometerUnavailable: "Accelerometer isn’t available on this device.",
        warnGyroUnavailable: "Gyroscope isn’t available on this device (e.g., Simulator).",
        warnDeviceMotionUnavailable: "Device motion isn’t available on this device.",
        warnStepsUnavailable: "Step counting isn’t available on this device.",
        warnCadenceUnavailable: "Cadence isn’t available on this device.",
        warnLocationServicesOff: "Location Services are disabled.",
        warnLocationNotDetermined: "Location permission not determined.",
        warnLocationDenied: "Location permission denied. Enable it in Settings.",
        warnLocationRestricted: "Location access restricted."
    )

    init(from raw: RawCoreMotionConfiguration) {
        let fallback = Self.fallback
        // Scalars
        self.version = raw.version ?? fallback.version
        self.accelerometerHz = raw.accelerometerHz ?? fallback.accelerometerHz
        self.gyroscopeHz = raw.gyroscopeHz ?? fallback.gyroscopeHz
        self.deviceMotionHz = raw.deviceMotionHz ?? fallback.deviceMotionHz
        self.balanceDurationSeconds = raw.balanceDurationSeconds ?? fallback.balanceDurationSeconds
        self.balanceTimerStepSeconds = raw.balanceTimerStepSeconds ?? fallback.balanceTimerStepSeconds
        self.cadenceTimerStepSeconds = raw.cadenceTimerStepSeconds ?? fallback.cadenceTimerStepSeconds
        self.gpsDesiredAccuracy = raw.gpsDesiredAccuracy ?? fallback.gpsDesiredAccuracy
        self.gpsDistanceFilterMeters = raw.gpsDistanceFilterMeters ?? fallback.gpsDistanceFilterMeters
        self.accelerometerDecimals = raw.accelerometerDecimals ?? fallback.accelerometerDecimals
        self.gyroscopeDecimals = raw.gyroscopeDecimals ?? fallback.gyroscopeDecimals
        self.speedDecimals = raw.speedDecimals ?? fallback.speedDecimals
        self.altitudeDecimals = raw.altitudeDecimals ?? fallback.altitudeDecimals
        self.distanceDecimals = raw.distanceDecimals ?? fallback.distanceDecimals
        self.speedUnitFactorFromMps = raw.speedUnitFactorFromMps ?? fallback.speedUnitFactorFromMps
        self.speedUnitSymbol = raw.speedUnitSymbol ?? fallback.speedUnitSymbol
        self.distanceUnitSymbol = raw.distanceUnitSymbol ?? fallback.distanceUnitSymbol
        self.altitudeUnitSymbol = raw.altitudeUnitSymbol ?? fallback.altitudeUnitSymbol

        // Localized
        self.titleSteps = raw.titleSteps ?? fallback.titleSteps
        self.titleCadence = raw.titleCadence ?? fallback.titleCadence
        self.titleBalance = raw.titleBalance ?? fallback.titleBalance
        self.titleAccelerometer = raw.titleAccelerometer ?? fallback.titleAccelerometer
        self.titleGyroscope = raw.titleGyroscope ?? fallback.titleGyroscope
        self.titleGPS = raw.titleGPS ?? fallback.titleGPS

        self.instructionsSteps = raw.instructionsSteps ?? fallback.instructionsSteps
        self.instructionsCadence = raw.instructionsCadence ?? fallback.instructionsCadence
        self.instructionsBalance = raw.instructionsBalance ?? fallback.instructionsBalance
        self.instructionsAccelerometer = raw.instructionsAccelerometer ?? fallback.instructionsAccelerometer
        self.instructionsGyroscope = raw.instructionsGyroscope ?? fallback.instructionsGyroscope
        self.instructionsGPS = raw.instructionsGPS ?? fallback.instructionsGPS

        self.metricX = raw.metricX ?? fallback.metricX
        self.metricY = raw.metricY ?? fallback.metricY
        self.metricZ = raw.metricZ ?? fallback.metricZ
        self.metricRMS = raw.metricRMS ?? fallback.metricRMS
        self.metricPeak = raw.metricPeak ?? fallback.metricPeak
        self.metricSpeed = raw.metricSpeed ?? fallback.metricSpeed
        self.metricAvgSpeed = raw.metricAvgSpeed ?? fallback.metricAvgSpeed
        self.metricDistance = raw.metricDistance ?? fallback.metricDistance
        self.metricAltitude = raw.metricAltitude ?? fallback.metricAltitude
        self.metricCadence = raw.metricCadence ?? fallback.metricCadence
        self.metricDuration = raw.metricDuration ?? fallback.metricDuration
        self.metricSteps = raw.metricSteps ?? fallback.metricSteps
        self.metricFloors = raw.metricFloors ?? fallback.metricFloors
        self.metricSway = raw.metricSway ?? fallback.metricSway
        self.metricGrade = raw.metricGrade ?? fallback.metricGrade
        self.captionSway = raw.captionSway ?? fallback.captionSway

        self.buttonStart = raw.buttonStart ?? fallback.buttonStart
        self.buttonStop = raw.buttonStop ?? fallback.buttonStop
        self.buttonStartWalk = raw.buttonStartWalk ?? fallback.buttonStartWalk
        self.buttonSave = raw.buttonSave ?? fallback.buttonSave
        self.buttonSaved = raw.buttonSaved ?? fallback.buttonSaved
        self.buttonRefresh = raw.buttonRefresh ?? fallback.buttonRefresh
        self.buttonMarkComplete = raw.buttonMarkComplete ?? fallback.buttonMarkComplete
        self.buttonCompleted = raw.buttonCompleted ?? fallback.buttonCompleted

        self.warnAccelerometerUnavailable = raw.warnAccelerometerUnavailable ?? fallback.warnAccelerometerUnavailable
        self.warnGyroUnavailable = raw.warnGyroUnavailable ?? fallback.warnGyroUnavailable
        self.warnDeviceMotionUnavailable = raw.warnDeviceMotionUnavailable ?? fallback.warnDeviceMotionUnavailable
        self.warnStepsUnavailable = raw.warnStepsUnavailable ?? fallback.warnStepsUnavailable
        self.warnCadenceUnavailable = raw.warnCadenceUnavailable ?? fallback.warnCadenceUnavailable
        self.warnLocationServicesOff = raw.warnLocationServicesOff ?? fallback.warnLocationServicesOff
        self.warnLocationNotDetermined = raw.warnLocationNotDetermined ?? fallback.warnLocationNotDetermined
        self.warnLocationDenied = raw.warnLocationDenied ?? fallback.warnLocationDenied
        self.warnLocationRestricted = raw.warnLocationRestricted ?? fallback.warnLocationRestricted
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawCoreMotionConfiguration) throws -> CoreMotionConfiguration {
        CoreMotionConfiguration(from: raw)
    }
}
