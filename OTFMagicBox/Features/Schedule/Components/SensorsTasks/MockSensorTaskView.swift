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

struct MockSensorTaskView: View {

    private enum FileConstants {
        static let addSymbol = "plus.circle.fill"
        static let contentSpacing: CGFloat = 4
        static let iconSize: CGFloat = 38
        static let rowSpacing: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 4
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode = SensorTaskMode.sensor

    let selectedDate: Date

    private var healthConfig = HealthSensorsConfigurationLoader.config
    private var sensorConfig = SensorTaskConfigurationLoader.config

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(sensorConfig.sensorModeLabel.localized, selection: $selectedMode) {
                    Text(sensorConfig.sensorModeLabel.localized)
                        .tag(SensorTaskMode.sensor)
                    Text(sensorConfig.manualModeLabel.localized)
                        .tag(SensorTaskMode.manual)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, HealthSensorVisualStyle.horizontalPadding)
                .padding(
                    .vertical,
                    HealthSensorVisualStyle.segmentedControlVerticalPadding
                )

                List {
                    Section {
                        sensorButtons(mode: selectedMode)
                    } header: {
                        Text(modeDescription)
                            .textCase(nil)
                            .font(.footnote)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .background(HealthSensorVisualStyle.screenBackground)
            .navigationTitle(SensorTaskConfigurationLoader.config.mockSensorTaskTitle.localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(sensorConfig.doneLabel.localized) {
                        dismiss()
                    }
                }
            }
        }
        .globalStyle(.tintColor)
    }

    private func sensorButtons(mode: SensorTaskMode) -> some View {
        ForEach(HealthKitDataManager.HealthMetric.allCases) { metric in
            Button {
                CareKitStoreManager.shared.mockSensorTask(for: metric, mode: mode, on: selectedDate)
                dismiss()
            } label: {
                HStack(spacing: FileConstants.rowSpacing) {
                    HealthSensorMetricIcon(metric: metric, size: FileConstants.iconSize)

                    VStack(alignment: .leading, spacing: FileConstants.contentSpacing) {
                        Text(metric.displayTitle(config: healthConfig))
                            .foregroundStyle(Color.primary)
                            .globalStyle(.textFont)
                            .globalStyle(.headerFontWeight)
                        Text(metric.displaySubtitle(config: healthConfig))
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Image(systemName: FileConstants.addSymbol)
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, FileConstants.rowVerticalPadding)
            }
            .buttonStyle(.plain)
        }
    }

    private var modeDescription: String {
        switch selectedMode {
        case .sensor:
            sensorConfig.sensorDescription.localized
        case .manual:
            sensorConfig.manualDescription.localized
        }
    }
}

#Preview {
    MockSensorTaskView(selectedDate: Date())
}
