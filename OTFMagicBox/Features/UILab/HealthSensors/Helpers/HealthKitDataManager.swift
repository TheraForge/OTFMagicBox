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

final class HealthKitDataManager {

    enum HealthMetric: CaseIterable {
        case heartRate
        case bloodGlucose
        case bloodPressure
        case ecg
        case respiratoryRate
        case restingHeartRate
        case oxygenSaturation
        case vo2Max
    }

    enum HealthMetricValue: Equatable {
        case heartRate(bpm: Double, date: Date)
        case bloodGlucose(mgPerdL: Double, date: Date)
        case bloodPressure(systolic: Double, diastolic: Double, unit: HKUnit, date: Date)
        case ecg(classification: HKElectrocardiogram.Classification, averageBPM: Double?, samplingHz: Double?, duration: TimeInterval?, date: Date)
        case respiratoryRate(breathsPerMin: Double, date: Date)
        case restingHeartRate(bpm: Double, date: Date)
        case oxygenSaturation(percent: Double, date: Date)
        case vo2Max(mlPerKgMin: Double, date: Date)
        case unavailable(String)

        var date: Date {
            switch self {
            case .heartRate(_, let date):
                return date
            case .bloodGlucose(_, let date):
                return date
            case .bloodPressure(_, _, _, let date):
                return date
            case .ecg(_, _, _, _, let date):
                return date
            case .respiratoryRate(_, let date):
                return date
            case .restingHeartRate(_, let date):
                return date
            case .oxygenSaturation(_, let date):
                return date
            case .vo2Max(_, let date):
                return date
            case .unavailable:
                return Date()
            }
        }
    }

    /// Authorization state for a given metric
    enum AuthorizationState {
        case notDetermined
        case authorized
        case denied
    }

    // MARK: - Type mapping
    private static func readTypes(for metrics: Set<HealthMetric>) -> Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        for metric in metrics {
            switch metric {
            case .heartRate:
                if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                    types.insert(heartRateType)
                }
            case .bloodGlucose:
                if let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) {
                    types.insert(bloodGlucoseType)
                }
            case .bloodPressure:
                if let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
                    types.insert(systolicType)
                }
                if let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
                    types.insert(diastolicType)
                }
            case .ecg:
                types.insert(HKObjectType.electrocardiogramType())
            case .respiratoryRate:
                if let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
                    types.insert(respiratoryType)
                }
            case .restingHeartRate:
                if let restingType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
                    types.insert(restingType)
                }
            case .oxygenSaturation:
                if let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
                    types.insert(spo2Type)
                }
            case .vo2Max:
                if let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max) {
                    types.insert(vo2Type)
                }
            }
        }
        return types
    }

    private let healthStore = HKHealthStore()
    
    /// Storage key for requested metrics
    private let requestedMetricsKey = Constants.Storage.kHealthKitRequestedMetrics

    /// Track whether we have requested authorization for specific metrics
    private var requestedMetrics: Set<HealthMetric> = []

    init() {
        loadRequestedMetrics()
    }
    
    private func loadRequestedMetrics() {
        if let savedParams = UserDefaults.standard.array(forKey: requestedMetricsKey) as? [String] {
            let loadedMetrics = savedParams.compactMap { id -> HealthMetric? in
                HealthMetric.allCases.first { String(describing: $0) == id }
            }
            requestedMetrics = Set(loadedMetrics)
        }
    }
    
    private func saveRequestedMetrics() {
        let params = requestedMetrics.map { String(describing: $0) }
        UserDefaults.standard.set(params, forKey: requestedMetricsKey)
    }

    // MARK: - Authorization

    /// Requests authorization only for the specified metrics.
    func requestAuthorization(for metrics: Set<HealthMetric>) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(
                domain: "HealthKitDataManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit not available on this device."]
            )
        }
        let readTypes = Self.readTypes(for: metrics)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "HealthKitDataManager",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Authorization not granted."]
                        )
                    )
                    return
                }
                continuation.resume()
            }
        }
        // Mark these metrics as requested
        requestedMetrics.formUnion(metrics)
        saveRequestedMetrics()
    }

    /// Check authorization state for read access.
    /// Note: HealthKit doesn't provide a reliable way to check read authorization status.
    /// The `authorizationStatus(for:)` method only reflects WRITE access.
    /// For read access, we must attempt to fetch data - if we get results, we have access.
    /// This method returns a best-guess based on whether we have requested permission before.
    func authorizationState(for metrics: Set<HealthMetric>) -> AuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .denied
        }

        // If we haven't requested permission yet, return notDetermined
        if requestedMetrics.isDisjoint(with: metrics) {
            return .notDetermined
        }

        // Once requested, assume authorized (we can't reliably check read access)
        // The data fetch will return empty if access was actually denied
        return .authorized
    }

    // MARK: - fetch API

    func fetchLatestValue(
        for metric: HealthMetric,
        since lookback: TimeInterval = 60 * 60 * 24 * 7,
        limit: Int? = nil
    ) async -> [HealthMetricValue] {
        switch metric {
        case .heartRate:
            return await fetchLatestHeartRate(since: lookback, limit: limit)
        case .bloodGlucose:
            return await fetchLatestBloodGlucose(since: lookback, limit: limit)
        case .bloodPressure:
            return await fetchLatestBloodPressure(since: lookback, limit: limit)
        case .ecg:
            return await fetchLatestECG(since: lookback, limit: limit)
        case .respiratoryRate:
            return await fetchLatestRespiratoryRate(since: lookback, limit: limit)
        case .restingHeartRate:
            return await fetchLatestRestingHeartRate(since: lookback, limit: limit)
        case .oxygenSaturation:
            return await fetchLatestOxygenSaturation(since: lookback, limit: limit)
        case .vo2Max:
            return await fetchLatestVO2Max(since: lookback, limit: limit)
        }
    }

    /// Fetch the latest values for a collection of metrics. Authorization should be requested beforehand.
    func fetchLatestValues(
        for metrics: Set<HealthMetric>,
        since lookback: TimeInterval = 60 * 60 * 24 * 7,
        limit: Int? = nil
    ) async -> [HealthMetric: [HealthMetricValue]] {
        var results: [HealthMetric: [HealthMetricValue]] = [:]
        await withTaskGroup(of: (HealthMetric, [HealthMetricValue]).self) { group in
            for metric in metrics {
                group.addTask { [lookback, limit] in
                    let value = await self.fetchLatestValue(for: metric, since: lookback, limit: limit)
                    return (metric, value)
                }
            }
            for await (metric, value) in group {
                results[metric] = value
            }
        }
        return results
    }

    // MARK: - Individual fetchers

    func fetchLatestHeartRate(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return [.unavailable("Heart Rate type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { sample in
            let bpm = sample.quantity.doubleValue(for: unit)
            return .heartRate(bpm: bpm, date: sample.endDate)
        }
    }

    func fetchLatestBloodGlucose(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            return [.unavailable("Blood Glucose type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        let mgPerdLUnit = HKUnit(from: "mg/dL")
        return samples.map { sample in
            // Most apps show mg/dL; convert from the HealthKit base unit
            var value = sample.quantity.doubleValue(for: mgPerdLUnit)
            if value == 0 {
                // try mmol/L -> mg/dL
                let mmolL = sample.quantity.doubleValue(
                    for: HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
                )
                if mmolL > 0 {
                    value = mmolL * 18.0
                }
            }
            return .bloodGlucose(mgPerdL: value, date: sample.endDate)
        }
    }

    func fetchLatestBloodPressure(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let corrType = HKObjectType.correlationType(forIdentifier: .bloodPressure),
              let sysType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diaType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return [.unavailable("Blood Pressure types unavailable")]
        }

        let startDate = Date().addingTimeInterval(-lookback)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let queryLimit = limit ?? HKObjectQueryNoLimit

        let samples: [HKCorrelation] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: corrType,
                predicate: predicate,
                limit: queryLimit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                continuation.resume(returning: results as? [HKCorrelation] ?? [])
            }
            self.healthStore.execute(query)
        }

        if samples.isEmpty {
            return []
        }
        let unit = HKUnit.millimeterOfMercury()
        return samples.compactMap { bloodPressure in
            guard let sys = bloodPressure.objects(for: sysType).first as? HKQuantitySample,
                  let dia = bloodPressure.objects(for: diaType).first as? HKQuantitySample else {
                return nil
            }
            let systolic = sys.quantity.doubleValue(for: unit)
            let diastolic = dia.quantity.doubleValue(for: unit)
            return .bloodPressure(systolic: systolic, diastolic: diastolic, unit: unit, date: bloodPressure.endDate)
        }
    }

    func fetchLatestECG(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        let ecgType = HKObjectType.electrocardiogramType()
        let startDate = Date().addingTimeInterval(-lookback)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let queryLimit = limit ?? HKObjectQueryNoLimit

        let samples: [HKElectrocardiogram] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: ecgType,
                predicate: predicate,
                limit: queryLimit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                continuation.resume(returning: results as? [HKElectrocardiogram] ?? [])
            }
            self.healthStore.execute(query)
        }

        if samples.isEmpty {
            return []
        }

        return samples.map { ecg in
            let avgHR = ecg.averageHeartRate?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let sampling = ecg.samplingFrequency?.doubleValue(for: HKUnit.hertz())
            let duration = ecg.endDate.timeIntervalSince(ecg.startDate)

            return .ecg(
                classification: ecg.classification,
                averageBPM: avgHR,
                samplingHz: sampling,
                duration: duration,
                date: ecg.endDate
            )
        }
    }

    func fetchLatestRespiratoryRate(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            return [.unavailable("Respiratory Rate type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { sample in
            let value = sample.quantity.doubleValue(for: unit)
            return .respiratoryRate(breathsPerMin: value, date: sample.endDate)
        }
    }

    func fetchLatestRestingHeartRate(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return [.unavailable("Resting Heart Rate type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { sample in
            let bpm = sample.quantity.doubleValue(for: unit)
            return .restingHeartRate(bpm: bpm, date: sample.endDate)
        }
    }

    func fetchLatestOxygenSaturation(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            return [.unavailable("Oxygen Saturation type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        return samples.map { sample in
            // HealthKit stores SpO2 as a fraction 0.0 - 1.0; convert to percentage 0 - 100
            let fraction = sample.quantity.doubleValue(for: HKUnit.percent())
            let percent = fraction * 100.0
            return .oxygenSaturation(percent: percent, date: sample.endDate)
        }
    }

    func fetchLatestVO2Max(since lookback: TimeInterval, limit: Int?) async -> [HealthMetricValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            return [.unavailable("VO2 Max type unavailable")]
        }
        let samples = await quantitySamples(of: type, since: lookback, limit: limit)
        if samples.isEmpty {
            return []
        }
        let unit = HKUnit.literUnit(with: .milli)
            .unitDivided(by: HKUnit.gramUnit(with: .kilo))
            .unitDivided(by: HKUnit.minute())
        return samples.map { sample in
            // VO2Max is typically mL/(kg·min)
            let value = sample.quantity.doubleValue(for: unit)
            return .vo2Max(mlPerKgMin: value, date: sample.endDate)
        }
    }

    // MARK: - Series Fetching

    func fetchQuantitySeries(type: HKQuantityType, since lookback: TimeInterval) async -> [HKQuantitySample] {
        return await quantitySamples(of: type, since: lookback, limit: nil)
    }

    // MARK: - Helpers

    private func quantitySamples(of type: HKQuantityType, since lookback: TimeInterval, limit: Int?) async -> [HKQuantitySample] {
        let startDate = Date().addingTimeInterval(-lookback)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let queryLimit = limit ?? HKObjectQueryNoLimit

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: queryLimit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                continuation.resume(returning: results as? [HKQuantitySample] ?? [])
            }
            self.healthStore.execute(query)
        }
    }
}
