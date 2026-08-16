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

import SwiftUI
import OTFCareKitStore

struct SensorModeBadge: View {
    private enum FileConstants {
        static let manualSymbol = "square.and.pencil"
        static let sensorSymbol = "waveform.path.ecg"
        static let unknownSymbol = "questionmark.circle"
    }

    let mode: SensorTaskMode?

    private let config = SensorTaskConfigurationLoader.config

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .labelStyle(.titleAndIcon)
    }

    private var label: String {
        switch mode {
        case .sensor: config.sensorModeLabel.localized
        case .manual: config.manualModeLabel.localized
        case nil: config.unknownModeLabel.localized
        }
    }

    private var symbol: String {
        switch mode {
        case .sensor: FileConstants.sensorSymbol
        case .manual: FileConstants.manualSymbol
        case nil: FileConstants.unknownSymbol
        }
    }
}

struct SensorReadingDetailsView: View {
    private enum FileConstants {
        static let rowVerticalPadding: CGFloat = 6
    }

    let reading: HealthKitDataManager.HealthMetricValue
    var showsRecordedDate = true

    private let healthConfig = HealthSensorsConfigurationLoader.config
    private let sensorConfig = SensorTaskConfigurationLoader.config

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, field in
                LabeledContent(field.label, value: field.value)
                    .font(.callout)
                    .padding(.vertical, FileConstants.rowVerticalPadding)

                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var rows: [SensorReadingField] {
        var rows = fields
        if showsRecordedDate {
            rows.append(
                SensorReadingField(
                    label: sensorConfig.recordedAtLabel.localized,
                    value: reading.date.formatted(date: .abbreviated, time: .shortened)
                )
            )
        }
        return rows
    }

    private var fields: [SensorReadingField] {
        switch reading {
        case .heartRate(let bpm, _):
            return [
                field(healthConfig.cardTitleHeartRate.localized, bpm, unit: healthConfig.unitBPM.localized)
            ]
        case .bloodGlucose(let mgPerdL, _):
            return [
                field(
                    healthConfig.cardTitleBloodGlucose.localized,
                    mgPerdL,
                    unit: healthConfig.unitMgDL.localized
                )
            ]
        case .bloodPressure(let systolic, let diastolic, _, _):
            return [
                field(healthConfig.labelSystolic.localized, systolic, unit: healthConfig.unitMmHg.localized),
                field(healthConfig.labelDiastolic.localized, diastolic, unit: healthConfig.unitMmHg.localized),
                SensorReadingField(
                    label: sensorConfig.unitLabel.localized,
                    value: healthConfig.unitMmHg.localized
                )
            ]
        case .ecg(let classification, let averageBPM, let samplingHz, let duration, _):
            var fields = [
                SensorReadingField(
                    label: sensorConfig.classificationLabel.localized,
                    value: classification.displayTitle(config: healthConfig)
                )
            ]
            if let averageBPM {
                fields.append(field(sensorConfig.averageBPMLabel.localized, averageBPM, unit: healthConfig.unitBPM.localized))
            }
            if let samplingHz {
                fields.append(field(sensorConfig.samplingHzLabel.localized, samplingHz, unit: SensorOutcomeUnits.hertz))
            }
            if let duration {
                fields.append(field(sensorConfig.durationLabel.localized, duration, unit: SensorOutcomeUnits.seconds))
            }
            return fields
        case .respiratoryRate(let breathsPerMin, _):
            return [
                field(
                    healthConfig.cardTitleRespiratoryRate.localized,
                    breathsPerMin,
                    unit: healthConfig.unitBreathsPerMin.localized
                )
            ]
        case .restingHeartRate(let bpm, _):
            return [
                field(
                    healthConfig.cardTitleRestingHeartRate.localized,
                    bpm,
                    unit: healthConfig.unitBPM.localized
                )
            ]
        case .oxygenSaturation(let percent, _):
            return [
                field(
                    healthConfig.cardTitleOxygenSaturation.localized,
                    percent,
                    unit: healthConfig.unitPercent.localized
                )
            ]
        case .vo2Max(let mlPerKgMin, _):
            return [
                field(
                    healthConfig.cardTitleVO2Max.localized,
                    mlPerKgMin,
                    unit: healthConfig.unitVO2Max.localized
                )
            ]
        case .unavailable(let message):
            return [
                SensorReadingField(label: healthConfig.statusError.localized, value: message)
            ]
        }
    }

    private func field(_ label: String, _ value: Double, unit: String) -> SensorReadingField {
        SensorReadingField(
            label: label,
            value: "\(MetricFormatter.format(value, decimals: value.rounded() == value ? 0 : 1)) \(unit)"
        )
    }
}

struct SensorOutcomeSummaryView: View {
    private enum FileConstants {
        static let checkmarkSymbol = "checkmark.circle.fill"
        static let headerContentSpacing: CGFloat = 6
        static let headerIconSize: CGFloat = 58
        static let headerSpacing: CGFloat = 14
        static let notesSpacing: CGFloat = 10
        static let reportStatusSpacing: CGFloat = 12
    }

    let metric: HealthKitDataManager.HealthMetric
    let outcome: DecodedSensorOutcome
    let submittedAt: Date?
    let ecgReportState: ECGReportLoadState
    let retryECGReport: () -> Void

    private let config = SensorTaskConfigurationLoader.config

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: HealthSensorVisualStyle.contentSpacing
            ) {
                HealthSensorSectionCard {
                    HStack(spacing: FileConstants.headerSpacing) {
                        ZStack(alignment: .bottomTrailing) {
                            HealthSensorMetricIcon(
                                metric: metric,
                                size: FileConstants.headerIconSize
                            )
                            Image(systemName: FileConstants.checkmarkSymbol)
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .background(Color(.systemBackground), in: Circle())
                        }

                        VStack(
                            alignment: .leading,
                            spacing: FileConstants.headerContentSpacing
                        ) {
                            Text(config.submittedResultLabel.localized)
                                .font(.title2.weight(.semibold))
                            SensorModeBadge(mode: mode)
                        }
                    }
                }

                switch outcome {
                case .payload(let payload):
                    HealthSensorSectionCard {
                        SensorReadingDetailsView(reading: payload.reading)
                    }

                    switch ecgReportState {
                    case .loaded(let report):
                        HealthSensorSectionCard {
                            ECGReportInlineView(report: report)
                        }
                    case .loading:
                        HealthSensorSectionCard {
                            HStack(spacing: FileConstants.reportStatusSpacing) {
                                ProgressView()
                                Text(config.loadingLabel.localized)
                                    .foregroundStyle(Color.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    case .failed:
                        HealthSensorSectionCard {
                            VStack(
                                alignment: .leading,
                                spacing: FileConstants.reportStatusSpacing
                            ) {
                                Label(
                                    config.outcomeLoadError.localized,
                                    systemImage: "exclamationmark.triangle.fill"
                                )
                                .foregroundStyle(Color.red)

                                Button(config.retryLabel.localized, action: retryECGReport)
                                    .buttonStyle(.bordered)
                            }
                        }
                    case .unavailable:
                        EmptyView()
                    }

                    if let notes = payload.notes {
                        HealthSensorSectionCard {
                            VStack(alignment: .leading, spacing: FileConstants.notesSpacing) {
                                HealthSensorSectionTitle(
                                    title: config.notesLabel.localized,
                                    systemImage: "note.text"
                                )
                                Text(notes)
                                    .font(.body)
                            }
                        }
                    }
                case .legacy(let values):
                    HealthSensorSectionCard {
                        LegacySensorOutcomeValuesView(values: values)
                    }
                }

                if let submittedAt {
                    HealthSensorSectionCard {
                        LabeledContent(
                            config.submittedAtLabel.localized,
                            value: submittedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        .font(.callout)
                    }
                }
            }
            .padding(.horizontal, HealthSensorVisualStyle.horizontalPadding)
            .padding(.top, HealthSensorVisualStyle.screenTopPadding)
            .padding(.bottom, HealthSensorVisualStyle.screenBottomPadding)
        }
        .background(HealthSensorVisualStyle.screenBackground)
    }

    private var mode: SensorTaskMode? {
        guard case .payload(let payload) = outcome else { return nil }
        return payload.mode
    }
}

struct SensorOutcomePayloadPreviewView: View {
    private enum FileConstants {
        static let typeDetailSpacing: CGFloat = 4
        static let valueSpacing: CGFloat = 3
    }

    @Environment(\.dismiss) private var dismiss

    let payload: SensorOutcomePayload

    private let config = SensorTaskConfigurationLoader.config

    var body: some View {
        NavigationStack {
            List {
                if let report = payload.ecgReport {
                    Section(ECGReportCopy.generatedReport) {
                        ECGReportInlineView(report: report)
                    }
                }

                Section {
                    ForEach(Array(SensorOutcomeCodec.encode(payload).enumerated()), id: \.offset) { _, value in
                        LabeledContent {
                            VStack(
                                alignment: .trailing,
                                spacing: FileConstants.valueSpacing
                            ) {
                                Text(previewValue(value))
                                    .font(.body.monospacedDigit())
                                HStack(spacing: FileConstants.typeDetailSpacing) {
                                    Text(String(describing: value.type))
                                    if let units = value.units {
                                        Text("· \(units)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            }
                        } label: {
                            Text(value.kind ?? config.valueLabel.localized)
                                .font(.headline)
                        }
                    }
                } header: {
                    HStack {
                        Text(payload.metric.displayTitle(
                            config: HealthSensorsConfigurationLoader.config
                        ))
                        Spacer()
                        SensorModeBadge(mode: payload.mode)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(HealthSensorVisualStyle.screenBackground)
            .navigationTitle(config.payloadPreviewTitle.localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(config.doneLabel.localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func previewValue(_ value: OCKOutcomeValue) -> String {
        if let date = value.dateValue {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        if let data = value.dataValue {
            return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        }
        return value.description
    }
}

private struct LegacySensorOutcomeValuesView: View {
    private enum FileConstants {
        static let rowSpacing: CGFloat = 10
    }

    let values: [OCKOutcomeValue]
    private let config = SensorTaskConfigurationLoader.config

    var body: some View {
        VStack(alignment: .leading, spacing: FileConstants.rowSpacing) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                LabeledContent(
                    value.kind ?? "\(config.valueLabel.localized) \(index + 1)",
                    value: formatted(value)
                )
                .font(.callout)
            }
        }
    }

    private func formatted(_ value: OCKOutcomeValue) -> String {
        let units = value.units.map { " \($0)" } ?? ""
        if let date = value.dateValue {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return value.description + units
    }
}

private struct SensorReadingField: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}
