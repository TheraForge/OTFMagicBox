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
        static let valueDecimals = 0
        static let secondaryColumns = 3
        static let secondarySpacing: CGFloat = 12
        static let outcomeFreshnessMinutes = 15
        static let outcomeFreshnessInterval: TimeInterval = 15 * 60
    }

    private let metric: HealthKitDataManager.HealthMetric
    private let onSendOutcome: ((MetricValue) -> Void)?
    private let sendOutcomeDisabled: Bool
    private let kitConfig = HealthSensorsConfigurationLoader.config

    @StateObject private var viewModel: GenericHealthCardViewModel
    @StateObject private var dataSource: AnyCardDataSource

    init(
        metric: HealthKitDataManager.HealthMetric,
        onSendOutcome: ((MetricValue) -> Void)? = nil,
        sendOutcomeDisabled: Bool = false
    ) {
        self.metric = metric
        self.onSendOutcome = onSendOutcome
        self.sendOutcomeDisabled = sendOutcomeDisabled
        let viewModel = GenericHealthCardViewModel(metric: metric)
        _viewModel = StateObject(wrappedValue: viewModel)
        _dataSource = StateObject(wrappedValue: AnyCardDataSource(viewModel))
    }

    var body: some View {
        CardShellView(
            title: metric.displayTitle(config: kitConfig),
            emptyTitle: metric.displayEmptyStateTitle(config: kitConfig),
            emptyMessage: metric.displayEmptyStateMessage(config: kitConfig),
            guidanceTitle: kitConfig.labelHowToUpdate.localized,
            guidanceSteps: metric.displayGuidanceSteps(config: kitConfig),
            config: kitConfig,
            primaryValueText: primaryValueText,
            primaryUnitText: dataSource.primary?.unit,
            dataSource: dataSource
        ) {
            secondaryMetrics
        } chartContent: {
            MetricSeriesChartView(
                series: dataSource.series,
                chartType: metric.chartType
            )
        } actionsContent: {
            VStack(alignment: .leading, spacing: FileConstants.secondarySpacing) {
                if dataSource.state == .needsPermission {
                    Button(kitConfig.buttonGrantAccess.localized, action: dataSource.requestPermission)
                        .buttonStyle(.borderedProminent)
                }

                if metric == .heartRate {
                    Button(kitConfig.buttonStartLiveMeasurement.localized) {
                        viewModel.startLiveMeasurementOnWatch()
                    }
                    .buttonStyle(.bordered)

                    WatchConnectivityStatusView()
                }

                if let onSendOutcome {
                    Button(kitConfig.buttonSendOutcome.localized) {
                        guard let primary = dataSource.primary else { return }
                        onSendOutcome(primary)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sendOutcomeDisabled || dataSource.primary == nil)

                    if dataSource.primary != nil, !isPrimaryRecent {
                        Text(kitConfig.labelOutcomeFreshnessHint.localized)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .onAppear(perform: dataSource.start)
        .onDisappear(perform: dataSource.stop)
        .globalStyle(.tintColor)
    }

    private var primaryValueText: String? {
        guard let primary = dataSource.primary else { return nil }
        return MetricFormatter.format(primary.value, decimals: FileConstants.valueDecimals)
    }

    private var isPrimaryRecent: Bool {
        guard let primary = dataSource.primary else { return false }
        let age = abs(Date().timeIntervalSince(primary.date))
        return age <= FileConstants.outcomeFreshnessInterval
    }

    private var secondaryMetrics: some View {
        let metrics = dataSource.secondary
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FileConstants.secondarySpacing), count: FileConstants.secondaryColumns), spacing: FileConstants.secondarySpacing) {
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
