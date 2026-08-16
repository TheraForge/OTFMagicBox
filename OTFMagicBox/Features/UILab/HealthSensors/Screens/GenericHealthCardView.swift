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
import SwiftUI

struct GenericHealthCardView: View {

    private enum FileConstants {
        static let deviceActionSpacing: CGFloat = 16
        static let deviceControlSpacing: CGFloat = 10
        static let freshnessSymbol = "clock.badge.exclamationmark"
        static let heartAccessSymbol = "heart.text.clipboard"
        static let heartWatchSymbol = "applewatch"
        static let notesSpacing: CGFloat = 8
        static let secondaryColumns = 3
        static let secondarySpacing: CGFloat = 12
        static let submissionSpacing: CGFloat = 10
        static let valueDecimals = 0
        static let watchStatusPadding: CGFloat = 12
    }

    private let metric: HealthKitDataManager.HealthMetric
    private let onSendOutcome: ((SensorOutcomePayload) -> Void)?
    private let sendOutcomeDisabled: Bool
    private let outcomeActionLabel: String
    private let scheduledDate: Date?
    private let now: () -> Date
    private let kitConfig = HealthSensorsConfigurationLoader.config
    private let sensorConfig = SensorTaskConfigurationLoader.config

    @StateObject private var viewModel: GenericHealthCardViewModel
    @StateObject private var dataSource: AnyCardDataSource
    @State private var notes = ""

    init(
        metric: HealthKitDataManager.HealthMetric,
        onSendOutcome: ((SensorOutcomePayload) -> Void)? = nil,
        sendOutcomeDisabled: Bool = false,
        outcomeActionLabel: String = HealthSensorsConfigurationLoader.config.buttonSendOutcome.localized,
        scheduledDate: Date? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.metric = metric
        self.onSendOutcome = onSendOutcome
        self.sendOutcomeDisabled = sendOutcomeDisabled
        self.outcomeActionLabel = outcomeActionLabel
        self.scheduledDate = scheduledDate
        self.now = now
        let viewModel = GenericHealthCardViewModel(metric: metric)
        _viewModel = StateObject(wrappedValue: viewModel)
        _dataSource = StateObject(wrappedValue: AnyCardDataSource(viewModel))
    }

    var body: some View {
        CardShellView(
            title: metric.displayTitle(config: kitConfig),
            metric: metric,
            emptyTitle: metric.displayEmptyStateTitle(config: kitConfig),
            emptyMessage: metric.displayEmptyStateMessage(config: kitConfig),
            guidanceTitle: kitConfig.labelHowToUpdate.localized,
            guidanceSteps: metric.displayGuidanceSteps(config: kitConfig),
            config: kitConfig,
            primaryValueText: primaryValueText,
            primaryUnitText: primaryUnitText,
            sampleDate: viewModel.latestReading?.date,
            entryMode: .sensor,
            entryModeDescription: sensorConfig.sensorDescription.localized,
            showsActions: showsActions,
            dataSource: dataSource
        ) {
            VStack(alignment: .leading, spacing: FileConstants.secondarySpacing) {
                if let reading = viewModel.latestReading {
                    SensorReadingDetailsView(reading: reading)
                }
                if metric != .ecg {
                    secondaryMetrics
                }
            }
        } chartContent: {
            if let report = viewModel.ecgReport {
                ECGReportInlineView(report: report)
            } else {
                MetricSeriesChartView(
                    series: dataSource.series,
                    chartType: metric.chartType,
                    tint: .accentColor
                )
            }
        } actionsContent: {
            actionSections
        }
        .onAppear(perform: dataSource.start)
        .onDisappear(perform: dataSource.stop)
        .globalStyle(.tintColor)
    }

    private var primaryValueText: String? {
        if let reading = viewModel.latestReading {
            switch reading {
            case .bloodPressure:
                return reading.compactSummary(config: kitConfig)
            case .ecg(let classification, _, _, _, _):
                return classification.displayTitle(config: kitConfig)
            default:
                break
            }
        }
        guard let primary = dataSource.primary else { return nil }
        return MetricFormatter.format(primary.value, decimals: FileConstants.valueDecimals)
    }

    private var primaryUnitText: String? {
        guard let reading = viewModel.latestReading else {
            return dataSource.primary?.unit
        }
        switch reading {
        case .bloodPressure, .ecg:
            return nil
        default:
            return dataSource.primary?.unit
        }
    }

    private var isPrimaryRecent: Bool {
        guard let reading = viewModel.latestReading else { return false }
        return SensorOutcomeSubmissionPolicy.isFreshSensorReading(reading, now: now())
    }

    private var canSubmitLatestReading: Bool {
        guard let payload = latestPayload else { return false }
        let currentDate = now()
        return SensorOutcomeSubmissionPolicy.canSubmit(
            payload,
            on: scheduledDate ?? currentDate,
            now: currentDate
        )
    }

    private var latestPayload: SensorOutcomePayload? {
        guard let reading = viewModel.latestReading else { return nil }
        return SensorOutcomePayload(
            metric: metric,
            reading: reading,
            mode: .sensor,
            notes: notes,
            ecgReport: viewModel.ecgReport
        )
    }

    private var showsActions: Bool {
        dataSource.state == .needsPermission || metric == .heartRate || onSendOutcome != nil
    }

    private var actionSections: some View {
        VStack(alignment: .leading, spacing: FileConstants.secondarySpacing) {
            if dataSource.state == .needsPermission || metric == .heartRate {
                HealthSensorSectionCard {
                    deviceActions
                }
            }

            if onSendOutcome != nil {
                notesSection
                submissionSection
            }
        }
    }

    private var deviceActions: some View {
        VStack(alignment: .leading, spacing: FileConstants.deviceActionSpacing) {
            if dataSource.state == .needsPermission {
                VStack(alignment: .leading, spacing: FileConstants.deviceControlSpacing) {
                    HealthSensorSectionTitle(
                        title: kitConfig.labelHealthAccessRequired.localized,
                        systemImage: FileConstants.heartAccessSymbol
                    )

                    Button(kitConfig.buttonGrantAccess.localized, action: dataSource.requestPermission)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if dataSource.state == .needsPermission, metric == .heartRate {
                Divider()
            }

            if metric == .heartRate {
                VStack(alignment: .leading, spacing: FileConstants.deviceControlSpacing) {
                    HealthSensorSectionTitle(
                        title: kitConfig.buttonStartLiveMeasurement.localized,
                        systemImage: FileConstants.heartWatchSymbol
                    )

                    Button(kitConfig.buttonStartLiveMeasurement.localized) {
                        viewModel.startLiveMeasurementOnWatch()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    WatchConnectivityStatusView()
                        .padding(.vertical, FileConstants.watchStatusPadding / 2)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: FileConstants.notesSpacing) {
            HealthSensorFieldSectionTitle(title: sensorConfig.notesLabel.localized)

            HealthSensorSectionCard {
                TextField(
                    sensorConfig.notesPlaceholder.localized,
                    text: $notes,
                    axis: .vertical
                )
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
            Button(action: sendOutcome) {
                Text(outcomeActionLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(
                sendOutcomeDisabled ||
                    !canSubmitLatestReading ||
                    viewModel.isPreparingECGReport
            )

            if viewModel.latestReading != nil, !isPrimaryRecent {
                Label(
                    kitConfig.labelOutcomeFreshnessHint.localized,
                    systemImage: FileConstants.freshnessSymbol
                )
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func sendOutcome() {
        guard let payload = latestPayload, let onSendOutcome else { return }
        let currentDate = now()
        guard SensorOutcomeSubmissionPolicy.canSubmit(
            payload,
            on: scheduledDate ?? currentDate,
            now: currentDate
        ) else { return }
        onSendOutcome(payload)
    }

    private var secondaryMetrics: some View {
        let metrics = dataSource.secondary
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: FileConstants.secondarySpacing),
            count: FileConstants.secondaryColumns
        )
        return LazyVGrid(
            columns: columns,
            spacing: FileConstants.secondarySpacing
        ) {
            ForEach(metrics) { metric in
                MetricChipView(
                    label: metric.label ?? "",
                    value: "\(MetricFormatter.format(metric.value, decimals: FileConstants.valueDecimals)) \(metric.unit)"
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        GenericHealthCardView(metric: .heartRate)
    }
}
