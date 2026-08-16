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
import HealthKit
import OTFCareKitStore

enum SensorTaskMode: String, CaseIterable, Codable, Identifiable {
    case sensor
    case manual

    var id: String { rawValue }

    init?(persistedValue: String) {
        switch persistedValue {
        case Self.sensor.rawValue, "automatic":
            self = .sensor
        case Self.manual.rawValue:
            self = .manual
        default:
            return nil
        }
    }
}

struct SensorOutcomePayload: Equatable {
    let metric: HealthKitDataManager.HealthMetric
    let reading: HealthKitDataManager.HealthMetricValue
    let mode: SensorTaskMode
    let notes: String?
    let ecgReport: ECGReport?
    let ecgReportAttachment: ECGReportAttachment?

    init(
        metric: HealthKitDataManager.HealthMetric,
        reading: HealthKitDataManager.HealthMetricValue,
        mode: SensorTaskMode,
        notes: String? = nil,
        ecgReport: ECGReport? = nil,
        ecgReportAttachment: ECGReportAttachment? = nil
    ) {
        self.metric = metric
        self.reading = reading
        self.mode = mode
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.ecgReport = metric == .ecg && mode == .sensor ? ecgReport : nil
        self.ecgReportAttachment = metric == .ecg && mode == .sensor ? ecgReportAttachment : nil
    }

    func replacingECGReport(with attachment: ECGReportAttachment) -> SensorOutcomePayload {
        SensorOutcomePayload(
            metric: metric,
            reading: reading,
            mode: mode,
            notes: notes,
            ecgReportAttachment: attachment
        )
    }
}

enum SensorOutcomeSubmissionPolicy {
    static let maximumSensorReadingAge: TimeInterval = 15 * 60

    static func canSubmit(
        _ payload: SensorOutcomePayload,
        on scheduledDate: Date,
        now: Date = Date()
    ) -> Bool {
        guard scheduledDate <= now else { return false }
        guard payload.mode == .sensor else { return true }
        return isFreshSensorReading(payload.reading, now: now)
    }

    static func isFreshSensorReading(
        _ reading: HealthKitDataManager.HealthMetricValue,
        now: Date = Date()
    ) -> Bool {
        let age = now.timeIntervalSince(reading.date)
        return age >= 0 && age <= maximumSensorReadingAge
    }
}

enum DecodedSensorOutcome: Equatable {
    case payload(SensorOutcomePayload)
    case legacy([OCKOutcomeValue])
}

enum SensorOutcomeValueKind: String, CaseIterable {
    case bpm
    case mgPerdL
    case systolic
    case diastolic
    case unit
    case classification
    case averageBPM
    case samplingHz
    case duration
    case healthKitSampleUUID
    case lead
    case ecgReportFormat
    case ecgReportMimeType
    case ecgReportAttachmentID
    case ecgReportFileName
    case ecgReportEncryptedFileKey
    case ecgReportHashFileKey
    case breathsPerMin
    case percent
    case mlPerKgMin
    case date
    case entryMode
    case notes
}

enum SensorOutcomeUnits {
    static let bpm = "BPM"
    static let bloodGlucose = "mg/dL"
    static let bloodPressure = "mmHg"
    static let hertz = "Hz"
    static let seconds = "s"
    static let respiratoryRate = "br/min"
    static let percent = "%"
    static let vo2Max = "mL/(kg·min)"
}

enum SensorOutcomeCodec {

    static func ecgReportAttachmentID(in values: [OCKOutcomeValue]) -> String? {
        values.first {
            $0.kind == SensorOutcomeValueKind.ecgReportAttachmentID.rawValue
        }?.stringValue
    }

    static func ecgReportAttachment(in values: [OCKOutcomeValue]) -> ECGReportAttachment? {
        let valuesByKind = Dictionary(
            values.compactMap { value in
                value.kind.map { ($0, value) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        return decodeECGReportAttachment(valuesByKind: valuesByKind)
    }

    static func replacingECGReportAttachment(
        in values: [OCKOutcomeValue],
        with replacement: ECGReportAttachment
    ) -> [OCKOutcomeValue]? {
        guard ecgReportAttachment(in: values) != nil else {
            return nil
        }
        return values.map { value in
            guard value.kind == SensorOutcomeValueKind.ecgReportAttachmentID.rawValue else {
                return value
            }
            return makeValue(replacement.attachmentID, kind: .ecgReportAttachmentID)
        }
    }

    static func encode(_ payload: SensorOutcomePayload) -> [OCKOutcomeValue] {
        guard payload.metric == payload.reading.metric else { return [] }

        var values = measurementValues(for: payload.reading)
        if let attachment = payload.ecgReportAttachment {
            if let sourceSampleUUID = attachment.sourceSampleUUID {
                values.append(makeValue(sourceSampleUUID.uuidString, kind: .healthKitSampleUUID))
            }
            values.append(makeValue(attachment.lead, kind: .lead))
            values.append(makeValue(attachment.format, kind: .ecgReportFormat))
            values.append(makeValue(attachment.mimeType, kind: .ecgReportMimeType))
            values.append(makeValue(attachment.attachmentID, kind: .ecgReportAttachmentID))
            values.append(makeValue(attachment.fileName, kind: .ecgReportFileName))
            values.append(
                makeValue(attachment.encryptedFileKey, kind: .ecgReportEncryptedFileKey)
            )
            values.append(makeValue(attachment.hashFileKey, kind: .ecgReportHashFileKey))
        }
        values.append(makeValue(payload.reading.date, kind: .date))
        values.append(makeValue(payload.mode.rawValue, kind: .entryMode))
        if let notes = payload.notes {
            values.append(makeValue(notes, kind: .notes))
        }
        return values
    }

    static func decode(
        metric: HealthKitDataManager.HealthMetric,
        values: [OCKOutcomeValue]
    ) -> DecodedSensorOutcome {
        let valuesByKind = Dictionary(
            values.compactMap { value in
                value.kind.map { ($0, value) }
            },
            uniquingKeysWith: { first, _ in first }
        )

        guard
            let modeRawValue = valuesByKind[SensorOutcomeValueKind.entryMode.rawValue]?.stringValue,
            let mode = SensorTaskMode(persistedValue: modeRawValue),
            let date = valuesByKind[SensorOutcomeValueKind.date.rawValue]?.dateValue,
            let reading = decodeReading(metric: metric, valuesByKind: valuesByKind, date: date)
        else {
            return .legacy(values)
        }

        let notes = valuesByKind[SensorOutcomeValueKind.notes.rawValue]?.stringValue
        let attachment = mode == .sensor ? decodeECGReportAttachment(valuesByKind: valuesByKind) : nil
        return .payload(
            SensorOutcomePayload(
                metric: metric,
                reading: reading,
                mode: mode,
                notes: notes,
                ecgReportAttachment: attachment
            )
        )
    }

    private static func measurementValues(
        for reading: HealthKitDataManager.HealthMetricValue
    ) -> [OCKOutcomeValue] {
        switch reading {
        case .heartRate(let bpm, _):
            return [makeValue(bpm, kind: .bpm, units: SensorOutcomeUnits.bpm)]
        case .bloodGlucose(let mgPerdL, _):
            return [makeValue(mgPerdL, kind: .mgPerdL, units: SensorOutcomeUnits.bloodGlucose)]
        case .bloodPressure(let systolic, let diastolic, _, _):
            return [
                makeValue(systolic, kind: .systolic, units: SensorOutcomeUnits.bloodPressure),
                makeValue(diastolic, kind: .diastolic, units: SensorOutcomeUnits.bloodPressure),
                makeValue(SensorOutcomeUnits.bloodPressure, kind: .unit)
            ]
        case .ecg(let classification, let averageBPM, let samplingHz, let duration, _):
            var values = [
                makeValue(classification.rawValue, kind: .classification)
            ]
            if let averageBPM {
                values.append(makeValue(averageBPM, kind: .averageBPM, units: SensorOutcomeUnits.bpm))
            }
            if let samplingHz {
                values.append(makeValue(samplingHz, kind: .samplingHz, units: SensorOutcomeUnits.hertz))
            }
            if let duration {
                values.append(makeValue(duration, kind: .duration, units: SensorOutcomeUnits.seconds))
            }
            return values
        case .respiratoryRate(let breathsPerMin, _):
            return [
                makeValue(
                    breathsPerMin,
                    kind: .breathsPerMin,
                    units: SensorOutcomeUnits.respiratoryRate
                )
            ]
        case .restingHeartRate(let bpm, _):
            return [makeValue(bpm, kind: .bpm, units: SensorOutcomeUnits.bpm)]
        case .oxygenSaturation(let percent, _):
            return [makeValue(percent, kind: .percent, units: SensorOutcomeUnits.percent)]
        case .vo2Max(let mlPerKgMin, _):
            return [makeValue(mlPerKgMin, kind: .mlPerKgMin, units: SensorOutcomeUnits.vo2Max)]
        case .unavailable:
            return []
        }
    }

    private static func decodeReading(
        metric: HealthKitDataManager.HealthMetric,
        valuesByKind: [String: OCKOutcomeValue],
        date: Date
    ) -> HealthKitDataManager.HealthMetricValue? {
        switch metric {
        case .heartRate:
            guard let bpm = doubleValue(.bpm, in: valuesByKind) else { return nil }
            return .heartRate(bpm: bpm, date: date)
        case .bloodGlucose:
            guard let mgPerdL = doubleValue(.mgPerdL, in: valuesByKind) else { return nil }
            return .bloodGlucose(mgPerdL: mgPerdL, date: date)
        case .bloodPressure:
            guard
                let systolic = doubleValue(.systolic, in: valuesByKind),
                let diastolic = doubleValue(.diastolic, in: valuesByKind),
                valuesByKind[SensorOutcomeValueKind.unit.rawValue]?.stringValue ==
                    SensorOutcomeUnits.bloodPressure
            else {
                return nil
            }
            return .bloodPressure(
                systolic: systolic,
                diastolic: diastolic,
                unit: .millimeterOfMercury(),
                date: date
            )
        case .ecg:
            guard
                let rawClassification = integerValue(.classification, in: valuesByKind),
                let classification = HKElectrocardiogram.Classification(rawValue: rawClassification)
            else {
                return nil
            }
            return .ecg(
                classification: classification,
                averageBPM: doubleValue(.averageBPM, in: valuesByKind),
                samplingHz: doubleValue(.samplingHz, in: valuesByKind),
                duration: doubleValue(.duration, in: valuesByKind),
                date: date
            )
        case .respiratoryRate:
            guard let breathsPerMin = doubleValue(.breathsPerMin, in: valuesByKind) else { return nil }
            return .respiratoryRate(breathsPerMin: breathsPerMin, date: date)
        case .restingHeartRate:
            guard let bpm = doubleValue(.bpm, in: valuesByKind) else { return nil }
            return .restingHeartRate(bpm: bpm, date: date)
        case .oxygenSaturation:
            guard let percent = doubleValue(.percent, in: valuesByKind) else { return nil }
            return .oxygenSaturation(percent: percent, date: date)
        case .vo2Max:
            guard let mlPerKgMin = doubleValue(.mlPerKgMin, in: valuesByKind) else { return nil }
            return .vo2Max(mlPerKgMin: mlPerKgMin, date: date)
        }
    }

    private static func doubleValue(
        _ kind: SensorOutcomeValueKind,
        in valuesByKind: [String: OCKOutcomeValue]
    ) -> Double? {
        valuesByKind[kind.rawValue]?.doubleValue
    }

    private static func decodeECGReportAttachment(
        valuesByKind: [String: OCKOutcomeValue]
    ) -> ECGReportAttachment? {
        guard
            let attachmentID = valuesByKind[SensorOutcomeValueKind.ecgReportAttachmentID.rawValue]?
                .stringValue,
            let fileName = valuesByKind[SensorOutcomeValueKind.ecgReportFileName.rawValue]?.stringValue,
            let encryptedFileKey = valuesByKind[
                SensorOutcomeValueKind.ecgReportEncryptedFileKey.rawValue
            ]?.stringValue,
            let hashFileKey = valuesByKind[
                SensorOutcomeValueKind.ecgReportHashFileKey.rawValue
            ]?.stringValue,
            let lead = valuesByKind[SensorOutcomeValueKind.lead.rawValue]?.stringValue,
            let format = valuesByKind[SensorOutcomeValueKind.ecgReportFormat.rawValue]?.stringValue,
            let mimeType = valuesByKind[SensorOutcomeValueKind.ecgReportMimeType.rawValue]?.stringValue
        else {
            return nil
        }
        let sourceSampleUUID = valuesByKind[SensorOutcomeValueKind.healthKitSampleUUID.rawValue]?
            .stringValue
            .flatMap(UUID.init(uuidString:))
        return ECGReportAttachment(
            attachmentID: attachmentID,
            fileName: fileName,
            encryptedFileKey: encryptedFileKey,
            hashFileKey: hashFileKey,
            sourceSampleUUID: sourceSampleUUID,
            lead: lead,
            format: format,
            mimeType: mimeType
        )
    }

    private static func integerValue(
        _ kind: SensorOutcomeValueKind,
        in valuesByKind: [String: OCKOutcomeValue]
    ) -> Int? {
        valuesByKind[kind.rawValue]?.integerValue
    }

    private static func makeValue(
        _ value: OCKOutcomeValueUnderlyingType,
        kind: SensorOutcomeValueKind,
        units: String? = nil
    ) -> OCKOutcomeValue {
        var outcomeValue = OCKOutcomeValue(value, units: units)
        outcomeValue.kind = kind.rawValue
        return outcomeValue
    }
}

extension HealthKitDataManager.HealthMetricValue {
    var metric: HealthKitDataManager.HealthMetric? {
        switch self {
        case .heartRate: .heartRate
        case .bloodGlucose: .bloodGlucose
        case .bloodPressure: .bloodPressure
        case .ecg: .ecg
        case .respiratoryRate: .respiratoryRate
        case .restingHeartRate: .restingHeartRate
        case .oxygenSaturation: .oxygenSaturation
        case .vo2Max: .vo2Max
        case .unavailable: nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
