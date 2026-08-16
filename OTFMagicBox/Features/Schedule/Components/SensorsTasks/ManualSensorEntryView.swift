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
import SwiftUI

struct ManualSensorEntryView: View {

    private enum FileConstants {
        static let fieldRowSpacing: CGFloat = 12
        static let fieldVerticalPadding: CGFloat = 4
        static let submissionSpacing: CGFloat = 10
    }

    private enum FocusedField: Hashable {
        case primary
        case secondary
        case averageBPM
        case samplingHz
        case duration
        case notes
    }

    @StateObject private var viewModel: ManualSensorEntryViewModel
    @FocusState private var focusedField: FocusedField?

    private let onSubmit: (SensorOutcomePayload) -> Void
    private let scheduledDate: Date?
    private let submitLabel: String
    private let healthConfig = HealthSensorsConfigurationLoader.config
    private let sensorConfig = SensorTaskConfigurationLoader.config

    init(
        metric: HealthKitDataManager.HealthMetric,
        scheduledDate: Date? = nil,
        submitLabel: String = SensorTaskConfigurationLoader.config.sendManualResultLabel.localized,
        now: @escaping () -> Date = Date.init,
        onSubmit: @escaping (SensorOutcomePayload) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ManualSensorEntryViewModel(
                metric: metric,
                date: scheduledDate,
                scheduledDate: scheduledDate,
                now: now
            )
        )
        self.scheduledDate = scheduledDate
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HealthSensorVisualStyle.contentSpacing) {
                entryHeader
                measurementSection
                dateSection
                notesSection
                submissionSection
            }
            .padding(.horizontal, HealthSensorVisualStyle.horizontalPadding)
            .padding(.bottom, HealthSensorVisualStyle.screenBottomPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HealthSensorVisualStyle.screenBackground)
        .navigationTitle(viewModel.metric.displayTitle(config: healthConfig))
        .globalStyle(.navigationTitleDisplayMode)
        .globalStyle(.tintColor)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(sensorConfig.doneLabel.localized) {
                    focusedField = nil
                }
            }
        }
    }

    private var entryHeader: some View {
        HealthSensorSectionCard {
            VStack(alignment: .leading, spacing: FileConstants.fieldRowSpacing) {
                HStack(alignment: .top) {
                    HealthSensorMetricIcon(metric: viewModel.metric)

                    SensorModeBadge(mode: .manual)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Divider()

                Text(sensorConfig.manualDescription.localized)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var measurementSection: some View {
        VStack(alignment: .leading, spacing: HealthSensorVisualStyle.sectionLabelSpacing) {
            HealthSensorFieldSectionTitle(
                title: viewModel.metric.displayTitle(config: healthConfig)
            )

            HealthSensorSectionCard {
                measurementFields
            }

            if viewModel.metric == .ecg {
                Text(ecgOptionalFieldsFooter)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, HealthSensorVisualStyle.sectionPadding)
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: HealthSensorVisualStyle.sectionLabelSpacing) {
            HealthSensorFieldSectionTitle(title: sensorConfig.dateLabel.localized)

            HealthSensorSectionCard {
                if let scheduledDate {
                    HStack {
                        Text(sensorConfig.recordedAtLabel.localized)

                        Spacer()

                        Text(
                            scheduledDate,
                            format: .dateTime.day().month(.abbreviated).year()
                        )
                            .foregroundStyle(Color.secondary)

                        DatePicker(
                            sensorConfig.recordedAtLabel.localized,
                            selection: $viewModel.date,
                            in: ...Date(),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .font(.body)
                } else {
                    DatePicker(
                        sensorConfig.recordedAtLabel.localized,
                        selection: $viewModel.date,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(.body)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: HealthSensorVisualStyle.sectionLabelSpacing) {
            HealthSensorFieldSectionTitle(title: sensorConfig.notesLabel.localized)

            HealthSensorSectionCard {
                TextField(
                    sensorConfig.notesPlaceholder.localized,
                    text: $viewModel.notes,
                    axis: .vertical
                )
                .focused($focusedField, equals: .notes)
                .lineLimit(4...8)
                .frame(
                    minHeight: HealthSensorVisualStyle.fieldMinimumHeight,
                    alignment: .top
                )
                .accessibilityLabel(sensorConfig.notesLabel.localized)
            }
        }
    }

    private var submissionSection: some View {
        VStack(alignment: .leading, spacing: FileConstants.submissionSpacing) {
            Button {
                guard viewModel.isValid, let payload = viewModel.payload else { return }
                focusedField = nil
                onSubmit(payload)
            } label: {
                Text(submitLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isValid)

            if viewModel.hasInput, !viewModel.isValid {
                Label(sensorConfig.invalidFormMessage.localized, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var measurementFields: some View {
        switch viewModel.metric {
        case .bloodPressure:
            VStack(spacing: 0) {
                numericField(
                    healthConfig.labelSystolic.localized,
                    text: $viewModel.primaryValue,
                    field: .primary,
                    unit: SensorOutcomeUnits.bloodPressure
                )
                Divider()
                numericField(
                    healthConfig.labelDiastolic.localized,
                    text: $viewModel.secondaryValue,
                    field: .secondary,
                    unit: SensorOutcomeUnits.bloodPressure
                )
            }
        case .ecg:
            VStack(spacing: 0) {
                HStack(spacing: FileConstants.fieldRowSpacing) {
                    Text(sensorConfig.classificationLabel.localized)

                    Spacer()

                    Picker("", selection: $viewModel.ecgClassificationRawValue) {
                        Text(MetricFormatter.unavailableValue)
                            .tag(nil as Int?)
                        ForEach(HKElectrocardiogram.Classification.manualEntryCases, id: \.rawValue) { classification in
                            Text(classification.displayTitle(config: healthConfig))
                                .tag(classification.rawValue as Int?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .padding(.vertical, FileConstants.fieldVerticalPadding)
                Divider()
                numericField(
                    optionalFieldName(sensorConfig.averageBPMLabel.localized),
                    text: $viewModel.averageBPM,
                    field: .averageBPM,
                    unit: SensorOutcomeUnits.bpm
                )
                Divider()
                numericField(
                    optionalFieldName(sensorConfig.samplingHzLabel.localized),
                    text: $viewModel.samplingHz,
                    field: .samplingHz,
                    unit: SensorOutcomeUnits.hertz
                )
                Divider()
                numericField(
                    optionalFieldName(sensorConfig.durationLabel.localized),
                    text: $viewModel.duration,
                    field: .duration,
                    unit: SensorOutcomeUnits.seconds
                )
            }
        default:
            numericField(
                viewModel.metric.displayTitle(config: healthConfig),
                text: $viewModel.primaryValue,
                field: .primary,
                unit: viewModel.metric.displayUnit(config: healthConfig)
            )
        }
    }

    private func numericField(
        _ label: String,
        text: Binding<String>,
        field: FocusedField,
        unit: String
    ) -> some View {
        HStack(spacing: FileConstants.fieldRowSpacing) {
            Text(label)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)

            TextField(sensorConfig.valueLabel.localized, text: text)
                .focused($focusedField, equals: field)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .accessibilityLabel(label)

            Text(unit)
                .font(.callout)
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, FileConstants.fieldVerticalPadding)
    }

    private var ecgOptionalFieldsFooter: String {
        let localizedLabels = [
            sensorConfig.averageBPMLabel.localized,
            sensorConfig.samplingHzLabel.localized,
            sensorConfig.durationLabel.localized
        ]
        let names = localizedLabels.map(optionalFieldName).joined(separator: " · ")
        guard let optionalMarker = parentheticalSuffix(in: localizedLabels[0]) else {
            return names
        }
        return "\(optionalMarker): \(names)"
    }

    private func optionalFieldName(_ label: String) -> String {
        guard let suffixRange = label.range(
            of: #"\s*\([^)]*\)\s*$"#,
            options: .regularExpression
        ) else {
            return label
        }
        return String(label[..<suffixRange.lowerBound])
    }

    private func parentheticalSuffix(in label: String) -> String? {
        guard let openingParenthesis = label.lastIndex(of: "("),
              let closingParenthesis = label.lastIndex(of: ")"),
              openingParenthesis < closingParenthesis else {
            return nil
        }
        return String(label[label.index(after: openingParenthesis)..<closingParenthesis])
    }
}

final class ManualSensorEntryViewModel: ObservableObject {
    @Published var primaryValue = ""
    @Published var secondaryValue = ""
    @Published var averageBPM = ""
    @Published var samplingHz = ""
    @Published var duration = ""
    @Published var ecgClassificationRawValue: Int?
    @Published var date: Date
    @Published var notes = ""

    let metric: HealthKitDataManager.HealthMetric

    private let calendar: Calendar
    private let now: () -> Date
    private let scheduledDate: Date?

    init(
        metric: HealthKitDataManager.HealthMetric,
        date: Date? = nil,
        scheduledDate: Date? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.metric = metric
        self.calendar = calendar
        self.now = now
        self.scheduledDate = scheduledDate
        self.date = date ?? scheduledDate ?? now()
    }

    var payload: SensorOutcomePayload? {
        let recordingDate = recordingDate
        guard recordingDate <= now(), let reading = reading(at: recordingDate) else { return nil }
        return SensorOutcomePayload(
            metric: metric,
            reading: reading,
            mode: .manual,
            notes: notes
        )
    }

    var isValid: Bool {
        payload != nil
    }

    var hasInput: Bool {
        [
            primaryValue,
            secondaryValue,
            averageBPM,
            samplingHz,
            duration,
            notes
        ].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ||
            ecgClassificationRawValue != nil
    }

    private var recordingDate: Date {
        guard let scheduledDate else { return date }
        let time = calendar.dateComponents([.hour, .minute, .second], from: date)
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: scheduledDate
        ) ?? scheduledDate
    }

    private func reading(at date: Date) -> HealthKitDataManager.HealthMetricValue? {
        switch metric {
        case .heartRate:
            guard let value = requiredPositive(primaryValue) else { return nil }
            return .heartRate(bpm: value, date: date)
        case .bloodGlucose:
            guard let value = requiredPositive(primaryValue) else { return nil }
            return .bloodGlucose(mgPerdL: value, date: date)
        case .bloodPressure:
            guard
                let systolic = requiredPositive(primaryValue),
                let diastolic = requiredPositive(secondaryValue),
                systolic > diastolic
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
                let rawValue = ecgClassificationRawValue,
                let classification = HKElectrocardiogram.Classification(rawValue: rawValue),
                HKElectrocardiogram.Classification.manualEntryCases.contains(classification),
                let averageBPM = optionalPositive(averageBPM),
                let samplingHz = optionalPositive(samplingHz),
                let duration = optionalPositive(duration)
            else {
                return nil
            }
            return .ecg(
                classification: classification,
                averageBPM: averageBPM,
                samplingHz: samplingHz,
                duration: duration,
                date: date
            )
        case .respiratoryRate:
            guard let value = requiredPositive(primaryValue) else { return nil }
            return .respiratoryRate(breathsPerMin: value, date: date)
        case .restingHeartRate:
            guard let value = requiredPositive(primaryValue) else { return nil }
            return .restingHeartRate(bpm: value, date: date)
        case .oxygenSaturation:
            guard let value = requiredPositive(primaryValue), value <= 100 else { return nil }
            return .oxygenSaturation(percent: value, date: date)
        case .vo2Max:
            guard let value = requiredPositive(primaryValue) else { return nil }
            return .vo2Max(mlPerKgMin: value, date: date)
        }
    }

    private func requiredPositive(_ text: String) -> Double? {
        guard let value = number(from: text), value.isFinite, value > 0 else { return nil }
        return value
    }

    private func optionalPositive(_ text: String) -> Double?? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .some(nil) }
        guard let value = number(from: trimmed), value.isFinite, value > 0 else { return nil }
        return .some(value)
    }

    private func number(from text: String) -> Double? {
        Double(
            text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )
    }
}
