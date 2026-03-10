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

import Combine
import Foundation
import HealthKit
import UIKit

@MainActor
final class CardRowViewModel: ObservableObject {

    private enum FileConstants {
        static let lookbackWindow: TimeInterval = 60 * 60 * 24 * 365
        static let mockIndexSeedMultiplier: UInt64 = 1_103_515_245
        static let randomOffsetSeed: UInt64 = 12345
    }

    @Published private(set) var valueText = "--"
    @Published private(set) var detailText: String?
    @Published private(set) var timestampText: String?
    @Published private(set) var usesPlaceholderStyle = true

    private let metric: HealthKitDataManager.HealthMetric
    private let dataManager = HealthKitDataManager()
    private let config = HealthSensorsConfigurationLoader.config
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    init(metric: HealthKitDataManager.HealthMetric) {
        self.metric = metric
    }

    func start() {
        guard cancellables.isEmpty else {
            refresh()
            return
        }

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        refresh()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        cancellables.removeAll()
    }

    private func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.loadLatestSnapshot()
        }
    }

    private func loadLatestSnapshot() async {
        if MockDataStore.isEnabled {
            applyMock()
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            applyPlaceholder(value: config.statusError.localized, detail: config.emptyStateTitle.localized)
            return
        }

        switch dataManager.authorizationState(for: [metric]) {
        case .notDetermined:
            applyPlaceholder(
                value: config.statusNeedsPermission.localized,
                detail: config.buttonGrantAccess.localized
            )
            return
        case .denied:
            applyPlaceholder(
                value: config.statusAccessDenied.localized,
                detail: config.buttonOpenSettings.localized
            )
            return
        case .authorized:
            break
        }

        let values = await dataManager.fetchLatestValue(
            for: metric,
            since: FileConstants.lookbackWindow,
            limit: 1
        )

        guard !Task.isCancelled else { return }

        guard let latest = values.first else {
            applyPlaceholder(
                value: config.statusNoData.localized,
                detail: metric.displayEmptyStateMessage(config: config)
            )
            return
        }

        applyHealthValue(latest)
    }

    private func applyPlaceholder(value: String, detail: String?) {
        valueText = value
        detailText = detail
        timestampText = nil
        usesPlaceholderStyle = true
    }

    private func applyReady(value: String, detail: String?, date: Date) {
        valueText = value
        detailText = detail
        timestampText = formattedTimestamp(for: date)
        usesPlaceholderStyle = false
    }

    private func applyHealthValue(_ value: HealthKitDataManager.HealthMetricValue) {
        switch value {
        case .heartRate(let bpm, let date):
            applyReady(
                value: "\(MetricFormatter.format(bpm, decimals: 0)) \(config.unitBPM.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .bloodGlucose(let mgPerdL, let date):
            applyReady(
                value: "\(MetricFormatter.format(mgPerdL, decimals: 0)) \(config.unitMgDL.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .bloodPressure(let systolic, let diastolic, _, let date):
            applyReady(
                value: "\(MetricFormatter.format(systolic, decimals: 0))/\(MetricFormatter.format(diastolic, decimals: 0)) \(config.unitMmHg.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .ecg(let classification, let averageBPM, _, _, let date):
            let detail = averageBPM.map { bpm in
                "\(MetricFormatter.format(bpm, decimals: 0)) \(config.unitBPM.localized)"
            }
            applyReady(
                value: classification.displayTitle(config: config),
                detail: detail ?? config.cardSubtitleECG.localized,
                date: date
            )
        case .respiratoryRate(let breathsPerMin, let date):
            applyReady(
                value: "\(MetricFormatter.format(breathsPerMin, decimals: 1)) \(config.unitBreathsPerMin.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .restingHeartRate(let bpm, let date):
            applyReady(
                value: "\(MetricFormatter.format(bpm, decimals: 0)) \(config.unitBPM.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .oxygenSaturation(let percent, let date):
            applyReady(
                value: "\(MetricFormatter.format(percent, decimals: 0))\(config.unitPercent.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .vo2Max(let mlPerKgMin, let date):
            applyReady(
                value: "\(MetricFormatter.format(mlPerKgMin, decimals: 1)) \(config.unitVO2Max.localized)",
                detail: config.statusSampleBased.localized,
                date: date
            )
        case .unavailable:
            applyPlaceholder(
                value: config.statusError.localized,
                detail: metric.displayEmptyStateMessage(config: config)
            )
        }
    }

    private func applyMock() {
        let now = Date()
        var generator = mockGenerator()

        switch metric {
        case .heartRate:
            let value = Double.random(in: 60...98, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 0)) \(config.unitBPM.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .bloodGlucose:
            let value = Double.random(in: 75...146, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 0)) \(config.unitMgDL.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .bloodPressure:
            let systolic = Double.random(in: 110...142, using: &generator)
            let diastolic = Double.random(in: 70...92, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(systolic, decimals: 0))/\(MetricFormatter.format(diastolic, decimals: 0)) \(config.unitMmHg.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .ecg:
            let average = Double.random(in: 58...98, using: &generator)
            applyReady(
                value: HKElectrocardiogram.Classification.sinusRhythm.displayTitle(config: config),
                detail: "\(MetricFormatter.format(average, decimals: 0)) \(config.unitBPM.localized)",
                date: now
            )
        case .respiratoryRate:
            let value = Double.random(in: 12...20, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 1)) \(config.unitBreathsPerMin.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .restingHeartRate:
            let value = Double.random(in: 49...66, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 0)) \(config.unitBPM.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .oxygenSaturation:
            let value = Double.random(in: 94...100, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 0))\(config.unitPercent.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        case .vo2Max:
            let value = Double.random(in: 34...57, using: &generator)
            applyReady(
                value: "\(MetricFormatter.format(value, decimals: 1)) \(config.unitVO2Max.localized)",
                detail: config.statusMock.localized,
                date: now
            )
        }
    }

    private func mockGenerator() -> SeededRandomNumberGenerator {
        let index = HealthKitDataManager.HealthMetric.allCases.firstIndex(of: metric) ?? 0
        let seed = UInt64(MockDataStore.seed)
            &+ UInt64(index + 1) * FileConstants.mockIndexSeedMultiplier
            &+ FileConstants.randomOffsetSeed
        return SeededRandomNumberGenerator(seed: seed)
    }

    private func formattedTimestamp(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private extension HKElectrocardiogram.Classification {
    func displayTitle(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .notSet: config.ecgClassificationDefault.localized
        case .sinusRhythm: config.ecgClassificationSinusRhythm.localized
        case .atrialFibrillation: config.ecgClassificationAtrialFibrillation.localized
        case .inconclusiveLowHeartRate: config.ecgClassificationLowHeartRate.localized
        case .inconclusiveHighHeartRate: config.ecgClassificationHighHeartRate.localized
        case .inconclusivePoorReading, .inconclusiveOther: config.ecgClassificationInconclusive.localized
        case .unrecognized: config.ecgClassificationUnrecognized.localized
        @unknown default: config.ecgClassificationDefault.localized
        }
    }
}
