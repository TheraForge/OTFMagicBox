/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import Foundation
import Testing
@testable import OTFMagicBox

@Suite("CheckUp domain models")
struct CheckUpDomainModelTests {
    @Test("Category summaries calculate zero and fractional progress")
    func categorySummariesCalculateZeroAndFractionalProgress() {
        #expect(CategorySummary.zero.progress == 0)
        #expect(CategorySummary(totalTasks: 0, completedTasks: 3).progress == 0)
        #expect(CategorySummary(totalTasks: 4, completedTasks: 3).progress == 0.75)
    }
}

@Suite("Schedule domain models")
struct ScheduleDomainModelTests {
    @Test("Schedule task type raw values remain stable for persisted group identifiers")
    func scheduleTaskTypeRawValuesRemainStableForPersistedGroupIdentifiers() throws {
        let rawValues = [
            "simple", "instruction", "buttonLog", "grid", "checklist",
            "steps", "cadence", "balance", "accelerometer", "gyroscope", "gps",
            "heartRate", "bloodGlucose", "bloodPressure", "ecg", "respiratoryRate",
            "restingHeartRate", "oxygenSaturation", "vo2Max",
            "manualHeartRate", "manualBloodGlucose", "manualBloodPressure", "manualECG",
            "manualRespiratoryRate", "manualRestingHeartRate", "manualOxygenSaturation",
            "manualVO2Max"
        ]
        let decoded = try rawValues.map { rawValue in
            try JSONDecoder().decode(ScheduleTaskType.self, from: Data("\"\(rawValue)\"".utf8))
        }

        #expect(decoded.map(\.rawValue) == rawValues)
    }
}
