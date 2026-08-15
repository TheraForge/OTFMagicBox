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

final class SensorTaskQuickSendState: ObservableObject {
    typealias Submission = (@escaping (Bool) -> Void) -> Void

    @Published private(set) var isSubmitting = false
    @Published private(set) var submissionFailed = false

    func submit(using submission: Submission) {
        guard !isSubmitting else { return }

        isSubmitting = true
        submissionFailed = false
        submission { [weak self] success in
            self?.isSubmitting = false
            self?.submissionFailed = !success
        }
    }
}

struct SensorTaskCard: View {

    private enum FileConstants {
        static let actionCornerRadius: CGFloat = 10
        static let actionHorizontalPadding: CGFloat = 14
        static let actionOuterPadding: CGFloat = 14
        static let actionVerticalPadding: CGFloat = 12
        static let cardPadding: CGFloat = 14
        static let chevronName = "chevron.right"
        static let checkmarkName = "checkmark.circle.fill"
        static let contentSpacing: CGFloat = 12
        static let detailSpacing: CGFloat = 4
        static let errorSymbol = "exclamationmark.triangle.fill"
        static let headerSpacing: CGFloat = 12
        static let minimumSpacerLength: CGFloat = 8
        static let paperplaneName = "paperplane.fill"
        static let rightArrowName = "arrow.right"
        static let summarySpacing: CGFloat = 8
        static let waveformName = "waveform.path.ecg"
    }

    private let config = SensorTaskConfigurationLoader.config

    let metric: HealthKitDataManager.HealthMetric
    let mode: SensorTaskMode
    let task: OCKAnyTask
    let occurrence: Int
    let scheduledStart: Date
    let showsScheduledTime: Bool
    let hasSentOutcome: Bool
    let sentValueText: String?
    let selectedDate: Date
    let storeManager: OCKSynchronizedStoreManager
    let onTap: () -> Void

    private let healthDataManager = HealthKitDataManager()

    @State private var latestReading: HealthKitDataManager.HealthMetricValue?
    @StateObject private var quickSendState = SensorTaskQuickSendState()

    private var canSendOutcome: Bool {
        guard mode == .sensor, let latestReading, !hasSentOutcome else {
            return false
        }
        return SensorOutcomeSubmissionPolicy.canSubmit(
            SensorOutcomePayload(
                metric: metric,
                reading: latestReading,
                mode: .sensor
            ),
            on: selectedDate
        )
    }

    private var hasAuthorization: Bool {
        healthDataManager.authorizationState(for: [metric]) == .authorized
    }

    private var ctaText: String {
        switch (mode, canSendOutcome) {
        case (.sensor, true):
            config.sendResultLabel.localized
        case (.manual, _):
            config.enterManuallyLabel.localized
        default:
            config.reviewLabel.localized
        }
    }

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: HealthSensorVisualStyle.cardCornerRadius,
            style: .continuous
        )

        VStack(spacing: 0) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: FileConstants.contentSpacing) {
                    HStack(alignment: .top, spacing: FileConstants.headerSpacing) {
                        VStack(alignment: .leading, spacing: FileConstants.detailSpacing) {
                            Text(task.title ?? metric.id)
                                .font(.headline)
                                .foregroundStyle(Color.primary)

                            if let instructions = task.instructions, !instructions.isEmpty {
                                Text(instructions)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: FileConstants.minimumSpacerLength)

                        VStack(alignment: .trailing, spacing: FileConstants.summarySpacing) {
                            SensorModeBadge(mode: mode)

                            if showsScheduledTime {
                                Text(scheduledStart, format: .dateTime.hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .monospacedDigit()
                            }

                            Image(systemName: FileConstants.chevronName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    if let summary = readingSummary {
                        Divider()

                        HStack(spacing: FileConstants.summarySpacing) {
                            Image(
                                systemName: hasSentOutcome ?
                                    FileConstants.checkmarkName :
                                    FileConstants.waveformName
                            )
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                            Text(summary)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(FileConstants.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, FileConstants.cardPadding)

            Button(action: performPrimaryAction) {
                HStack {
                    Text(primaryActionText)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if quickSendState.isSubmitting {
                        ProgressView()
                            .tint(Color.white)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: primaryActionSymbol)
                    }
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, FileConstants.actionHorizontalPadding)
                .padding(.vertical, FileConstants.actionVerticalPadding)
                .frame(maxWidth: .infinity)
                .background(
                    Color.accentColor,
                    in: .rect(cornerRadius: FileConstants.actionCornerRadius)
                )
            }
            .buttonStyle(.plain)
            .disabled(quickSendState.isSubmitting)
            .padding(FileConstants.actionOuterPadding)

            if quickSendState.submissionFailed {
                Label(config.outcomeLoadError.localized, systemImage: FileConstants.errorSymbol)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FileConstants.actionOuterPadding)
                    .padding(.bottom, FileConstants.actionOuterPadding)
            }
        }
        .background(HealthSensorVisualStyle.cardBackground, in: shape)
        .overlay {
            shape
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
        .shadow(
            color: Color.black.opacity(HealthSensorVisualStyle.cardShadowOpacity),
            radius: HealthSensorVisualStyle.cardShadowRadius,
            y: HealthSensorVisualStyle.cardShadowYOffset
        )
        .task(id: readingRequestID) {
            latestReading = nil
            guard mode == .sensor, hasAuthorization else { return }
            latestReading = await healthDataManager.fetchLatestValue(for: metric, limit: 1).first
        }
    }

    private var readingSummary: String? {
        if hasSentOutcome {
            return sentValueText
        }
        return latestReading?.compactSummary(config: HealthSensorsConfigurationLoader.config)
    }

    private var primaryActionSymbol: String {
        if hasSentOutcome {
            return FileConstants.chevronName
        }
        return canSendOutcome ? FileConstants.paperplaneName : FileConstants.rightArrowName
    }

    private var primaryActionText: String {
        hasSentOutcome ? config.reviewLabel.localized : ctaText
    }

    private var readingRequestID: String {
        [
            metric.id,
            task.id,
            "\(occurrence)",
            selectedDate.ISO8601Format()
        ].joined(separator: "-")
    }

    private func performPrimaryAction() {
        guard !quickSendState.isSubmitting else { return }
        if hasSentOutcome {
            onTap()
        } else if canSendOutcome {
            sendOutcome()
        } else {
            onTap()
        }
    }

    private func sendOutcome() {
        guard let latestReading else {
            onTap()
            return
        }

        quickSendState.submit { completion in
            Task {
                let ecgReport: ECGReport?
                if metric == .ecg,
                   let waveform = await healthDataManager.fetchECGWaveform(for: latestReading.date) {
                    ecgReport = ECGReportRenderer().makeReport(
                        reading: latestReading,
                        waveform: waveform
                    )
                } else {
                    ecgReport = nil
                }

                SensorTaskOutcomeHelper.sendOutcome(
                    payload: SensorOutcomePayload(
                        metric: metric,
                        reading: latestReading,
                        mode: .sensor,
                        ecgReport: ecgReport
                    ),
                    task: task,
                    on: selectedDate,
                    occurrence: occurrence,
                    storeManager: storeManager,
                    completion: completion
                )
            }
        }
    }
}
