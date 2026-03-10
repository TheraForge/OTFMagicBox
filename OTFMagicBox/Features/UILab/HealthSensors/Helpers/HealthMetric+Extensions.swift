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

extension HealthKitDataManager.HealthMetric {
    
    enum ChartType {
        case line
        case bar
        case scatter
    }
    
    var chartType: ChartType {
        switch self {
        case .heartRate, .restingHeartRate, .oxygenSaturation, .bloodPressure, .respiratoryRate: .line
        case .ecg, .bloodGlucose: .scatter
        case .vo2Max: .bar
        }
    }
}

extension HealthKitDataManager.HealthMetric: Identifiable {
    public var id: String {
        switch self {
        case .heartRate: "heartRate"
        case .bloodGlucose: "bloodGlucose"
        case .bloodPressure: "bloodPressure"
        case .ecg: "ecg"
        case .respiratoryRate: "respiratoryRate"
        case .restingHeartRate: "restingHeartRate"
        case .oxygenSaturation: "oxygenSaturation"
        case .vo2Max: "vo2Max"
        }
    }
    
    // MARK: - Localized Accessors
    
    /// Returns the localized display title for this metric
    func displayTitle(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .heartRate: config.cardTitleHeartRate.localized
        case .bloodGlucose: config.cardTitleBloodGlucose.localized
        case .bloodPressure: config.cardTitleBloodPressure.localized
        case .ecg: config.cardTitleECG.localized
        case .respiratoryRate: config.cardTitleRespiratoryRate.localized
        case .restingHeartRate: config.cardTitleRestingHeartRate.localized
        case .oxygenSaturation: config.cardTitleOxygenSaturation.localized
        case .vo2Max: config.cardTitleVO2Max.localized
        }
    }
    
    /// Returns the localized display subtitle for this metric
    func displaySubtitle(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .heartRate: config.cardSubtitleHeartRate.localized
        case .bloodGlucose: config.cardSubtitleBloodGlucose.localized
        case .bloodPressure: config.cardSubtitleBloodPressure.localized
        case .ecg: config.cardSubtitleECG.localized
        case .respiratoryRate: config.cardSubtitleRespiratoryRate.localized
        case .restingHeartRate: config.cardSubtitleRestingHeartRate.localized
        case .oxygenSaturation: config.cardSubtitleOxygenSaturation.localized
        case .vo2Max: config.cardSubtitleVO2Max.localized
        }
    }

    /// Returns the symbol name for this metric
    func displaySymbol(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .heartRate: config.symbolHeartRate.localized
        case .bloodGlucose: config.symbolBloodGlucose.localized
        case .bloodPressure: config.symbolBloodPressure.localized
        case .ecg: config.symbolECG.localized
        case .respiratoryRate: config.symbolRespiratoryRate.localized
        case .restingHeartRate: config.symbolRestingHeartRate.localized
        case .oxygenSaturation: config.symbolOxygenSaturation.localized
        case .vo2Max: config.symbolVO2Max.localized
        }
    }
    
    /// Returns the localized unit for this metric
    func displayUnit(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .heartRate: config.unitBPM.localized
        case .bloodGlucose: config.unitMgDL.localized
        case .bloodPressure: config.unitMmHg.localized
        case .ecg: config.unitRecords.localized
        case .respiratoryRate: config.unitBreathsPerMin.localized
        case .restingHeartRate: config.unitBPM.localized
        case .oxygenSaturation: config.unitPercent.localized
        case .vo2Max: config.unitVO2Max.localized
        }
    }
    
    /// Returns the localized empty state title
    func displayEmptyStateTitle(config: HealthSensorsConfiguration) -> String {
        return config.emptyStateTitle.localized
    }
    
    /// Returns the localized empty state message for this metric
    func displayEmptyStateMessage(config: HealthSensorsConfiguration) -> String {
        switch self {
        case .heartRate: config.emptyMessageHeartRate.localized
        case .bloodGlucose: config.emptyMessageBloodGlucose.localized
        case .bloodPressure: config.emptyMessageBloodPressure.localized
        case .ecg: config.emptyMessageECG.localized
        case .respiratoryRate: config.emptyMessageRespiratoryRate.localized
        case .restingHeartRate: config.emptyMessageRestingHeartRate.localized
        case .oxygenSaturation: config.emptyMessageOxygenSaturation.localized
        case .vo2Max: config.emptyMessageVO2Max.localized
        }
    }
    
    /// Returns the localized guidance steps for this metric
    func displayGuidanceSteps(config: HealthSensorsConfiguration) -> [String] {
        switch self {
        case .heartRate:
            [
                config.guidanceHeartRateStep1.localized,
                config.guidanceHeartRateStep2.localized,
                config.guidanceHeartRateStep3.localized
            ]
        case .bloodGlucose:
            [
                config.guidanceBloodGlucoseStep1.localized,
                config.guidanceBloodGlucoseStep2.localized,
                config.guidanceBloodGlucoseStep3.localized
            ]
        case .bloodPressure:
            [
                config.guidanceBloodPressureStep1.localized,
                config.guidanceBloodPressureStep2.localized,
                config.guidanceBloodPressureStep3.localized
            ]
        case .ecg:
            [
                config.guidanceECGStep1.localized,
                config.guidanceECGStep2.localized,
                config.guidanceECGStep3.localized
            ]
        case .respiratoryRate:
            [
                config.guidanceRespiratoryRateStep1.localized,
                config.guidanceRespiratoryRateStep2.localized,
                config.guidanceRespiratoryRateStep3.localized
            ]
        case .restingHeartRate:
            [
                config.guidanceRestingHeartRateStep1.localized,
                config.guidanceRestingHeartRateStep2.localized,
                config.guidanceRestingHeartRateStep3.localized
            ]
        case .oxygenSaturation:
            [
                config.guidanceOxygenSaturationStep1.localized,
                config.guidanceOxygenSaturationStep2.localized,
                config.guidanceOxygenSaturationStep3.localized
            ]
        case .vo2Max:
            [
                config.guidanceVO2MaxStep1.localized,
                config.guidanceVO2MaxStep2.localized,
                config.guidanceVO2MaxStep3.localized
            ]
        }
    }
}

// MARK: - HealthMetricValue Extensions

extension HealthKitDataManager.HealthMetricValue {
    
    /// Returns the primary display value for this metric.
    /// For composite metrics like blood pressure, returns the systolic value.
    var displayValue: Double {
        switch self {
        case .heartRate(let bpm, _):
            return bpm
        case .bloodGlucose(let mg, _):
            return mg
        case .bloodPressure(let sys, _, _, _):
            return sys
        case .ecg(_, let avg, _, _, _):
            return avg ?? 0
        case .respiratoryRate(let val, _):
            return val
        case .restingHeartRate(let bpm, _):
            return bpm
        case .oxygenSaturation(let val, _):
            return val
        case .vo2Max(let val, _):
            return val
        case .unavailable:
            return 0
        }
    }
}
