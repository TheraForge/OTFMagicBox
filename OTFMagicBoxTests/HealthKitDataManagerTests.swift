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
import Testing
@testable import OTFMagicBox

@Suite("HealthKit data manager")
struct HealthKitDataManagerTests {
    @Test("Authorization request persists requested metrics after success")
    func authorizationRequestPersistsRequestedMetricsAfterSuccess() async throws {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "healthkit-data-manager")
        defer { defaultsFixture.cleanup() }
        let fakeStore = FakeHealthKitStore()
        let manager = HealthKitDataManager(
            defaults: defaultsFixture.defaults,
            healthDataAvailable: { true },
            healthStore: fakeStore
        )

        try await manager.requestAuthorization(for: [.heartRate, .bloodPressure])

        #expect(fakeStore.authorizationShareTypeIdentifiers.isEmpty)
        #expect(Set(fakeStore.authorizationReadTypeIdentifiers) == [
            HKQuantityTypeIdentifier.heartRate.rawValue,
            HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
            HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue
        ])
        #expect(manager.authorizationState(for: [.heartRate]) == .authorized)
        #expect(manager.authorizationState(for: [.bloodPressure]) == .authorized)
        #expect(manager.authorizationState(for: [.vo2Max]) == .notDetermined)
    }

    @Test("Authorization failure does not persist requested metrics")
    func authorizationFailureDoesNotPersistRequestedMetrics() async {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "healthkit-data-manager")
        defer { defaultsFixture.cleanup() }
        let fakeStore = FakeHealthKitStore()
        fakeStore.authorizationSuccess = false
        let manager = HealthKitDataManager(
            defaults: defaultsFixture.defaults,
            healthDataAvailable: { true },
            healthStore: fakeStore
        )

        do {
            try await manager.requestAuthorization(for: [.heartRate])
            Issue.record("Expected authorization failure")
        } catch {
            #expect((error as NSError).domain == "HealthKitDataManager")
        }

        #expect(manager.authorizationState(for: [.heartRate]) == .notDetermined)
    }

    @Test("Quantity sample fetchers convert HealthKit units into metric values")
    func quantitySampleFetchersConvertHealthKitUnitsIntoMetricValues() async throws {
        let date = Date(timeIntervalSince1970: 1_800_700_000)
        let fakeStore = FakeHealthKitStore()
        fakeStore.setQuantitySamples([
            quantitySample(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), value: 72, date: date)
        ], for: .heartRate)
        fakeStore.setQuantitySamples([
            quantitySample(.bloodGlucose, unit: HKUnit(from: "mg/dL"), value: 101, date: date)
        ], for: .bloodGlucose)
        fakeStore.setQuantitySamples([
            quantitySample(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), value: 14, date: date)
        ], for: .respiratoryRate)
        fakeStore.setQuantitySamples([
            quantitySample(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), value: 59, date: date)
        ], for: .restingHeartRate)
        fakeStore.setQuantitySamples([
            quantitySample(.oxygenSaturation, unit: HKUnit.percent(), value: 0.98, date: date)
        ], for: .oxygenSaturation)
        fakeStore.setQuantitySamples([
            quantitySample(.vo2Max, unit: vo2MaxUnit(), value: 42, date: date)
        ], for: .vo2Max)
        let manager = HealthKitDataManager(healthDataAvailable: { true }, healthStore: fakeStore)

        #expect(await manager.fetchLatestValue(for: .heartRate, since: 10, limit: 1) == [
            .heartRate(bpm: 72, date: date)
        ])
        #expect(await manager.fetchLatestValue(for: .bloodGlucose, since: 10, limit: 1) == [
            .bloodGlucose(mgPerdL: 101, date: date)
        ])
        #expect(await manager.fetchLatestValue(for: .respiratoryRate, since: 10, limit: 1) == [
            .respiratoryRate(breathsPerMin: 14, date: date)
        ])
        #expect(await manager.fetchLatestValue(for: .restingHeartRate, since: 10, limit: 1) == [
            .restingHeartRate(bpm: 59, date: date)
        ])
        #expect(await manager.fetchLatestValue(for: .oxygenSaturation, since: 10, limit: 1) == [
            .oxygenSaturation(percent: 98, date: date)
        ])
        #expect(await manager.fetchLatestValue(for: .vo2Max, since: 10, limit: 1) == [
            .vo2Max(mlPerKgMin: 42, date: date)
        ])
    }

    @Test("Blood pressure fetcher converts paired systolic and diastolic samples")
    func bloodPressureFetcherConvertsPairedSystolicAndDiastolicSamples() async throws {
        let date = Date(timeIntervalSince1970: 1_800_800_000)
        let fakeStore = FakeHealthKitStore()
        fakeStore.correlations = [
            try bloodPressureCorrelation(systolic: 118, diastolic: 76, date: date)
        ]
        let manager = HealthKitDataManager(healthDataAvailable: { true }, healthStore: fakeStore)

        let values = await manager.fetchLatestValue(for: .bloodPressure, since: 10, limit: 1)
        let value = try #require(values.first)

        guard case .bloodPressure(let systolic, let diastolic, _, let valueDate) = value else {
            Issue.record("Expected blood pressure value")
            return
        }
        #expect(systolic == 118)
        #expect(diastolic == 76)
        #expect(valueDate == date)
    }

    @Test("Empty injected query results return empty metric arrays")
    func emptyInjectedQueryResultsReturnEmptyMetricArrays() async {
        let manager = HealthKitDataManager(healthDataAvailable: { true }, healthStore: FakeHealthKitStore())

        #expect(await manager.fetchLatestValue(for: .heartRate, since: 10, limit: 1) == [])
        #expect(await manager.fetchLatestValue(for: .bloodPressure, since: 10, limit: 1) == [])
        #expect(await manager.fetchLatestValue(for: .ecg, since: 10, limit: 1) == [])
    }
}

private final class FakeHealthKitStore: HealthKitStoreQuerying {
    var authorizationSuccess = true
    var authorizationError: Error?
    var correlations = [HKCorrelation]()
    var electrocardiograms = [HKElectrocardiogram]()
    private var quantitySamplesByIdentifier = [String: [HKQuantitySample]]()
    private(set) var authorizationShareTypeIdentifiers = [String]()
    private(set) var authorizationReadTypeIdentifiers = [String]()

    func requestAuthorization(
        toShare shareTypes: Set<HKSampleType>,
        read readTypes: Set<HKObjectType>,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        authorizationShareTypeIdentifiers = shareTypes.map(\.identifier).sorted()
        authorizationReadTypeIdentifiers = readTypes.compactMap { ($0 as? HKSampleType)?.identifier }.sorted()
        completion(authorizationSuccess, authorizationError)
    }

    func quantitySamples(of type: HKQuantityType, since lookback: TimeInterval, limit: Int?) async -> [HKQuantitySample] {
        quantitySamplesByIdentifier[type.identifier] ?? []
    }

    func correlationSamples(of type: HKCorrelationType, since lookback: TimeInterval, limit: Int?) async -> [HKCorrelation] {
        correlations
    }

    func electrocardiogramSamples(since lookback: TimeInterval, limit: Int?) async -> [HKElectrocardiogram] {
        electrocardiograms
    }

    func setQuantitySamples(_ samples: [HKQuantitySample], for identifier: HKQuantityTypeIdentifier) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        quantitySamplesByIdentifier[type.identifier] = samples
    }
}

private func quantitySample(
    _ identifier: HKQuantityTypeIdentifier,
    unit: HKUnit,
    value: Double,
    date: Date
) -> HKQuantitySample {
    let type = HKObjectType.quantityType(forIdentifier: identifier)!
    let quantity = HKQuantity(unit: unit, doubleValue: value)
    return HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
}

private func bloodPressureCorrelation(systolic: Double, diastolic: Double, date: Date) throws -> HKCorrelation {
    let correlationType = try #require(HKObjectType.correlationType(forIdentifier: .bloodPressure))
    let systolicType = try #require(HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic))
    let diastolicType = try #require(HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic))
    let unit = HKUnit.millimeterOfMercury()
    let systolicSample = HKQuantitySample(
        type: systolicType,
        quantity: HKQuantity(unit: unit, doubleValue: systolic),
        start: date,
        end: date
    )
    let diastolicSample = HKQuantitySample(
        type: diastolicType,
        quantity: HKQuantity(unit: unit, doubleValue: diastolic),
        start: date,
        end: date
    )
    return HKCorrelation(
        type: correlationType,
        start: date,
        end: date,
        objects: [systolicSample, diastolicSample]
    )
}

private func vo2MaxUnit() -> HKUnit {
    HKUnit.literUnit(with: .milli)
        .unitDivided(by: HKUnit.gramUnit(with: .kilo))
        .unitDivided(by: HKUnit.minute())
}
