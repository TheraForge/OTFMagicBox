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
import HealthKit
import OTFCareKit
import OTFCareKitStore
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("Health sensor formatting and mock data", .serialized)
struct HealthSensorFormattingAndMockDataTests {
    private struct MetricMetadataExpectation {
        let metric: HealthKitDataManager.HealthMetric
        let title: String
        let subtitle: String
        let symbol: String
        let unit: String
    }

    @Test("Quick-send ignores rapid duplicate taps and surfaces failure")
    @MainActor
    func quickSendIgnoresRapidDuplicateTapsAndSurfacesFailure() throws {
        let state = SensorTaskQuickSendState()
        var submissionCount = 0
        var pendingCompletion: ((Bool) -> Void)?
        let submission: SensorTaskQuickSendState.Submission = { completion in
            submissionCount += 1
            pendingCompletion = completion
        }

        state.submit(using: submission)
        state.submit(using: submission)

        #expect(submissionCount == 1)
        #expect(state.isSubmitting)
        #expect(!state.submissionFailed)

        let completion = try #require(pendingCompletion)
        completion(false)

        #expect(!state.isSubmitting)
        #expect(state.submissionFailed)

        state.submit(using: submission)

        #expect(submissionCount == 2)
        #expect(state.isSubmitting)
        #expect(!state.submissionFailed)
    }

    @Test("Submitted sensor cards invalidate their hosted height")
    @MainActor
    func submittedSensorCardsInvalidateTheirHostedHeight() {
        let date = Date(timeIntervalSinceReferenceDate: 789012)
        let task = makeTask(id: "manual-heart-rate-layout", start: date, end: nil)
        let store = OCKStore(
            name: "SensorTaskContainerLayoutTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        let container = SensorTaskContainerView()
        let pendingEvent = SensorTaskEventCardModel(
            id: "pending",
            eventIndexPath: IndexPath(row: 0, section: 0),
            occurrence: 0,
            scheduledStart: date,
            hasSentOutcome: false,
            sentValueText: nil
        )
        let submittedEvent = SensorTaskEventCardModel(
            id: "submitted",
            eventIndexPath: IndexPath(row: 0, section: 0),
            occurrence: 0,
            scheduledStart: date,
            hasSentOutcome: true,
            sentValueText: "Sent 84 BPM"
        )

        container.update(
            task: task,
            eventCards: [pendingEvent],
            metric: .heartRate,
            mode: .manual,
            selectedDate: date,
            storeManager: storeManager
        )
        let pendingHeight = fittingHeight(for: container)

        container.update(
            task: task,
            eventCards: [submittedEvent],
            metric: .heartRate,
            mode: .manual,
            selectedDate: date,
            storeManager: storeManager
        )
        let submittedHeight = fittingHeight(for: container)

        #expect(submittedHeight > pendingHeight)
    }

    @Test("Twice-daily sensor schedules keep each occurrence independent")
    @MainActor
    func twiceDailySensorSchedulesKeepEachOccurrenceIndependent() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 1)
        ))
        let morning = try #require(calendar.date(byAdding: .hour, value: 8, to: day))
        let evening = try #require(calendar.date(byAdding: .hour, value: 20, to: day))
        let dayEnd = try #require(calendar.date(byAdding: .day, value: 1, to: day))
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: morning,
                end: nil,
                interval: DateComponents(day: 1)
            ),
            OCKScheduleElement(
                start: evening,
                end: nil,
                interval: DateComponents(day: 1)
            )
        ])
        let task = OCKTask(
            id: "twice-daily-heart-rate",
            title: "Heart Rate",
            carePlanUUID: nil,
            schedule: schedule
        )
        let scheduleEvents = task.schedule.events(from: day, to: dayEnd).sorted()
        #expect(scheduleEvents.count == 2)

        let submittedScheduleEvent = try #require(scheduleEvents.first)
        let outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: submittedScheduleEvent.occurrence,
            values: SensorOutcomeCodec.encode(
                SensorOutcomePayload(
                    metric: .heartRate,
                    reading: .heartRate(bpm: 84, date: morning),
                    mode: .sensor
                )
            )
        )
        let events = scheduleEvents.enumerated().map { index, scheduleEvent in
            OCKAnyEvent(
                task: task,
                outcome: index == 0 ? outcome : nil,
                scheduleEvent: scheduleEvent
            )
        }
        let store = OCKStore(
            name: "TwiceDailySensorScheduleTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        let synchronizer = SensorTaskViewSynchronizer(
            metric: .heartRate,
            mode: .sensor,
            selectedDate: day,
            storeManager: storeManager
        )

        let cardModels = synchronizer.eventCardModels(from: events)

        #expect(cardModels.count == 2)
        #expect(cardModels.map(\.eventIndexPath) == [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 1, section: 0)
        ])
        #expect(cardModels.map(\.occurrence) == scheduleEvents.map(\.occurrence))
        #expect(cardModels.map(\.scheduledStart) == [morning, evening])
        #expect(cardModels.map(\.hasSentOutcome) == [true, false])
        #expect(cardModels[0].sentValueText != nil)
        #expect(cardModels[1].sentValueText == nil)

        let secondPayload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: evening),
            mode: .sensor
        )
        let secondOutcome = try #require(SensorTaskOutcomeHelper.makeOutcome(
            payload: secondPayload,
            task: task,
            on: day,
            occurrence: cardModels[1].occurrence,
            now: evening
        ))

        #expect(secondOutcome.taskOccurrenceIndex == scheduleEvents[1].occurrence)
        #expect(secondOutcome.effectiveDate == scheduleEvents[1].start)

        let container = SensorTaskContainerView()
        container.update(
            task: task,
            eventCards: [cardModels[0]],
            metric: .heartRate,
            mode: .manual,
            selectedDate: day,
            storeManager: storeManager
        )
        let singleOccurrenceHeight = fittingHeight(for: container)
        container.update(
            task: task,
            eventCards: cardModels,
            metric: .heartRate,
            mode: .manual,
            selectedDate: day,
            storeManager: storeManager
        )
        let twiceDailyHeight = fittingHeight(for: container)

        #expect(twiceDailyHeight > singleOccurrenceHeight)
    }

    @Test("Mock sensor tasks use the selected non-today schedule date")
    func mockSensorTasksUseSelectedNonTodayDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let selectedDate = try #require(calendar.date(
            from: DateComponents(year: 2031, month: 5, day: 14, hour: 16, minute: 30)
        ))
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        let selectedDayEnd = try #require(calendar.date(byAdding: .day, value: 1, to: selectedDayStart))

        let task = CareKitStoreManager.makeMockSensorTask(
            for: .heartRate,
            mode: .manual,
            on: selectedDate,
            calendar: calendar
        )
        let events = task.schedule.events(from: selectedDayStart, to: selectedDayEnd)

        let event = try #require(events.first)
        #expect(events.count == 1)
        #expect(event.start == selectedDate)
        #expect(calendar.isDate(event.start, inSameDayAs: selectedDate))
        #expect(task.groupIdentifierKeys.viewType == .manualHeartRate)
    }

    @Test("Metric formatter preserves requested fraction digits")
    func metricFormatterPreservesRequestedFractionDigits() {
        #expect(MetricFormatter.format(12.6, decimals: 0) == "13")
        #expect(MetricFormatter.format(12, decimals: 0) == "12")

        let decimalValue = MetricFormatter.format(12.3, decimals: 2)
        #expect(decimalValue.hasSuffix("30"))
    }

    @Test("Mock data store uses default seed when unset and stored seed when present")
    func mockDataStoreUsesDefaultAndStoredSeed() {
        let defaults = UserDefaults.standard
        let enabledKey = Constants.Storage.kHealthSensorsMockEnabled
        let seedKey = Constants.Storage.kHealthSensorsMockSeed
        let originalEnabled = defaults.object(forKey: enabledKey)
        let originalSeed = defaults.object(forKey: seedKey)
        defer {
            restore(originalEnabled, forKey: enabledKey, defaults: defaults)
            restore(originalSeed, forKey: seedKey, defaults: defaults)
        }

        defaults.removeObject(forKey: enabledKey)
        defaults.removeObject(forKey: seedKey)
        #expect(!MockDataStore.isEnabled)
        #expect(MockDataStore.seed == 1)

        defaults.set(true, forKey: enabledKey)
        defaults.set(42, forKey: seedKey)
        #expect(MockDataStore.isEnabled)
        #expect(MockDataStore.seed == 42)
    }

    @Test("Seeded random generator is deterministic")
    func seededRandomGeneratorIsDeterministic() {
        var first = SeededRandomNumberGenerator(seed: 7)
        var second = SeededRandomNumberGenerator(seed: 7)

        #expect(first.next() == second.next())
        #expect(first.next() == second.next())
        #expect(first.next() == second.next())
    }

    @Test("Health metric identifiers and chart types remain stable")
    func healthMetricIdentifiersAndChartTypesRemainStable() {
        let metrics = HealthKitDataManager.HealthMetric.allCases

        #expect(metrics.map(\.id) == [
            "heartRate",
            "bloodGlucose",
            "bloodPressure",
            "ecg",
            "respiratoryRate",
            "restingHeartRate",
            "oxygenSaturation",
            "vo2Max"
        ])
        #expect(metrics.map { chartTypeName($0.chartType) } == [
            "line",
            "scatter",
            "line",
            "scatter",
            "line",
            "line",
            "line",
            "bar"
        ])
    }

    @Test("Health metrics derive display metadata from configuration")
    func healthMetricsDeriveDisplayMetadataFromConfiguration() {
        let config = HealthSensorsConfiguration.fallback
        let expected: [MetricMetadataExpectation] = [
            MetricMetadataExpectation(
                metric: .heartRate,
                title: "Heart Rate",
                subtitle: "Beats per minute",
                symbol: "heart.fill",
                unit: "BPM"
            ),
            MetricMetadataExpectation(
                metric: .bloodGlucose,
                title: "Blood Glucose",
                subtitle: "Sugar in blood",
                symbol: "drop.fill",
                unit: "mg/dL"
            ),
            MetricMetadataExpectation(
                metric: .bloodPressure,
                title: "Blood Pressure",
                subtitle: "Systolic & Diastolic",
                symbol: "waveform.path.ecg",
                unit: "mmHg"
            ),
            MetricMetadataExpectation(
                metric: .ecg,
                title: "Electrocardiogram",
                subtitle: "Electrical heart activity",
                symbol: "heart.text.square.fill",
                unit: "Records"
            ),
            MetricMetadataExpectation(
                metric: .respiratoryRate,
                title: "Respiratory Rate",
                subtitle: "Breaths per minute",
                symbol: "lungs.fill",
                unit: "br/min"
            ),
            MetricMetadataExpectation(
                metric: .restingHeartRate,
                title: "Resting Heart Rate",
                subtitle: "Resting beats per minute",
                symbol: "heart.fill",
                unit: "BPM"
            ),
            MetricMetadataExpectation(
                metric: .oxygenSaturation,
                title: "Oxygen Saturation",
                subtitle: "Oxygen level in blood",
                symbol: "o.circle.fill",
                unit: "%"
            ),
            MetricMetadataExpectation(
                metric: .vo2Max,
                title: config.cardTitleVO2Max.localized,
                subtitle: "Max oxygen consumption",
                symbol: "figure.run",
                unit: config.unitVO2Max.localized
            )
        ]

        for expectation in expected {
            #expect(expectation.metric.displayTitle(config: config) == expectation.title)
            #expect(expectation.metric.displaySubtitle(config: config) == expectation.subtitle)
            #expect(expectation.metric.displaySymbol(config: config) == expectation.symbol)
            #expect(expectation.metric.displayUnit(config: config) == expectation.unit)
            #expect(expectation.metric.displayEmptyStateTitle(config: config) == "No Data Available")
            #expect(expectation.metric.displayGuidanceSteps(config: config).count == 3)
        }
        #expect(
            HealthKitDataManager.HealthMetric.ecg.displayEmptyStateMessage(config: config) ==
                "No ECG records found on this device."
        )
        #expect(
            HealthKitDataManager.HealthMetric.vo2Max.displayGuidanceSteps(config: config) ==
                [
                    "Record an Outdoor Walk, Run, or Hiking workout.",
                    "Sustain efforts for at least 20 minutes.",
                    "Check 'Cardio Fitness' in the Health app."
                ]
        )
    }

    @Test("Health metric values expose optional primary display values and sample dates")
    func healthMetricValuesExposePrimaryDisplayValuesAndSampleDates() {
        let date = Date(timeIntervalSinceReferenceDate: 123)
        let values: [(HealthKitDataManager.HealthMetricValue, Double?)] = [
            (.heartRate(bpm: 72, date: date), 72),
            (.bloodGlucose(mgPerdL: 101, date: date), 101),
            (.bloodPressure(systolic: 118, diastolic: 76, unit: .millimeterOfMercury(), date: date), 118),
            (.ecg(classification: .sinusRhythm, averageBPM: 68, samplingHz: 512, duration: 30, date: date), 68),
            (.ecg(classification: .sinusRhythm, averageBPM: nil, samplingHz: nil, duration: nil, date: date), nil),
            (.respiratoryRate(breathsPerMin: 14, date: date), 14),
            (.restingHeartRate(bpm: 59, date: date), 59),
            (.oxygenSaturation(percent: 98, date: date), 98),
            (.vo2Max(mlPerKgMin: 42, date: date), 42),
            (.unavailable("No sample"), nil)
        ]

        for (value, expectedDisplayValue) in values {
            #expect(value.displayValue == expectedDisplayValue)
            if case .unavailable = value {
                continue
            }
            #expect(value.date == date)
        }
    }

    @Test("ECG charts omit samples without an average heart rate")
    func ecgChartsOmitSamplesWithoutAverageHeartRate() {
        let firstDate = Date(timeIntervalSinceReferenceDate: 123)
        let secondDate = firstDate.addingTimeInterval(60)
        let model = GenericHealthCardViewModel(metric: .ecg)

        let chartData = model.buildChartData(
            values: [
                .ecg(
                    classification: .sinusRhythm,
                    averageBPM: nil,
                    samplingHz: 512,
                    duration: 30,
                    date: firstDate
                ),
                .ecg(
                    classification: .sinusRhythm,
                    averageBPM: 68,
                    samplingHz: 512,
                    duration: 30,
                    date: secondDate
                )
            ],
            liveValue: nil,
            unit: "BPM"
        )

        #expect(chartData.summaryPoints.count == 1)
        #expect(chartData.summaryPoints.first?.value == 68)
        #expect(chartData.summaryPoints.first?.date == secondDate)
    }

    @Test("Health metric model wrappers preserve values and identifiers")
    func healthMetricModelWrappersPreserveValuesAndIdentifiers() {
        let date = Date(timeIntervalSinceReferenceDate: 42)
        let point = MetricPoint(date: date, value: 72)
        let series = MetricSeries(label: "Heart Rate", unit: "BPM", points: [point])
        let value = MetricValue(label: "Live", value: 73, unit: "BPM", date: date, source: .watchLive)

        #expect(series.label == "Heart Rate")
        #expect(series.unit == "BPM")
        #expect(series.points.first?.id == point.id)
        #expect(value.label == "Live")
        #expect(value.value == 73)
        #expect(value.source == .watchLive)
    }

    @Test("HealthKit authorization state uses injected availability and persisted requested metrics")
    func healthKitAuthorizationStateUsesInjectedAvailabilityAndPersistedRequestedMetrics() throws {
        let defaults = try isolatedHealthSensorDefaults()
        defer {
            defaults.removePersistentDomain(forName: defaultsSuiteName)
        }
        let key = Constants.Storage.kHealthKitRequestedMetrics

        let unavailableManager = HealthKitDataManager(
            defaults: defaults,
            healthDataAvailable: { false }
        )
        #expect(unavailableManager.authorizationState(for: [.heartRate]) == .denied)

        let freshManager = HealthKitDataManager(
            defaults: defaults,
            healthDataAvailable: { true }
        )
        #expect(freshManager.authorizationState(for: [.heartRate]) == .notDetermined)

        defaults.set(["heartRate", "vo2Max", "unknownMetric"], forKey: key)
        let restoredManager = HealthKitDataManager(
            defaults: defaults,
            healthDataAvailable: { true }
        )

        #expect(restoredManager.authorizationState(for: [.heartRate]) == .authorized)
        #expect(restoredManager.authorizationState(for: [.vo2Max]) == .authorized)
        #expect(restoredManager.authorizationState(for: [.bloodGlucose]) == .notDetermined)
    }
}

@MainActor
private func fittingHeight(for view: UIView, width: CGFloat = 350) -> CGFloat {
    view.bounds.size.width = width
    view.setNeedsLayout()
    view.layoutIfNeeded()
    return view.systemLayoutSizeFitting(
        CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
    ).height
}

private let defaultsSuiteName = "HealthSensorFormattingAndMockDataTests"

private func isolatedHealthSensorDefaults() throws -> UserDefaults {
    let defaults = try #require(UserDefaults(suiteName: defaultsSuiteName))
    defaults.removePersistentDomain(forName: defaultsSuiteName)
    return defaults
}

private func restore(_ value: Any?, forKey key: String, defaults: UserDefaults) {
    if let value {
        defaults.set(value, forKey: key)
    } else {
        defaults.removeObject(forKey: key)
    }
}

private func chartTypeName(_ chartType: HealthKitDataManager.HealthMetric.ChartType) -> String {
    switch chartType {
    case .line: "line"
    case .bar: "bar"
    case .scatter: "scatter"
    }
}
