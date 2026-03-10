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

private enum CardShellConstants {
    static let contentSpacing: CGFloat = 20
    static let sectionSpacing: CGFloat = 12
    static let primaryValueSize: CGFloat = 48
    static let unitOffset: CGFloat = 8
    static let guidanceSpacing: CGFloat = 8
    static let statusDotSize: CGFloat = 8
    static let statusSpacing: CGFloat = 6
}

struct CardShellView<Secondary: View, Chart: View, Actions: View>: View {

    let title: String
    let emptyTitle: String
    let emptyMessage: String
    let guidanceTitle: String
    let guidanceSteps: [String]
    let config: HealthSensorsConfiguration
    let primaryValueText: String?
    let primaryUnitText: String?

    @ObservedObject var dataSource: AnyCardDataSource

    @ViewBuilder let secondaryContent: () -> Secondary
    @ViewBuilder let chartContent: () -> Chart
    @ViewBuilder let actionsContent: () -> Actions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CardShellConstants.contentSpacing) {
                primaryMetric

                if dataSource.state == .ready {
                    secondaryContent()
                    chartContent()
                } else {
                    emptyState
                }

                guidanceSection
                actionsContent()
            }
            .padding(.horizontal)
        }
        .navigationTitle(title)
        .globalStyle(.navigationTitleDisplayMode)
    }

    private var primaryMetric: some View {
        VStack(alignment: .leading, spacing: CardShellConstants.sectionSpacing) {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: CardShellConstants.unitOffset) {
                    Text(primaryValueText ?? "--")
                        .font(.system(size: CardShellConstants.primaryValueSize, weight: .semibold))

                    if let unit = primaryUnitText {
                        Text(unit)
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                    }
                }

                statusIndicator
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if let primary = dataSource.primary {
                VStack(alignment: .leading, spacing: CardShellConstants.guidanceSpacing) {
                    Text("\(config.labelLastUpdated.localized): \(primary.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)

                    Text("\(config.labelDataSource.localized): \(dataSourceLabel(for: primary.source))")
                        .font(.caption)
                }
                .foregroundStyle(Color.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: CardShellConstants.guidanceSpacing) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: CardShellConstants.guidanceSpacing) {
            Text(guidanceTitle)
                .font(.headline)

            VStack(alignment: .leading, spacing: CardShellConstants.guidanceSpacing) {
                ForEach(guidanceSteps, id: \.self) { step in
                    HStack(alignment: .top, spacing: CardShellConstants.guidanceSpacing) {
                        Text("• " + step)
                            .font(.callout)
                            .foregroundStyle(.secondary)
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
        case .noData: return .gray
        case .error: return .red
        case .ready:
            if dataSource.statusText == config.statusLive.localized {
                return .teal
            }
            if dataSource.statusText == config.statusMock.localized {
                return .orange
            }
            return .blue
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: CardShellConstants.statusSpacing) {
            Circle()
                .fill(statusColor)
                .frame(width: CardShellConstants.statusDotSize, height: CardShellConstants.statusDotSize)
            Text(statusText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
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
        emptyTitle: "No Data",
        emptyMessage: "Start measuring",
        guidanceTitle: "How to",
        guidanceSteps: ["Step 1"],
        config: HealthSensorsConfigurationLoader.config,
        primaryValueText: "72",
        primaryUnitText: "BPM",
        dataSource: dataSource
    ) {
        Text("Secondary")
    } chartContent: {
        Text("Chart")
    } actionsContent: {
        Button("Action") {}
    }
}
