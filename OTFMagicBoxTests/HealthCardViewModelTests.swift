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
import Testing
@testable import OTFMagicBox

@Suite("Health card row view model")
@MainActor
struct HealthCardRowViewModelTests {
    @Test("Loads permission-needed placeholder without live HealthKit")
    func loadsPermissionNeededPlaceholder() async {
        let model = makeCardRowViewModel(
            dataManager: FakeHealthKitDataProvider(authorizationState: .notDetermined)
        )

        await model.loadLatestSnapshot()

        #expect(model.valueText == HealthSensorsConfiguration.fallback.statusNeedsPermission.localized)
        #expect(model.detailText == HealthSensorsConfiguration.fallback.buttonGrantAccess.localized)
        #expect(model.usesPlaceholderStyle)
    }

    @Test("Loads latest health value from injected data provider")
    func loadsLatestHealthValue() async throws {
        let date = try fixedDate(day: 20, hour: 9)
        let model = makeCardRowViewModel(
            dataManager: FakeHealthKitDataProvider(
                authorizationState: .authorized,
                values: [.heartRate(bpm: 72, date: date)]
            )
        )

        await model.loadLatestSnapshot()

        #expect(model.valueText == "72 \(HealthSensorsConfiguration.fallback.unitBPM.localized)")
        #expect(model.detailText == HealthSensorsConfiguration.fallback.statusSampleBased.localized)
        #expect(model.timestampText != nil)
        #expect(!model.usesPlaceholderStyle)
    }

    @Test("Formats latest values for supported health metrics")
    func formatsLatestValuesForSupportedHealthMetrics() async throws {
        let date = try fixedDate(day: 20, hour: 9)
        let config = HealthSensorsConfiguration.fallback
        let cases: [(HealthKitDataManager.HealthMetric, HealthKitDataManager.HealthMetricValue, String, String?)] = [
            (
                .heartRate,
                .heartRate(bpm: 72, date: date),
                "72 \(config.unitBPM.localized)",
                config.statusSampleBased.localized
            ),
            (
                .bloodGlucose,
                .bloodGlucose(mgPerdL: 101, date: date),
                "101 \(config.unitMgDL.localized)",
                config.statusSampleBased.localized
            ),
            (
                .bloodPressure,
                .bloodPressure(systolic: 118, diastolic: 76, unit: .millimeterOfMercury(), date: date),
                "118/76 \(config.unitMmHg.localized)",
                config.statusSampleBased.localized
            ),
            (
                .ecg,
                .ecg(classification: .sinusRhythm, averageBPM: 68, samplingHz: nil, duration: nil, date: date),
                config.ecgClassificationSinusRhythm.localized,
                "68 \(config.unitBPM.localized)"
            ),
            (
                .respiratoryRate,
                .respiratoryRate(breathsPerMin: 14.4, date: date),
                "\(MetricFormatter.format(14.4, decimals: 1)) \(config.unitBreathsPerMin.localized)",
                config.statusSampleBased.localized
            ),
            (
                .restingHeartRate,
                .restingHeartRate(bpm: 59, date: date),
                "59 \(config.unitBPM.localized)",
                config.statusSampleBased.localized
            ),
            (
                .oxygenSaturation,
                .oxygenSaturation(percent: 98, date: date),
                "98\(config.unitPercent.localized)",
                config.statusSampleBased.localized
            ),
            (
                .vo2Max,
                .vo2Max(mlPerKgMin: 42.4, date: date),
                "\(MetricFormatter.format(42.4, decimals: 1)) \(config.unitVO2Max.localized)",
                config.statusSampleBased.localized
            )
        ]

        for (metric, value, expectedValue, expectedDetail) in cases {
            let dataManager = FakeHealthKitDataProvider(authorizationState: .authorized, values: [value])
            let model = makeCardRowViewModel(metric: metric, dataManager: dataManager)

            await model.loadLatestSnapshot()

            #expect(model.valueText == expectedValue)
            #expect(model.detailText == expectedDetail)
            #expect(model.timestampText != nil)
            #expect(!model.usesPlaceholderStyle)
            #expect(dataManager.fetchRequests.map(\.metric) == [metric])
            #expect(dataManager.fetchRequests.first?.limit == 1)
        }
    }

    @Test("Loads ECG subtitle when latest ECG has no average BPM")
    func loadsECGSubtitleWhenLatestECGHasNoAverageBPM() async throws {
        let date = try fixedDate(day: 20, hour: 9)
        let model = makeCardRowViewModel(
            metric: .ecg,
            dataManager: FakeHealthKitDataProvider(
                authorizationState: .authorized,
                values: [.ecg(classification: .inconclusiveOther, averageBPM: nil, samplingHz: nil, duration: nil, date: date)]
            )
        )

        await model.loadLatestSnapshot()

        #expect(model.valueText == HealthSensorsConfiguration.fallback.ecgClassificationOther.localized)
        #expect(model.detailText == HealthSensorsConfiguration.fallback.cardSubtitleECG.localized)
        #expect(!model.usesPlaceholderStyle)
    }

    @Test("Loads placeholders for unavailable health data and empty samples")
    func loadsPlaceholdersForUnavailableHealthDataAndEmptySamples() async {
        let unavailable = makeCardRowViewModel(
            healthDataAvailable: { false }
        )
        let noData = makeCardRowViewModel(
            dataManager: FakeHealthKitDataProvider(authorizationState: .authorized, values: [])
        )
        let unsupportedType = makeCardRowViewModel(
            dataManager: FakeHealthKitDataProvider(
                authorizationState: .authorized,
                values: [.unavailable("Heart Rate type unavailable")]
            )
        )

        await unavailable.loadLatestSnapshot()
        await noData.loadLatestSnapshot()
        await unsupportedType.loadLatestSnapshot()

        let config = HealthSensorsConfiguration.fallback
        #expect(unavailable.valueText == config.statusError.localized)
        #expect(unavailable.detailText == config.emptyStateTitle.localized)
        #expect(noData.valueText == config.statusNoData.localized)
        #expect(noData.detailText == HealthKitDataManager.HealthMetric.heartRate.displayEmptyStateMessage(config: config))
        #expect(unsupportedType.valueText == config.statusError.localized)
        #expect(unsupportedType.detailText == HealthKitDataManager.HealthMetric.heartRate.displayEmptyStateMessage(config: config))
        #expect(unavailable.usesPlaceholderStyle)
        #expect(noData.usesPlaceholderStyle)
        #expect(unsupportedType.usesPlaceholderStyle)
    }

    @Test("Loads deterministic mock value when mock provider is enabled")
    func loadsMockValueWhenEnabled() async throws {
        let date = try fixedDate(day: 20, hour: 9)
        let model = makeCardRowViewModel(
            dataManager: FakeHealthKitDataProvider(authorizationState: .denied),
            mockData: FakeHealthSensorMockDataProvider(isEnabled: true, seed: 9),
            now: { date }
        )

        await model.loadLatestSnapshot()

        #expect(model.detailText == HealthSensorsConfiguration.fallback.statusMock.localized)
        #expect(model.timestampText != nil)
        #expect(!model.usesPlaceholderStyle)
    }
}

@Suite("Generic health card view model")
@MainActor
struct GenericHealthCardViewModelTests {
    @Test("Refresh reports permission states without querying HealthKit")
    func refreshReportsPermissionStates() {
        let needsPermission = makeGenericHealthCardViewModel(
            dataManager: FakeHealthKitDataProvider(authorizationState: .notDetermined)
        )
        let permissionDenied = makeGenericHealthCardViewModel(
            dataManager: FakeHealthKitDataProvider(authorizationState: .denied)
        )

        needsPermission.refreshData()
        permissionDenied.refreshData()

        #expect(needsPermission.state == .needsPermission)
        #expect(needsPermission.primary == nil)
        #expect(permissionDenied.state == .permissionDenied)
        #expect(permissionDenied.series.isEmpty)
    }

    @Test("Processes no-data and unavailable values into distinct states")
    func processesNoDataAndUnavailableValues() {
        let noData = makeGenericHealthCardViewModel()
        noData.processFetchedValues([])

        let unavailable = makeGenericHealthCardViewModel()
        unavailable.processFetchedValues([.unavailable("Heart Rate unavailable")])

        #expect(noData.state == .noData)
        #expect(noData.primary == nil)
        #expect(unavailable.state == .error(HealthSensorsConfiguration.fallback.emptyMessageHeartRate.localized))
        #expect(unavailable.primary == nil)
    }

    @Test("Prefers fresh live heart rate over fetched HealthKit sample")
    func prefersFreshLiveHeartRate() throws {
        let now = try fixedDate(day: 20, hour: 9)
        let receiver = FakeWatchLiveHeartRateProvider(
            bpm: 91,
            lastReceived: now.addingTimeInterval(-5)
        )
        let model = makeGenericHealthCardViewModel(receiver: receiver, now: { now })

        model.processFetchedValues([.heartRate(bpm: 70, date: now.addingTimeInterval(-60))])

        #expect(model.state == .ready)
        #expect(model.primary?.value == 91)
        #expect(model.primary?.source == .watchLive)
        #expect(model.statusText == HealthSensorsConfiguration.fallback.statusLive.localized)
    }

    @Test("Blood pressure chart buckets paired systolic and diastolic series")
    func bloodPressureChartBucketsPairedSeries() throws {
        let start = try fixedDate(day: 20, hour: 0)
        let values: [HealthKitDataManager.HealthMetricValue] = [
            .bloodPressure(systolic: 120, diastolic: 80, unit: .millimeterOfMercury(), date: start.addingTimeInterval(60)),
            .bloodPressure(systolic: 130, diastolic: 90, unit: .millimeterOfMercury(), date: start.addingTimeInterval(120)),
            .bloodPressure(systolic: 140, diastolic: 95, unit: .millimeterOfMercury(), date: start.addingTimeInterval(60 * 60 * 5))
        ]
        let model = GenericHealthCardViewModel(metric: .bloodPressure, kitConfig: .fallback)

        let chart = model.buildChartData(values: values, liveValue: nil, unit: "mmHg")

        #expect(chart.series.count == 2)
        #expect(chart.series[0].points.map(\.value) == [125, 140])
        #expect(chart.series[1].points.map(\.value) == [85, 95])
        #expect(chart.summaryPoints.map(\.value) == [125, 140])
    }

    @Test("Preserves complete latest blood pressure and ECG readings")
    func preservesCompleteLatestCompositeReadings() throws {
        let date = try fixedDate(day: 20, hour: 9)
        let bloodPressure = HealthKitDataManager.HealthMetricValue.bloodPressure(
            systolic: 118,
            diastolic: 76,
            unit: .millimeterOfMercury(),
            date: date
        )
        let ecg = HealthKitDataManager.HealthMetricValue.ecg(
            classification: .sinusRhythm,
            averageBPM: nil,
            samplingHz: 512,
            duration: 30,
            date: date
        )
        let bloodPressureModel = GenericHealthCardViewModel(
            metric: .bloodPressure,
            kitConfig: .fallback
        )
        let ecgModel = GenericHealthCardViewModel(
            metric: .ecg,
            kitConfig: .fallback
        )

        bloodPressureModel.processFetchedValues([bloodPressure])
        ecgModel.processFetchedValues([ecg])

        #expect(bloodPressureModel.latestReading == bloodPressure)
        #expect(ecgModel.latestReading == ecg)
        #expect(ecgModel.latestReading?.compactSummary(config: .fallback) == "Sinus Rhythm")
    }

    @Test("Line charts bucket nearby samples into averaged points")
    func lineChartsBucketNearbySamplesIntoAveragedPoints() throws {
        let start = try fixedDate(day: 20, hour: 12)
        let values: [HealthKitDataManager.HealthMetricValue] = [
            .heartRate(bpm: 80, date: start.addingTimeInterval(60)),
            .heartRate(bpm: 100, date: start.addingTimeInterval(120)),
            .heartRate(bpm: 70, date: start.addingTimeInterval(60 * 60 * 5))
        ]
        let model = GenericHealthCardViewModel(metric: .heartRate, kitConfig: .fallback)

        let chart = model.buildChartData(values: values, liveValue: nil, unit: "BPM")

        #expect(chart.series.count == 1)
        #expect(chart.series.first?.points.map(\.value) == [90, 70])
        #expect(chart.summaryPoints.map(\.value) == [90, 70])
    }

    @Test("Dense scatter charts are downsampled to the configured cap")
    func denseScatterChartsAreDownsampledToConfiguredCap() throws {
        let start = try fixedDate(day: 20, hour: 12)
        let values = (0..<80).map { index in
            HealthKitDataManager.HealthMetricValue.bloodGlucose(
                mgPerdL: Double(index),
                date: start.addingTimeInterval(TimeInterval(index * 60))
            )
        }
        let model = GenericHealthCardViewModel(metric: .bloodGlucose, kitConfig: .fallback)

        let chart = model.buildChartData(values: values, liveValue: nil, unit: "mg/dL")

        #expect(chart.series.first?.points.count == 56)
        #expect(chart.summaryPoints.count == 56)
        #expect(chart.summaryPoints.first?.value == 0)
        #expect(chart.summaryPoints.last?.value == 79)
    }

    @Test("Mock data builds ready state with seven historical points")
    func mockDataBuildsReadyState() {
        let model = makeGenericHealthCardViewModel(
            mockData: FakeHealthSensorMockDataProvider(isEnabled: true, seed: 4)
        )

        model.refreshData()

        #expect(model.state == .ready)
        #expect(model.statusText == HealthSensorsConfiguration.fallback.statusMock.localized)
        #expect(model.series.first?.points.count == 7)
        #expect(model.secondary.count == 3)
        #expect(model.primary?.source == .mock)
    }

    @Test("Mock ECG generates a previewable PDF report")
    func mockECGGeneratesPreviewablePDFReport() throws {
        let model = makeGenericHealthCardViewModel(
            metric: .ecg,
            mockData: FakeHealthSensorMockDataProvider(isEnabled: true, seed: 4)
        )

        model.refreshData()

        let report = try #require(model.ecgReport)
        #expect(report.pdfData.starts(with: Data("%PDF-".utf8)))
        #expect(report.sourceSampleUUID == nil)
        #expect(report.lead == ECGWaveform.appleWatchLead)
        #expect(!model.isPreparingECGReport)
    }

    @Test("An older HealthKit refresh cannot replace a newer result")
    func olderHealthKitRefreshCannotReplaceNewerResult() async throws {
        let older = HealthKitDataManager.HealthMetricValue.heartRate(
            bpm: 61,
            date: try fixedDate(day: 19, hour: 9)
        )
        let newer = HealthKitDataManager.HealthMetricValue.heartRate(
            bpm: 79,
            date: try fixedDate(day: 20, hour: 9)
        )
        let provider = ControlledHealthKitDataProvider()
        let model = makeGenericHealthCardViewModel(dataManager: provider)

        model.refreshData()
        await waitForFetchCount(1, provider: provider)
        model.refreshData()
        await waitForFetchCount(2, provider: provider)

        await provider.completeFetch(1, values: [newer])
        await yieldToMainActor()
        #expect(model.latestReading == newer)

        await provider.completeFetch(0, values: [older])
        await yieldToMainActor()
        #expect(model.latestReading == newer)
    }

    @Test("A stale ECG waveform cannot replace a newer report")
    func staleECGWaveformCannotReplaceNewerReport() async throws {
        let olderDate = try fixedDate(day: 19, hour: 9)
        let newerDate = try fixedDate(day: 20, hour: 9)
        let provider = ControlledHealthKitDataProvider()
        let model = makeGenericHealthCardViewModel(
            metric: .ecg,
            dataManager: provider,
            reportRenderer: IdentityECGReportRenderer()
        )
        let olderReading = HealthKitDataManager.HealthMetricValue.ecg(
            classification: .sinusRhythm,
            averageBPM: 61,
            samplingHz: 512,
            duration: 30,
            date: olderDate
        )
        let newerReading = HealthKitDataManager.HealthMetricValue.ecg(
            classification: .sinusRhythm,
            averageBPM: 79,
            samplingHz: 512,
            duration: 30,
            date: newerDate
        )
        let olderUUID = UUID()
        let newerUUID = UUID()

        model.refreshData()
        await waitForFetchCount(1, provider: provider)
        await provider.completeFetch(0, values: [olderReading])
        await waitForWaveformFetchCount(1, provider: provider)

        model.refreshData()
        await waitForFetchCount(2, provider: provider)
        await provider.completeFetch(1, values: [newerReading])
        await waitForWaveformFetchCount(2, provider: provider)

        await provider.completeWaveformFetch(1, waveform: makeWaveform(uuid: newerUUID))
        await yieldToMainActor()
        #expect(model.ecgReport?.sourceSampleUUID == newerUUID)

        await provider.completeWaveformFetch(0, waveform: makeWaveform(uuid: olderUUID))
        await yieldToMainActor()
        #expect(model.ecgReport?.sourceSampleUUID == newerUUID)
    }
}

private final class FakeHealthKitDataProvider: HealthKitDataProviding {
    var authorizationState: HealthKitDataManager.AuthorizationState
    var values: [HealthKitDataManager.HealthMetricValue]
    private(set) var requestedMetrics: [Set<HealthKitDataManager.HealthMetric>] = []
    private(set) var fetchRequests: [(metric: HealthKitDataManager.HealthMetric, lookback: TimeInterval, limit: Int?)] = []

    init(
        authorizationState: HealthKitDataManager.AuthorizationState = .authorized,
        values: [HealthKitDataManager.HealthMetricValue] = []
    ) {
        self.authorizationState = authorizationState
        self.values = values
    }

    func requestAuthorization(for metrics: Set<HealthKitDataManager.HealthMetric>) async throws {
        requestedMetrics.append(metrics)
    }

    func authorizationState(for metrics: Set<HealthKitDataManager.HealthMetric>) -> HealthKitDataManager.AuthorizationState {
        authorizationState
    }

    func fetchLatestValue(
        for metric: HealthKitDataManager.HealthMetric,
        since lookback: TimeInterval,
        limit: Int?
    ) async -> [HealthKitDataManager.HealthMetricValue] {
        fetchRequests.append((metric, lookback, limit))
        return values
    }
}

private actor ControlledHealthKitDataProvider: HealthKitDataProviding {
    private var continuations = [
        Int: CheckedContinuation<[HealthKitDataManager.HealthMetricValue], Never>
    ]()
    private var nextRequestID = 0
    private var waveformContinuations = [Int: CheckedContinuation<ECGWaveform?, Never>]()
    private var nextWaveformRequestID = 0

    nonisolated func requestAuthorization(
        for metrics: Set<HealthKitDataManager.HealthMetric>
    ) async throws {}

    nonisolated func authorizationState(
        for metrics: Set<HealthKitDataManager.HealthMetric>
    ) -> HealthKitDataManager.AuthorizationState {
        .authorized
    }

    func fetchLatestValue(
        for metric: HealthKitDataManager.HealthMetric,
        since lookback: TimeInterval,
        limit: Int?
    ) async -> [HealthKitDataManager.HealthMetricValue] {
        let requestID = nextRequestID
        nextRequestID += 1
        return await withCheckedContinuation { continuation in
            continuations[requestID] = continuation
        }
    }

    var fetchCount: Int {
        nextRequestID
    }

    func fetchECGWaveform(for recordingDate: Date) async -> ECGWaveform? {
        let requestID = nextWaveformRequestID
        nextWaveformRequestID += 1
        return await withCheckedContinuation { continuation in
            waveformContinuations[requestID] = continuation
        }
    }

    var waveformFetchCount: Int {
        nextWaveformRequestID
    }

    func completeFetch(
        _ requestID: Int,
        values: [HealthKitDataManager.HealthMetricValue]
    ) {
        continuations.removeValue(forKey: requestID)?.resume(returning: values)
    }

    func completeWaveformFetch(_ requestID: Int, waveform: ECGWaveform?) {
        waveformContinuations.removeValue(forKey: requestID)?.resume(returning: waveform)
    }
}

private func waitForFetchCount(
    _ expectedCount: Int,
    provider: ControlledHealthKitDataProvider
) async {
    while await provider.fetchCount < expectedCount {
        await Task.yield()
    }
}

private func waitForWaveformFetchCount(
    _ expectedCount: Int,
    provider: ControlledHealthKitDataProvider
) async {
    while await provider.waveformFetchCount < expectedCount {
        await Task.yield()
    }
}

private func makeWaveform(uuid: UUID) -> ECGWaveform {
    let synthetic = ECGWaveform.synthetic(
        averageBPM: 72,
        duration: 30,
        samplingFrequencyHz: 512
    )
    return ECGWaveform(
        sourceSampleUUID: uuid,
        lead: ECGWaveform.appleWatchLead,
        samplingFrequencyHz: synthetic.samplingFrequencyHz,
        samples: synthetic.samples
    )
}

@MainActor
private func yieldToMainActor() async {
    for _ in 0..<4 {
        await Task.yield()
    }
}

private struct FakeHealthSensorMockDataProvider: HealthSensorMockDataProviding {
    let isEnabled: Bool
    let seed: Int

    func generator() -> SeededRandomNumberGenerator {
        SeededRandomNumberGenerator(seed: UInt64(seed))
    }
}

private struct IdentityECGReportRenderer: ECGReportRendering {
    func makeReport(
        reading: HealthKitDataManager.HealthMetricValue,
        waveform: ECGWaveform
    ) -> ECGReport? {
        ECGReport(
            pdfData: Data("%PDF-test".utf8),
            sourceSampleUUID: waveform.sourceSampleUUID,
            lead: waveform.lead
        )
    }
}

private final class FakeWatchLiveHeartRateProvider: WatchLiveHeartRateProviding {
    let bpm: Int?
    let lastReceived: Date?
    let updates: AnyPublisher<Void, Never>

    init(bpm: Int? = nil, lastReceived: Date? = nil) {
        self.bpm = bpm
        self.lastReceived = lastReceived
        self.updates = Empty<Void, Never>().eraseToAnyPublisher()
    }
}

@MainActor
private func makeCardRowViewModel(
    metric: HealthKitDataManager.HealthMetric = .heartRate,
    dataManager: HealthKitDataProviding = FakeHealthKitDataProvider(),
    mockData: HealthSensorMockDataProviding = FakeHealthSensorMockDataProvider(isEnabled: false, seed: 1),
    healthDataAvailable: @escaping () -> Bool = { true },
    now: @escaping () -> Date = Date.init
) -> CardRowViewModel {
    CardRowViewModel(
        metric: metric,
        dataManager: dataManager,
        config: .fallback,
        mockData: mockData,
        healthDataAvailable: healthDataAvailable,
        notificationCenter: NotificationCenter(),
        now: now,
        calendar: fixedCalendar
    )
}

@MainActor
private func makeGenericHealthCardViewModel(
    metric: HealthKitDataManager.HealthMetric = .heartRate,
    dataManager: HealthKitDataProviding = FakeHealthKitDataProvider(),
    mockData: HealthSensorMockDataProviding = FakeHealthSensorMockDataProvider(isEnabled: false, seed: 1),
    receiver: WatchLiveHeartRateProviding = FakeWatchLiveHeartRateProvider(),
    now: @escaping () -> Date = Date.init,
    reportRenderer: ECGReportRendering = ECGReportRenderer()
) -> GenericHealthCardViewModel {
    GenericHealthCardViewModel(
        metric: metric,
        dataManager: dataManager,
        kitConfig: .fallback,
        mockData: mockData,
        receiver: receiver,
        healthDataAvailable: { true },
        notificationCenter: NotificationCenter(),
        now: now,
        calendar: fixedCalendar,
        reportRenderer: reportRenderer
    )
}

private let fixedCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()

private func fixedDate(day: Int, hour: Int = 12) throws -> Date {
    let components = DateComponents(
        calendar: fixedCalendar,
        timeZone: fixedCalendar.timeZone,
        year: 2026,
        month: 5,
        day: day,
        hour: hour
    )
    return try #require(fixedCalendar.date(from: components))
}
