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

private enum FileConstants {
    static let emptyIconSize: CGFloat = 36
    static let emptySpacing: CGFloat = 12
    static let guidanceNumberSize: CGFloat = 26
    static let guidanceSpacing: CGFloat = 14
    static let metadataSpacing: CGFloat = 4
    static let modeSpacing: CGFloat = 8
    static let primaryValueSize: CGFloat = 52
    static let sectionSpacing: CGFloat = 12
    static let statusDotSize: CGFloat = 8
    static let statusSpacing: CGFloat = 6
    static let unitSpacing: CGFloat = 8
    static let waveformSymbol = "waveform.path.ecg"
}

struct CardShellView<Secondary: View, Chart: View, Actions: View>: View {

    let title: String
    let metric: HealthKitDataManager.HealthMetric
    let emptyTitle: String
    let emptyMessage: String
    let guidanceTitle: String
    let guidanceSteps: [String]
    let config: HealthSensorsConfiguration
    let primaryValueText: String?
    let primaryUnitText: String?
    let sampleDate: Date?
    let entryMode: SensorTaskMode
    let entryModeDescription: String
    let showsActions: Bool

    @ObservedObject private var dataSource: AnyCardDataSource

    @ViewBuilder private let secondaryContent: Secondary
    @ViewBuilder private let chartContent: Chart
    @ViewBuilder private let actionsContent: Actions

    init(
        title: String,
        metric: HealthKitDataManager.HealthMetric,
        emptyTitle: String,
        emptyMessage: String,
        guidanceTitle: String,
        guidanceSteps: [String],
        config: HealthSensorsConfiguration,
        primaryValueText: String?,
        primaryUnitText: String?,
        sampleDate: Date?,
        entryMode: SensorTaskMode,
        entryModeDescription: String,
        showsActions: Bool,
        dataSource: AnyCardDataSource,
        @ViewBuilder secondaryContent: () -> Secondary,
        @ViewBuilder chartContent: () -> Chart,
        @ViewBuilder actionsContent: () -> Actions
    ) {
        self.title = title
        self.metric = metric
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.guidanceTitle = guidanceTitle
        self.guidanceSteps = guidanceSteps
        self.config = config
        self.primaryValueText = primaryValueText
        self.primaryUnitText = primaryUnitText
        self.sampleDate = sampleDate
        self.entryMode = entryMode
        self.entryModeDescription = entryModeDescription
        self.showsActions = showsActions
        self.dataSource = dataSource
        self.secondaryContent = secondaryContent()
        self.chartContent = chartContent()
        self.actionsContent = actionsContent()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSensorVisualStyle.contentSpacing) {
                primaryMetric

                if dataSource.state == .ready {
                    HealthSensorSectionCard {
                        secondaryContent
                    }

                    if hasChartData {
                        HealthSensorSectionCard {
                            chartContent
                        }
                    }
                } else {
                    emptyState
                }

                guidanceSection

                if showsActions {
                    actionsContent
                }
            }
            .padding(.horizontal, HealthSensorVisualStyle.horizontalPadding)
            .padding(.top, HealthSensorVisualStyle.screenTopPadding)
            .padding(.bottom, HealthSensorVisualStyle.screenBottomPadding)
        }
        .background(HealthSensorVisualStyle.screenBackground)
        .navigationTitle(title)
        .globalStyle(.navigationTitleDisplayMode)
    }

    private var primaryMetric: some View {
        HealthSensorSectionCard {
            VStack(alignment: .leading, spacing: FileConstants.sectionSpacing) {
                HStack(alignment: .top) {
                    HealthSensorMetricIcon(metric: metric)

                    VStack(alignment: .trailing, spacing: FileConstants.modeSpacing) {
                        SensorModeBadge(mode: entryMode)
                        statusIndicator
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                HStack(alignment: .firstTextBaseline, spacing: FileConstants.unitSpacing) {
                    Text(primaryValueText ?? MetricFormatter.unavailableValue)
                        .font(.system(size: FileConstants.primaryValueSize, weight: .semibold))
                        .minimumScaleFactor(0.68)
                        .lineLimit(1)
                        .monospacedDigit()

                    if let unit = primaryUnitText {
                        Text(unit)
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                    }
                }

                if let metadata {
                    VStack(alignment: .leading, spacing: FileConstants.metadataSpacing) {
                        Label(
                            "\(config.labelLastUpdated.localized): \(metadata.date.formatted(date: .abbreviated, time: .shortened))",
                            systemImage: "clock"
                        )
                        Label(
                            "\(config.labelDataSource.localized): \(dataSourceLabel(for: metadata.source))",
                            systemImage: FileConstants.waveformSymbol
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                }

                Divider()

                Text(entryModeDescription)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        HealthSensorSectionCard {
            HStack(alignment: .top, spacing: FileConstants.emptySpacing) {
                Image(systemName: FileConstants.waveformSymbol)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(
                        width: FileConstants.emptyIconSize,
                        height: FileConstants.emptyIconSize
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: HealthSensorVisualStyle.sectionLabelSpacing) {
                    Text(emptyTitle)
                        .font(.headline)

                    Text(emptyMessage)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)

                    if case .error(let errorMessage) = dataSource.state {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var guidanceSection: some View {
        HealthSensorSectionCard {
            VStack(alignment: .leading, spacing: FileConstants.guidanceSpacing) {
                HealthSensorSectionTitle(title: guidanceTitle, systemImage: "lightbulb")

                ForEach(Array(zip(guidanceSteps.indices, guidanceSteps)), id: \.0) { index, step in
                    HStack(alignment: .top, spacing: FileConstants.sectionSpacing) {
                        Image(systemName: "\(index + 1).circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(
                                width: FileConstants.guidanceNumberSize,
                                height: FileConstants.guidanceNumberSize
                            )
                            .accessibilityHidden(true)

                        Text(step)
                            .font(.callout)
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var statusText: String {
        switch dataSource.state {
        case .needsPermission: config.statusNeedsPermission.localized
        case .permissionDenied: config.statusAccessDenied.localized
        case .noData: config.statusNoData.localized
        case .ready: dataSource.statusText ?? config.statusSampleBased.localized
        case .error: config.statusError.localized
        }
    }

    private var statusColor: Color {
        switch dataSource.state {
        case .needsPermission: return .orange
        case .permissionDenied: return .red
        case .noData: return .secondary
        case .error: return .red
        case .ready: return .accentColor
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: FileConstants.statusSpacing) {
            Circle()
                .fill(statusColor)
                .frame(
                    width: FileConstants.statusDotSize,
                    height: FileConstants.statusDotSize
                )
            Text(statusText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
    }

    private var hasChartData: Bool {
        dataSource.series.contains { !$0.points.isEmpty }
    }

    private var metadata: (date: Date, source: MetricSource)? {
        if let primary = dataSource.primary {
            return (primary.date, primary.source)
        }
        guard let sampleDate else { return nil }
        return (sampleDate, .health)
    }

    private func dataSourceLabel(for source: MetricSource) -> String {
        switch source {
        case .health: config.dataSourceHealth.localized
        case .watchLive: config.dataSourceWatchLive.localized
        case .mock: config.dataSourceMock.localized
        }
    }
}

#Preview {
    let viewModel = GenericHealthCardViewModel(metric: .heartRate)
    let dataSource = AnyCardDataSource(viewModel)
    CardShellView(
        title: "Heart Rate",
        metric: .heartRate,
        emptyTitle: "No Data",
        emptyMessage: "Start measuring",
        guidanceTitle: "How to",
        guidanceSteps: ["Step 1"],
        config: HealthSensorsConfigurationLoader.config,
        primaryValueText: "72",
        primaryUnitText: "BPM",
        sampleDate: Date(),
        entryMode: .sensor,
        entryModeDescription: "Read from the Health app and submitted by the user.",
        showsActions: true,
        dataSource: dataSource
    ) {
        Text("Secondary")
    } chartContent: {
        Text("Chart")
    } actionsContent: {
        HealthSensorSectionCard {
            Button("Action") {}
        }
    }
}
