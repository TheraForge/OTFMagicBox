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
import HealthKit
import UIKit
import WatchConnectivity
import Foundation

final class GenericHealthCardViewModel: ObservableObject, CardDataSource {

    private enum FileConstants {
        static let liveWindowSeconds: TimeInterval = 15
        static let fetchLookbackSeconds: TimeInterval = 60 * 60 * 24 * 7
        static let fetchLimit = 2000
        static let chartDaysHistorical = 7
        static let timeBucketHours: TimeInterval = 60 * 60 * 4
        static let timeBucketDays: TimeInterval = 60 * 60 * 24
        static let maxLinePoints = 42
        static let maxScatterPoints = 56
        static let liveStartMessageKey = "healthSensorsLiveHRStart"
    }

    @Published private(set) var state: CardState = .needsPermission
    @Published private(set) var primary: MetricValue?
    @Published private(set) var secondary: [MetricValue] = []
    @Published private(set) var series: [MetricSeries] = []
    @Published private(set) var statusText: String?

    let metric: HealthKitDataManager.HealthMetric
    private let dataManager = HealthKitDataManager()
    private let kitConfig = HealthSensorsConfigurationLoader.config
    private let receiver = WatchBPMReceiver.shared
    private var cancellables = Set<AnyCancellable>()

    init(metric: HealthKitDataManager.HealthMetric) {
        self.metric = metric
    }

    func start() {
        observeLiveUpdates()
        refreshData()
    }

    func stop() {
        cancellables.removeAll()
    }

    func requestPermission() {
        Task {
            do {
                try await dataManager.requestAuthorization(for: [metric])
                await MainActor.run {
                    self.refreshData()
                }
            } catch {
                await MainActor.run {
                    // If authorization fails, we might still want to try refreshing to see if we have read access
                    self.refreshData()
                }
            }
        }
    }

    func startLiveMeasurementOnWatch() {
        // Only relevant for Heart Rate currently
        guard metric == .heartRate else {
            return
        }
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        guard session.isReachable else {
            return
        }
        session.sendMessage([FileConstants.liveStartMessageKey: true], replyHandler: { _ in }, errorHandler: nil)
    }

    private func observeLiveUpdates() {
        // Only observe watch updates for heart rate
        if metric == .heartRate {
            Publishers.CombineLatest(receiver.$lastReceived, receiver.$bpm)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _, _ in
                    self?.refreshData()
                }
                .store(in: &cancellables)
        }

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }

    private func refreshData() {
        if MockDataStore.isEnabled {
            applyMock()
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            state = .error(metric.displayEmptyStateMessage(config: kitConfig))
            statusText = nil
            primary = nil
            secondary = []
            series = []
            return
        }

        let authStatus = dataManager.authorizationState(for: [metric])

        switch authStatus {
        case .notDetermined:
            state = .needsPermission
            statusText = nil
            primary = nil
            secondary = []
            series = []
            return
        case .denied:
            state = .permissionDenied
            statusText = nil
            primary = nil
            secondary = []
            series = []
            return
        case .authorized:
            break
        }

        // Fetch data
        Task {
            let values = await dataManager.fetchLatestValue(
                for: metric,
                since: FileConstants.fetchLookbackSeconds,
                limit: FileConstants.fetchLimit
            )

            await MainActor.run {
                self.processFetchedValues(values)
            }
        }
    }

    private func processFetchedValues(_ values: [HealthKitDataManager.HealthMetricValue]) {
        let unitString = metric.displayUnit(config: kitConfig)
        let liveValue = liveHeartRateMetricValue(unit: unitString)

        if let first = values.first, case .unavailable = first {
            if let liveValue {
                applyLiveOnlyState(liveValue, unit: unitString)
            } else {
                state = .error(metric.displayEmptyStateMessage(config: kitConfig))
                statusText = nil
                primary = nil
                secondary = []
                series = []
            }
            return
        }

        guard let latest = values.first else {
            if let liveValue {
                applyLiveOnlyState(liveValue, unit: unitString)
            } else {
                state = .noData
                statusText = nil
                primary = nil
                secondary = []
                series = []
            }
            return
        }

        // If live heart rate is active, prefer that for primary
        if let liveValue {
            self.primary = liveValue
            self.statusText = kitConfig.statusLive.localized
        } else {
            self.primary = MetricValue(
                label: nil,
                value: latest.displayValue,
                unit: unitString,
                date: latest.date,
                source: .health
            )
            self.statusText = kitConfig.statusSampleBased.localized
        }

        let chartData = buildChartData(values: values, liveValue: liveValue, unit: unitString)
        self.series = chartData.series

        // Secondary metrics
        self.secondary = makeSecondaryMetrics(
            points: chartData.summaryPoints,
            unit: unitString,
            source: liveValue == nil ? .health : .watchLive
        )
        self.state = .ready
    }

    private func applyLiveOnlyState(_ liveValue: MetricValue, unit: String) {
        primary = liveValue
        state = .ready
        statusText = kitConfig.statusLive.localized
        let livePoints = [MetricPoint(date: liveValue.date, value: liveValue.value)]
        series = [MetricSeries(label: metric.displayTitle(config: kitConfig), unit: unit, points: livePoints)]
        secondary = makeSecondaryMetrics(points: livePoints, unit: unit, source: .watchLive)
    }

    private func buildChartData(
        values: [HealthKitDataManager.HealthMetricValue],
        liveValue: MetricValue?,
        unit: String
    ) -> (series: [MetricSeries], summaryPoints: [MetricPoint]) {
        switch metric {
        case .bloodPressure:
            return makeBloodPressureChartData(values: values)
        default:
            return makeSingleSeriesChartData(values: values, liveValue: liveValue, unit: unit)
        }
    }

    private func makeSingleSeriesChartData(
        values: [HealthKitDataManager.HealthMetricValue],
        liveValue: MetricValue?,
        unit: String
    ) -> (series: [MetricSeries], summaryPoints: [MetricPoint]) {
        var points = values.reversed().map { value in
            MetricPoint(date: value.date, value: value.displayValue)
        }

        if let liveValue {
            points.append(MetricPoint(date: liveValue.date, value: liveValue.value))
        }

        points.sort { $0.date < $1.date }
        let optimizedPoints = optimizePointsForMetric(points)

        let dataSeries = MetricSeries(
            label: metric.displayTitle(config: kitConfig),
            unit: unit,
            points: optimizedPoints
        )
        return (series: [dataSeries], summaryPoints: optimizedPoints)
    }

    private func makeBloodPressureChartData(
        values: [HealthKitDataManager.HealthMetricValue]
    ) -> (series: [MetricSeries], summaryPoints: [MetricPoint]) {
        let samples = values.compactMap { value -> (date: Date, systolic: Double, diastolic: Double)? in
            guard case .bloodPressure(let systolic, let diastolic, _, let date) = value else {
                return nil
            }
            return (date: date, systolic: systolic, diastolic: diastolic)
        }.sorted { $0.date < $1.date }

        guard !samples.isEmpty else {
            return (series: [], summaryPoints: [])
        }

        let bucketed = bucketBloodPressure(
            samples: samples,
            interval: FileConstants.timeBucketHours
        )
        let systolicPoints = downsample(points: bucketed.systolic, maxPoints: FileConstants.maxLinePoints)
        let diastolicPoints = downsample(points: bucketed.diastolic, maxPoints: FileConstants.maxLinePoints)

        let systolicSeries = MetricSeries(
            label: kitConfig.labelSystolic.localized,
            unit: kitConfig.unitMmHg.localized,
            points: systolicPoints
        )
        let diastolicSeries = MetricSeries(
            label: kitConfig.labelDiastolic.localized,
            unit: kitConfig.unitMmHg.localized,
            points: diastolicPoints
        )
        return (series: [systolicSeries, diastolicSeries], summaryPoints: systolicPoints)
    }

    private func optimizePointsForMetric(_ points: [MetricPoint]) -> [MetricPoint] {
        guard !points.isEmpty else {
            return []
        }

        switch metric {
        case .heartRate, .oxygenSaturation, .respiratoryRate:
            let bucketed = bucketAverage(points: points, interval: FileConstants.timeBucketHours)
            return downsample(points: bucketed, maxPoints: FileConstants.maxLinePoints)
        case .restingHeartRate, .vo2Max:
            let bucketed = bucketAverage(points: points, interval: FileConstants.timeBucketDays)
            return downsample(points: bucketed, maxPoints: FileConstants.maxLinePoints)
        case .bloodGlucose, .ecg:
            return downsample(points: points, maxPoints: FileConstants.maxScatterPoints)
        case .bloodPressure:
            return downsample(points: points, maxPoints: FileConstants.maxLinePoints)
        }
    }

    private func bucketAverage(points: [MetricPoint], interval: TimeInterval) -> [MetricPoint] {
        guard interval > 0 else {
            return points
        }

        var buckets: [Date: (sum: Double, count: Int)] = [:]
        for point in points {
            let bucketDate = Date(
                timeIntervalSince1970: floor(point.date.timeIntervalSince1970 / interval) * interval
            )
            let existing = buckets[bucketDate] ?? (sum: 0, count: 0)
            buckets[bucketDate] = (sum: existing.sum + point.value, count: existing.count + 1)
        }

        return buckets.keys.sorted().compactMap { date in
            guard let entry = buckets[date], entry.count > 0 else {
                return nil
            }
            return MetricPoint(date: date, value: entry.sum / Double(entry.count))
        }
    }

    private func bucketBloodPressure(
        samples: [(date: Date, systolic: Double, diastolic: Double)],
        interval: TimeInterval
    ) -> (systolic: [MetricPoint], diastolic: [MetricPoint]) {
        struct Aggregation {
            var systolicSum: Double
            var diastolicSum: Double
            var count: Int
        }

        var buckets: [Date: Aggregation] = [:]
        for sample in samples {
            let bucketDate = Date(
                timeIntervalSince1970: floor(sample.date.timeIntervalSince1970 / interval) * interval
            )
            var entry = buckets[bucketDate] ?? Aggregation(systolicSum: 0, diastolicSum: 0, count: 0)
            entry.systolicSum += sample.systolic
            entry.diastolicSum += sample.diastolic
            entry.count += 1
            buckets[bucketDate] = entry
        }

        let sortedDates = buckets.keys.sorted()
        let systolic = sortedDates.compactMap { date -> MetricPoint? in
            guard let entry = buckets[date], entry.count > 0 else {
                return nil
            }
            return MetricPoint(date: date, value: entry.systolicSum / Double(entry.count))
        }
        let diastolic = sortedDates.compactMap { date -> MetricPoint? in
            guard let entry = buckets[date], entry.count > 0 else {
                return nil
            }
            return MetricPoint(date: date, value: entry.diastolicSum / Double(entry.count))
        }
        return (systolic: systolic, diastolic: diastolic)
    }

    private func downsample(points: [MetricPoint], maxPoints: Int) -> [MetricPoint] {
        guard points.count > maxPoints, maxPoints > 2 else {
            return points
        }

        let lastIndex = points.count - 1
        let strideValue = Double(lastIndex) / Double(maxPoints - 1)
        var sampledPoints: [MetricPoint] = []
        sampledPoints.reserveCapacity(maxPoints)

        for index in 0..<maxPoints {
            let sourceIndex = min(lastIndex, Int(round(Double(index) * strideValue)))
            sampledPoints.append(points[sourceIndex])
        }

        return sampledPoints
    }

    private var isLiveActive: Bool {
        guard metric == .heartRate, let lastReceived = receiver.lastReceived else {
            return false
        }
        return Date().timeIntervalSince(lastReceived) <= FileConstants.liveWindowSeconds
    }

    private func liveHeartRateMetricValue(unit: String) -> MetricValue? {
        guard metric == .heartRate, isLiveActive, let bpm = receiver.bpm else {
            return nil
        }

        return MetricValue(
            label: nil,
            value: Double(bpm),
            unit: unit,
            date: receiver.lastReceived ?? Date(),
            source: .watchLive
        )
    }

    private func makeSecondaryMetrics(points: [MetricPoint], unit: String, source: MetricSource) -> [MetricValue] {
        guard !points.isEmpty else {
            return []
        }
        let values = points.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let minValue = values.min() ?? average
        let maxValue = values.max() ?? average
        let now = Date()

        return [
            MetricValue(label: kitConfig.labelAverage.localized, value: average, unit: unit, date: now, source: source),
            MetricValue(label: kitConfig.labelMin.localized, value: minValue, unit: unit, date: now, source: source),
            MetricValue(label: kitConfig.labelMax.localized, value: maxValue, unit: unit, date: now, source: source)
        ]
    }

    private func applyMock() {
        var generator = MockDataStore.generator()
        let now = Date()
        let calendar = Calendar.current
        let unitString = metric.displayUnit(config: kitConfig)

        switch metric {
        case .bloodPressure:
            var systolicPoints: [MetricPoint] = []
            var diastolicPoints: [MetricPoint] = []
            for dayOffset in stride(from: FileConstants.chartDaysHistorical - 1, through: 0, by: -1) {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let systolic = Double.random(in: 110...140, using: &generator)
                let diastolic = Double.random(in: 70...90, using: &generator)
                systolicPoints.append(MetricPoint(date: date, value: systolic))
                diastolicPoints.append(MetricPoint(date: date, value: diastolic))
            }

            primary = MetricValue(
                label: nil,
                value: systolicPoints.last?.value ?? 120,
                unit: unitString,
                date: now,
                source: .mock
            )
            series = [
                MetricSeries(label: kitConfig.labelSystolic.localized, unit: kitConfig.unitMmHg.localized, points: systolicPoints),
                MetricSeries(label: kitConfig.labelDiastolic.localized, unit: kitConfig.unitMmHg.localized, points: diastolicPoints)
            ]
            secondary = makeSecondaryMetrics(points: systolicPoints, unit: unitString, source: .mock)
        default:
            let range: ClosedRange<Double>
            switch metric {
            case .heartRate: range = 60...100
            case .bloodGlucose: range = 70...140
            case .ecg: range = 60...100
            case .respiratoryRate: range = 12...20
            case .restingHeartRate: range = 50...70
            case .oxygenSaturation: range = 95...100
            case .vo2Max: range = 35...55
            case .bloodPressure: range = 110...140
            }

            var points: [MetricPoint] = []
            for dayOffset in stride(from: FileConstants.chartDaysHistorical - 1, through: 0, by: -1) {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let value = Double.random(in: range, using: &generator)
                points.append(MetricPoint(date: date, value: value))
            }

            primary = MetricValue(
                label: nil,
                value: points.last?.value ?? range.lowerBound,
                unit: unitString,
                date: now,
                source: .mock
            )
            series = [MetricSeries(label: metric.displayTitle(config: kitConfig), unit: unitString, points: points)]
            secondary = makeSecondaryMetrics(points: points, unit: unitString, source: .mock)
        }

        state = .ready
        statusText = kitConfig.statusMock.localized
    }
}
