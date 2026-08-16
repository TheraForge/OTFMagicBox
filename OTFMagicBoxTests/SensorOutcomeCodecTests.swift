/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import Foundation
import HealthKit
import OTFCareKit
import OTFCareKitStore
import Testing
@testable import OTFMagicBox

@Suite("Sensor outcome codec")
struct SensorOutcomeCodecTests {
    private let date = Date(timeIntervalSinceReferenceDate: 789012)

    @Test("All metrics encode complete named values and round trip", arguments: SensorTaskMode.allCases)
    func allMetricsEncodeCompleteNamedValuesAndRoundTrip(mode: SensorTaskMode) {
        for testCase in codecCases {
            let payload = SensorOutcomePayload(
                metric: testCase.metric,
                reading: testCase.reading,
                mode: mode,
                notes: "  Felt steady  "
            )

            let values = SensorOutcomeCodec.encode(payload)

            #expect(values.map(\.kind) == testCase.kinds + ["date", "entryMode", "notes"])
            #expect(values.map(\.type) == testCase.types + [.date, .text, .text])
            #expect(values.map(\.units) == testCase.units + [nil, nil, nil])
            #expect(values[values.count - 3].dateValue == date)
            #expect(values[values.count - 2].stringValue == mode.rawValue)
            #expect(values.last?.stringValue == "Felt steady")
            #expect(
                SensorOutcomeCodec.decode(metric: testCase.metric, values: values) ==
                    .payload(
                        SensorOutcomePayload(
                            metric: testCase.metric,
                            reading: testCase.reading,
                            mode: mode,
                            notes: "Felt steady"
                        )
                    )
            )
        }
    }

    @Test("Whitespace notes and optional ECG values are omitted")
    func whitespaceNotesAndOptionalECGValuesAreOmitted() {
        let reading = HealthKitDataManager.HealthMetricValue.ecg(
            classification: .sinusRhythm,
            averageBPM: nil,
            samplingHz: nil,
            duration: nil,
            date: date
        )
        let payload = SensorOutcomePayload(
            metric: .ecg,
            reading: reading,
            mode: .sensor,
            notes: " \n "
        )

        let values = SensorOutcomeCodec.encode(payload)

        #expect(values.map(\.kind) == ["classification", "date", "entryMode"])
        #expect(values.map(\.type) == [.integer, .date, .text])
        #expect(payload.notes == nil)
        #expect(
            SensorOutcomeCodec.decode(metric: .ecg, values: values) ==
                .payload(payload)
        )
    }

    @Test("Legacy unnamed values stay legacy with unknown mode")
    func legacyUnnamedValuesStayLegacyWithUnknownMode() {
        let value = OCKOutcomeValue(72.0, units: "BPM")
        let decoded = SensorOutcomeCodec.decode(metric: .heartRate, values: [value])

        #expect(decoded == .legacy([value]))
    }

    @Test("CareKit outcome Codable round trip preserves named sensor values")
    func careKitOutcomeCodableRoundTripPreservesNamedSensorValues() throws {
        let payload = SensorOutcomePayload(
            metric: .bloodPressure,
            reading: .bloodPressure(
                systolic: 118,
                diastolic: 76,
                unit: .millimeterOfMercury(),
                date: date
            ),
            mode: .manual,
            notes: "After resting"
        )
        let outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 4,
            values: SensorOutcomeCodec.encode(payload)
        )

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(OCKOutcome.self, from: data)

        #expect(decoded.taskUUID == outcome.taskUUID)
        #expect(decoded.taskOccurrenceIndex == 4)
        #expect(decoded.values == outcome.values)
        #expect(
            SensorOutcomeCodec.decode(metric: .bloodPressure, values: decoded.values) ==
                .payload(payload)
        )
    }

    @Test("CareKit store persists manual and sensor outcomes by occurrence")
    func careKitStorePersistsManualAndSensorOutcomesByOccurrence() async throws {
        let calendar = Calendar.current
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
            id: "persisted-heart-rate",
            title: "Heart Rate",
            carePlanUUID: nil,
            schedule: schedule
        )
        let events = task.schedule.events(from: day, to: dayEnd).sorted()
        #expect(events.count == 2)
        let morningEvent = try #require(events.first)
        let eveningEvent = try #require(events.last)
        let store = OCKStore(
            name: "SensorOutcomePersistenceTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        try await addSensorTask(task, to: store)

        let manualPayload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: morning),
            mode: .manual,
            notes: "Before breakfast"
        )
        let sensorPayload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 84, date: evening),
            mode: .sensor,
            notes: "After walking"
        )

        #expect(try await sendSensorOutcome(
            manualPayload,
            task: task,
            date: day,
            occurrence: morningEvent.occurrence,
            storeManager: storeManager,
            now: evening
        ))
        #expect(try await sendSensorOutcome(
            sensorPayload,
            task: task,
            date: day,
            occurrence: eveningEvent.occurrence,
            storeManager: storeManager,
            now: evening
        ))

        let persistedEvents = try await fetchSensorEvents(
            from: store,
            taskID: task.id,
            on: day
        ).sorted { $0.scheduleEvent.occurrence < $1.scheduleEvent.occurrence }

        #expect(persistedEvents.count == 2)
        guard persistedEvents.count == 2 else { return }
        #expect(persistedEvents.map(\.scheduleEvent.occurrence) == [
            morningEvent.occurrence,
            eveningEvent.occurrence
        ])
        let manualOutcome = try #require(persistedEvents[0].outcome)
        let sensorOutcome = try #require(persistedEvents[1].outcome)
        #expect((manualOutcome as? OCKOutcome)?.effectiveDate == morningEvent.start)
        #expect((sensorOutcome as? OCKOutcome)?.effectiveDate == eveningEvent.start)
        #expect(
            SensorOutcomeCodec.decode(metric: .heartRate, values: manualOutcome.values) ==
                .payload(manualPayload)
        )
        #expect(
            SensorOutcomeCodec.decode(metric: .heartRate, values: sensorOutcome.values) ==
                .payload(sensorPayload)
        )
    }

    @Test("Sensor readings older than fifteen minutes are rejected before persistence")
    func staleSensorReadingsAreRejectedBeforePersistence() async throws {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let day = Calendar.current.startOfDay(for: now)
        let task = makeTask(id: "stale-sensor-reading", start: day, end: nil)
        let store = OCKStore(
            name: "StaleSensorOutcomeTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        try await addSensorTask(task, to: store)
        let event = try #require(SensorTaskOutcomeHelper.event(for: task, on: day))
        let payload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(
                bpm: 72,
                date: now.addingTimeInterval(
                    -SensorOutcomeSubmissionPolicy.maximumSensorReadingAge - 1
                )
            ),
            mode: .sensor
        )

        let success = try await sendSensorOutcome(
            payload,
            task: task,
            date: day,
            occurrence: event.occurrence,
            storeManager: storeManager,
            now: now
        )

        #expect(!SensorOutcomeSubmissionPolicy.canSubmit(payload, on: day, now: now))
        #expect(!success)
        #expect(try await fetchSensorOutcomes(from: store, on: day).isEmpty)
    }

    @Test("Future sensor tasks cannot be completed")
    func futureSensorTasksCannotBeCompleted() async throws {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let futureDay = try #require(Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: now)
        ))
        let task = makeTask(id: "future-sensor-task", start: futureDay, end: nil)
        let store = OCKStore(
            name: "FutureSensorOutcomeTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        try await addSensorTask(task, to: store)
        let event = try #require(SensorTaskOutcomeHelper.event(for: task, on: futureDay))
        let payload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: now),
            mode: .sensor
        )

        let success = try await sendSensorOutcome(
            payload,
            task: task,
            date: futureDay,
            occurrence: event.occurrence,
            storeManager: storeManager,
            now: now
        )

        #expect(!SensorOutcomeSubmissionPolicy.canSubmit(payload, on: futureDay, now: now))
        #expect(!success)
        #expect(try await fetchSensorOutcomes(from: store, on: futureDay).isEmpty)
    }

    @Test("CareKit store failure is reported when sending an outcome")
    func careKitStoreFailureIsReportedWhenSendingAnOutcome() async throws {
        let task = makeTask(id: "missing-store-task", start: date, end: nil)
        let store = OCKStore(
            name: "SensorOutcomeFailureTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let payload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: date),
            mode: .manual
        )

        let success = try await sendSensorOutcome(
            payload,
            task: task,
            date: date,
            occurrence: 0,
            storeManager: OCKSynchronizedStoreManager(wrapping: store)
        )

        #expect(!success)
        #expect(try await fetchSensorOutcomes(from: store, on: date).isEmpty)
    }

    @Test("UILab exposes eight unique metric routes with both detail modes")
    func uiLabExposesEightUniqueMetricRoutesWithBothModes() {
        #expect(CardRegistry.cards.count == 8)
        #expect(Set(CardRegistry.cards.map(\.id)).count == 8)
        #expect(SensorTaskMode.allCases == [.sensor, .manual])
    }

    @Test("Legacy automatic entry mode decodes as sensor")
    func legacyAutomaticEntryModeDecodesAsSensor() throws {
        let payload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: date),
            mode: .sensor
        )
        var values = SensorOutcomeCodec.encode(payload)
        let modeIndex = try #require(values.firstIndex {
            $0.kind == SensorOutcomeValueKind.entryMode.rawValue
        })
        var legacyMode = OCKOutcomeValue("automatic")
        legacyMode.kind = SensorOutcomeValueKind.entryMode.rawValue
        values[modeIndex] = legacyMode

        #expect(
            SensorOutcomeCodec.decode(metric: .heartRate, values: values) ==
                .payload(payload)
        )
    }

    private var codecCases: [SensorCodecCase] {
        [
            SensorCodecCase(
                metric: .heartRate,
                reading: .heartRate(bpm: 72, date: date),
                kinds: ["bpm"],
                types: [.double],
                units: [SensorOutcomeUnits.bpm]
            ),
            SensorCodecCase(
                metric: .bloodGlucose,
                reading: .bloodGlucose(mgPerdL: 104, date: date),
                kinds: ["mgPerdL"],
                types: [.double],
                units: [SensorOutcomeUnits.bloodGlucose]
            ),
            SensorCodecCase(
                metric: .bloodPressure,
                reading: .bloodPressure(
                    systolic: 118,
                    diastolic: 76,
                    unit: .millimeterOfMercury(),
                    date: date
                ),
                kinds: ["systolic", "diastolic", "unit"],
                types: [.double, .double, .text],
                units: [
                    SensorOutcomeUnits.bloodPressure,
                    SensorOutcomeUnits.bloodPressure,
                    nil
                ]
            ),
            SensorCodecCase(
                metric: .ecg,
                reading: .ecg(
                    classification: .sinusRhythm,
                    averageBPM: 68,
                    samplingHz: 512,
                    duration: 30,
                    date: date
                ),
                kinds: ["classification", "averageBPM", "samplingHz", "duration"],
                types: [.integer, .double, .double, .double],
                units: [nil, SensorOutcomeUnits.bpm, SensorOutcomeUnits.hertz, SensorOutcomeUnits.seconds]
            ),
            SensorCodecCase(
                metric: .respiratoryRate,
                reading: .respiratoryRate(breathsPerMin: 15, date: date),
                kinds: ["breathsPerMin"],
                types: [.double],
                units: [SensorOutcomeUnits.respiratoryRate]
            ),
            SensorCodecCase(
                metric: .restingHeartRate,
                reading: .restingHeartRate(bpm: 58, date: date),
                kinds: ["bpm"],
                types: [.double],
                units: [SensorOutcomeUnits.bpm]
            ),
            SensorCodecCase(
                metric: .oxygenSaturation,
                reading: .oxygenSaturation(percent: 98, date: date),
                kinds: ["percent"],
                types: [.double],
                units: [SensorOutcomeUnits.percent]
            ),
            SensorCodecCase(
                metric: .vo2Max,
                reading: .vo2Max(mlPerKgMin: 42.5, date: date),
                kinds: ["mlPerKgMin"],
                types: [.double],
                units: [SensorOutcomeUnits.vo2Max]
            )
        ]
    }
}

@Suite("Manual sensor validation")
@MainActor
struct ManualSensorValidationTests {
    enum ECGOptionalField: CaseIterable {
        case averageBPM
        case samplingHz
        case duration

        func set(_ value: String, on model: ManualSensorEntryViewModel) {
            switch self {
            case .averageBPM:
                model.averageBPM = value
            case .samplingHz:
                model.samplingHz = value
            case .duration:
                model.duration = value
            }
        }
    }

    private let date = Date(timeIntervalSinceReferenceDate: 456789)

    @Test(
        "Every single-value metric rejects malformed values",
        arguments: [
            HealthKitDataManager.HealthMetric.heartRate,
            .bloodGlucose,
            .respiratoryRate,
            .restingHeartRate,
            .oxygenSaturation,
            .vo2Max
        ],
        ["", " ", "0", "-1", "nan", "inf", "abc"]
    )
    func singleValueMetricsRejectMalformedValues(
        metric: HealthKitDataManager.HealthMetric,
        invalidValue: String
    ) {
        let model = ManualSensorEntryViewModel(
            metric: metric,
            date: date,
            now: { self.date }
        )

        model.primaryValue = invalidValue

        #expect(!model.isValid)
        #expect(model.payload == nil)
    }

    @Test("Every single-value metric preserves its exact parsed value and date")
    func singleValueMetricsPreserveExactValuesAndDates() throws {
        let cases = [
            SingleValueMetricCase(
                metric: .heartRate,
                expectedReading: .heartRate(bpm: 72.5, date: date)
            ),
            SingleValueMetricCase(
                metric: .bloodGlucose,
                expectedReading: .bloodGlucose(mgPerdL: 72.5, date: date)
            ),
            SingleValueMetricCase(
                metric: .respiratoryRate,
                expectedReading: .respiratoryRate(breathsPerMin: 72.5, date: date)
            ),
            SingleValueMetricCase(
                metric: .restingHeartRate,
                expectedReading: .restingHeartRate(bpm: 72.5, date: date)
            ),
            SingleValueMetricCase(
                metric: .oxygenSaturation,
                expectedReading: .oxygenSaturation(percent: 72.5, date: date)
            ),
            SingleValueMetricCase(
                metric: .vo2Max,
                expectedReading: .vo2Max(mlPerKgMin: 72.5, date: date)
            )
        ]

        for testCase in cases {
            let model = ManualSensorEntryViewModel(
                metric: testCase.metric,
                date: date,
                now: { self.date }
            )
            model.primaryValue = "72,5"

            let payload = try #require(model.payload)
            #expect(payload.mode == .manual)
            #expect(payload.reading == testCase.expectedReading)
        }
    }

    @Test("Oxygen saturation is limited to one hundred percent")
    func oxygenSaturationIsLimitedToOneHundredPercent() {
        let model = ManualSensorEntryViewModel(
            metric: .oxygenSaturation,
            date: date,
            now: { self.date }
        )

        model.primaryValue = "100"
        #expect(model.isValid)
        model.primaryValue = "100.1"
        #expect(!model.isValid)
    }

    @Test("Future reading dates are invalid")
    func futureReadingDatesAreInvalid() {
        let model = ManualSensorEntryViewModel(
            metric: .bloodGlucose,
            date: date.addingTimeInterval(1),
            now: { self.date }
        )
        model.primaryValue = "98"

        #expect(!model.isValid)
        #expect(model.payload == nil)
    }

    @Test("A manual task keeps the selected schedule day after its entry date changes")
    func manualTaskKeepsSelectedScheduleDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let selectedDate = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 1, hour: 8)
        ))
        let changedPickerDate = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 5, day: 1, hour: 16, minute: 45)
        ))
        let now = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 2)
        ))
        let task = makeTask(id: "manual-heart-rate", start: selectedDate, end: nil)
        let store = OCKStore(
            name: "ManualSensorSelectedDateTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let detailModel = SensorTaskDetailViewModel(
            task: task,
            selectedDate: selectedDate,
            occurrence: 0,
            storeManager: OCKSynchronizedStoreManager(wrapping: store),
            metric: .heartRate,
            mode: .manual
        )
        let entryModel = ManualSensorEntryViewModel(
            metric: .heartRate,
            date: detailModel.manualEntryDate,
            scheduledDate: detailModel.manualEntryDate,
            calendar: calendar,
            now: { now }
        )
        entryModel.date = changedPickerDate
        entryModel.primaryValue = "72"

        let payload = try #require(entryModel.payload)
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: payload.reading.date
        )

        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 1)
        #expect(components.hour == 16)
        #expect(components.minute == 45)
    }

    @Test("An unscheduled manual entry keeps the selected date")
    func unscheduledManualEntryKeepsSelectedDate() throws {
        let selectedDate = date.addingTimeInterval(-86400)
        let model = ManualSensorEntryViewModel(
            metric: .heartRate,
            date: selectedDate,
            now: { self.date }
        )
        model.primaryValue = "72"

        let payload = try #require(model.payload)

        #expect(payload.reading.date == selectedDate)
    }

    @Test("Blood pressure always emits canonical millimeters of mercury")
    func bloodPressureAlwaysEmitsCanonicalMillimetersOfMercury() throws {
        let model = ManualSensorEntryViewModel(
            metric: .bloodPressure,
            date: date,
            now: { self.date }
        )
        model.primaryValue = "118"
        model.secondaryValue = "76"

        let payload = try #require(model.payload)
        let values = SensorOutcomeCodec.encode(payload)

        #expect(values.map(\.kind) == ["systolic", "diastolic", "unit", "date", "entryMode"])
        #expect(values[0].units == "mmHg")
        #expect(values[1].units == "mmHg")
        #expect(values[2].stringValue == "mmHg")
    }

    @Test(
        "Blood pressure requires two positive finite values",
        arguments: [
            ("", "76"),
            ("118", ""),
            ("0", "76"),
            ("118", "0"),
            ("nan", "76"),
            ("118", "inf"),
            ("abc", "76"),
            ("118", "abc")
        ]
    )
    func bloodPressureRejectsInvalidValues(systolic: String, diastolic: String) {
        let model = ManualSensorEntryViewModel(
            metric: .bloodPressure,
            date: date,
            now: { self.date }
        )
        model.primaryValue = systolic
        model.secondaryValue = diastolic

        #expect(!model.isValid)
        #expect(model.payload == nil)
    }

    @Test(
        "Blood pressure requires systolic to be greater than diastolic",
        arguments: [
            ("70", "120"),
            ("120", "120")
        ]
    )
    func bloodPressureRejectsReversedOrEqualValues(systolic: String, diastolic: String) {
        let model = ManualSensorEntryViewModel(
            metric: .bloodPressure,
            date: date,
            now: { self.date }
        )
        model.primaryValue = systolic
        model.secondaryValue = diastolic

        #expect(!model.isValid)
        #expect(model.payload == nil)
    }

    @Test(
        "Every manual ECG classification is accepted",
        arguments: HKElectrocardiogram.Classification.manualEntryCases
    )
    func manualECGClassificationsAreAccepted(classification: HKElectrocardiogram.Classification) {
        let model = ManualSensorEntryViewModel(
            metric: .ecg,
            date: date,
            now: { self.date }
        )
        model.ecgClassificationRawValue = classification.rawValue

        #expect(model.isValid)
    }

    @Test("ECG rejects missing, not-set, and unknown classifications")
    func ecgRejectsUnsupportedClassifications() {
        let model = ManualSensorEntryViewModel(
            metric: .ecg,
            date: date,
            now: { self.date }
        )

        #expect(!model.isValid)
        model.ecgClassificationRawValue = HKElectrocardiogram.Classification.notSet.rawValue
        #expect(!model.isValid)
        model.ecgClassificationRawValue = Int.max
        #expect(!model.isValid)
    }

    @Test(
        "ECG optional values must be positive and finite when supplied",
        arguments: ECGOptionalField.allCases,
        ["0", "-1", "nan", "inf", "abc"]
    )
    func ecgRejectsInvalidOptionalValues(field: ECGOptionalField, invalidValue: String) {
        let model = ManualSensorEntryViewModel(
            metric: .ecg,
            date: date,
            now: { self.date }
        )
        model.ecgClassificationRawValue = HKElectrocardiogram.Classification.sinusRhythm.rawValue
        field.set(invalidValue, on: model)

        #expect(!model.isValid)
        #expect(model.payload == nil)
    }

    @Test("ECG optional values may be omitted or supplied together")
    func ecgOptionalValuesMayBeOmittedOrSuppliedTogether() throws {
        let model = ManualSensorEntryViewModel(
            metric: .ecg,
            date: date,
            now: { self.date }
        )
        model.ecgClassificationRawValue = HKElectrocardiogram.Classification.sinusRhythm.rawValue

        #expect(model.isValid)
        model.averageBPM = "68"
        model.samplingHz = "512"
        model.duration = "30"
        let payload = try #require(model.payload)
        #expect(payload.reading == .ecg(
            classification: .sinusRhythm,
            averageBPM: 68,
            samplingHz: 512,
            duration: 30,
            date: date
        ))
    }

    @Test(
        "Each single and pair of optional ECG fields survives into the payload",
        arguments: ECGOptionalValues.singleAndPairCases
    )
    func ecgOptionalValuesValidateIndependently(values: ECGOptionalValues) throws {
        let model = ManualSensorEntryViewModel(
            metric: .ecg,
            date: date,
            now: { self.date }
        )
        model.ecgClassificationRawValue = HKElectrocardiogram.Classification.sinusRhythm.rawValue
        model.averageBPM = values.averageBPM.map { String($0) } ?? ""
        model.samplingHz = values.samplingHz.map { String($0) } ?? ""
        model.duration = values.duration.map { String($0) } ?? ""

        let payload = try #require(model.payload)
        #expect(payload.reading == .ecg(
            classification: .sinusRhythm,
            averageBPM: values.averageBPM,
            samplingHz: values.samplingHz,
            duration: values.duration,
            date: date
        ))
    }
}

@Suite("Sensor task detail refresh")
@MainActor
struct SensorTaskDetailRefreshTests {
    @Test("A stale refresh cannot overwrite a newer submitted result")
    func staleRefreshCannotOverwriteNewerSubmittedResult() throws {
        let date = Date(timeIntervalSinceReferenceDate: 789012)
        let task = makeTask(id: "ordered-refresh", start: date, end: nil)
        let payload = SensorOutcomePayload(
            metric: .heartRate,
            reading: .heartRate(bpm: 72, date: date),
            mode: .sensor
        )
        let outcome = try #require(SensorTaskOutcomeHelper.makeOutcome(
            payload: payload,
            task: task,
            on: date,
            occurrence: 0,
            now: date
        ))
        var completions = [
            (Result<[OCKAnyOutcome], OCKStoreError>) -> Void
        ]()
        let store = OCKStore(
            name: "SensorRefreshOrderingTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let model = SensorTaskDetailViewModel(
            task: task,
            selectedDate: date,
            occurrence: 0,
            storeManager: OCKSynchronizedStoreManager(wrapping: store),
            metric: .heartRate,
            mode: .sensor,
            outcomeFetcher: { _, _, completion in
                completions.append(completion)
            }
        )

        model.refresh()
        model.refresh()
        #expect(completions.count == 2)
        guard completions.count == 2 else { return }

        completions[1](.success([outcome]))
        assertSubmitted(model.state, equals: payload)
        #expect(model.sendOutcomeDisabled)

        completions[0](.success([]))
        assertSubmitted(model.state, equals: payload)
        #expect(model.sendOutcomeDisabled)
    }

    private func assertSubmitted(
        _ state: SensorTaskDetailState,
        equals payload: SensorOutcomePayload,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .submitted(let outcome, _) = state else {
            Issue.record("Expected submitted state", sourceLocation: sourceLocation)
            return
        }
        #expect(outcome == .payload(payload), sourceLocation: sourceLocation)
    }
}

private struct SensorCodecCase {
    let metric: HealthKitDataManager.HealthMetric
    let reading: HealthKitDataManager.HealthMetricValue
    let kinds: [String?]
    let types: [OCKOutcomeValueType]
    let units: [String?]
}

private struct SingleValueMetricCase {
    let metric: HealthKitDataManager.HealthMetric
    let expectedReading: HealthKitDataManager.HealthMetricValue
}

struct ECGOptionalValues: Sendable, CustomTestStringConvertible {
    let averageBPM: Double?
    let samplingHz: Double?
    let duration: Double?

    var testDescription: String {
        [
            averageBPM.map { "averageBPM=\($0)" },
            samplingHz.map { "samplingHz=\($0)" },
            duration.map { "duration=\($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    static let singleAndPairCases = [
        ECGOptionalValues(averageBPM: 68, samplingHz: nil, duration: nil),
        ECGOptionalValues(averageBPM: nil, samplingHz: 512, duration: nil),
        ECGOptionalValues(averageBPM: nil, samplingHz: nil, duration: 30),
        ECGOptionalValues(averageBPM: 68, samplingHz: 512, duration: nil),
        ECGOptionalValues(averageBPM: 68, samplingHz: nil, duration: 30),
        ECGOptionalValues(averageBPM: nil, samplingHz: 512, duration: 30)
    ]
}

private func addSensorTask(_ task: OCKTask, to store: OCKStore) async throws {
    let result = await withCheckedContinuation { continuation in
        store.addAnyTask(task, callbackQueue: .main) { result in
            continuation.resume(returning: result)
        }
    }

    if case .failure(let error) = result {
        throw error
    }
}

private func sendSensorOutcome(
    _ payload: SensorOutcomePayload,
    task: OCKAnyTask,
    date: Date,
    occurrence: Int,
    storeManager: OCKSynchronizedStoreManager,
    now: Date = Date()
) async throws -> Bool {
    await withCheckedContinuation { continuation in
        SensorTaskOutcomeHelper.sendOutcome(
            payload: payload,
            task: task,
            on: date,
            occurrence: occurrence,
            storeManager: storeManager,
            environment: .current(now: now)
        ) { success in
            continuation.resume(returning: success)
        }
    }
}

private func fetchSensorEvents(
    from store: OCKStore,
    taskID: String,
    on date: Date
) async throws -> [OCKAnyEvent] {
    let result = await withCheckedContinuation { continuation in
        store.fetchAnyEvents(
            taskID: taskID,
            query: OCKEventQuery(for: date),
            callbackQueue: .main
        ) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let events):
        return events
    case .failure(let error):
        throw error
    }
}

private func fetchSensorOutcomes(from store: OCKStore, on date: Date) async throws -> [OCKAnyOutcome] {
    let result = await withCheckedContinuation { continuation in
        store.fetchAnyOutcomes(query: OCKOutcomeQuery(for: date), callbackQueue: .main) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let outcomes):
        return outcomes
    case .failure(let error):
        throw error
    }
}
