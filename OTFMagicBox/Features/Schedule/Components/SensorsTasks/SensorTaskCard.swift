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
import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI

struct SensorTaskCard: View {

    private enum FileConstants {
        static let chevronName = "chevron.right"
        static let cornerRadius: CGFloat = 14
    }

    private let config = SensorTaskConfigurationLoader.config

    let metric: HealthKitDataManager.HealthMetric
    let task: OCKAnyTask
    let hasSentOutcome: Bool
    let sentValueText: String?
    let selectedDate: Date
    let storeManager: OCKSynchronizedStoreManager
    let onTap: () -> Void

    let healthDataManager = HealthKitDataManager()

    @State private var primaryValue: HealthKitDataManager.HealthMetricValue?

    private var canSendOutcome: Bool {
        primaryValue != nil && !hasSentOutcome
    }

    var hasAuthorization: Bool {
        healthDataManager.authorizationState(for: [metric]) == .authorized
    }

    var ctaText: String {
        canSendOutcome ? config.sendResultLabel.localized : config.reviewLabel.localized
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(task.title ?? metric.id)
                        .font(.headline)

                    Spacer()

                    Image(systemName: FileConstants.chevronName)
                        .foregroundStyle(Color.secondary)
                }

                if let instructions = task.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.subheadline)
                }

                Button {
                    guard !hasSentOutcome else { return }
                    if canSendOutcome {
                        sendOutcome()
                    } else {
                        onTap()
                    }
                } label: {
                    Text(sentValueText ?? ctaText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(hasSentOutcome ? Color.accentColor : Color.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .globalStyle(hasSentOutcome ? .disabledTintColor : .tintColor)
                .padding(.top)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: FileConstants.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FileConstants.cornerRadius)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            guard hasAuthorization else { return }
            Task {
                self.primaryValue = await healthDataManager.fetchLatestValue(for: metric, limit: 1).first
            }
        }
    }

    func sendOutcome() {

        let healthSensorsConfig = HealthSensorsConfigurationLoader.config

        Task {
            guard let primaryValue else {
                onTap()
                return
            }

            let value = MetricValue(
                label: nil,
                value: primaryValue.displayValue,
                unit: metric.displayUnit(config: healthSensorsConfig),
                date: primaryValue.date,
                source: .health
            )
            SensorTaskOutcomeHelper.sendOutcome(
                value: value,
                task: task,
                on: selectedDate,
                storeManager: storeManager
            )
        }
    }
}
