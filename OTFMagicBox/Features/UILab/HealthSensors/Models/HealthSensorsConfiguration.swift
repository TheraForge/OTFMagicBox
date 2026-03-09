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
import OTFTemplateBox
import RawModel

@RawGenerable
struct HealthSensorsConfiguration: Codable {
    let version: String

    let title: OTFStringLocalized
    let menuSettings: OTFStringLocalized

    let menuMockData: OTFStringLocalized
    let menuResetMockSeed: OTFStringLocalized

    let statusNeedsPermission: OTFStringLocalized
    let statusAccessDenied: OTFStringLocalized
    let statusNoData: OTFStringLocalized
    let statusSampleBased: OTFStringLocalized
    let statusLive: OTFStringLocalized
    let statusMock: OTFStringLocalized
    let statusError: OTFStringLocalized

    let labelLastUpdated: OTFStringLocalized
    let labelDataSource: OTFStringLocalized
    let labelHowToUpdate: OTFStringLocalized
    let labelConnectivity: OTFStringLocalized

    let dataSourceHealth: OTFStringLocalized
    let dataSourceWatchLive: OTFStringLocalized
    let dataSourceMock: OTFStringLocalized

    let labelHealthAccessGranted: OTFStringLocalized
    let labelHealthAccessRequired: OTFStringLocalized

    let buttonGrantAccess: OTFStringLocalized
    let buttonOpenSettings: OTFStringLocalized
    let buttonOpenHealth: OTFStringLocalized
    let buttonStartLiveMeasurement: OTFStringLocalized
    let buttonSendOutcome: OTFStringLocalized
    let labelOutcomeFreshnessHint: OTFStringLocalized

    let connectivityConnected: OTFStringLocalized
    let connectivityDisconnected: OTFStringLocalized

    // Secondary Metric Labels
    let labelAverage: OTFStringLocalized
    let labelMin: OTFStringLocalized
    let labelMax: OTFStringLocalized
    let labelSystolic: OTFStringLocalized
    let labelDiastolic: OTFStringLocalized
    let emptyStateTitle: OTFStringLocalized

    // Card Titles
    let cardTitleHeartRate: OTFStringLocalized
    let cardTitleBloodGlucose: OTFStringLocalized
    let cardTitleBloodPressure: OTFStringLocalized
    let cardTitleECG: OTFStringLocalized
    let cardTitleRespiratoryRate: OTFStringLocalized
    let cardTitleRestingHeartRate: OTFStringLocalized
    let cardTitleOxygenSaturation: OTFStringLocalized
    let cardTitleVO2Max: OTFStringLocalized

    // Card Symbols
    let symbolHeartRate: OTFStringLocalized
    let symbolBloodGlucose: OTFStringLocalized
    let symbolBloodPressure: OTFStringLocalized
    let symbolECG: OTFStringLocalized
    let symbolRespiratoryRate: OTFStringLocalized
    let symbolRestingHeartRate: OTFStringLocalized
    let symbolOxygenSaturation: OTFStringLocalized
    let symbolVO2Max: OTFStringLocalized

    // Card Subtitles
    let cardSubtitleHeartRate: OTFStringLocalized
    let cardSubtitleBloodGlucose: OTFStringLocalized
    let cardSubtitleBloodPressure: OTFStringLocalized
    let cardSubtitleECG: OTFStringLocalized
    let cardSubtitleRespiratoryRate: OTFStringLocalized
    let cardSubtitleRestingHeartRate: OTFStringLocalized
    let cardSubtitleOxygenSaturation: OTFStringLocalized
    let cardSubtitleVO2Max: OTFStringLocalized

    // Units
    let unitBPM: OTFStringLocalized
    let unitMgDL: OTFStringLocalized
    let unitMmHg: OTFStringLocalized
    let unitRecords: OTFStringLocalized
    let unitBreathsPerMin: OTFStringLocalized
    let unitPercent: OTFStringLocalized
    let unitVO2Max: OTFStringLocalized

    // ECG Classification Labels
    let ecgClassificationDefault: OTFStringLocalized
    let ecgClassificationSinusRhythm: OTFStringLocalized
    let ecgClassificationAtrialFibrillation: OTFStringLocalized
    let ecgClassificationLowHeartRate: OTFStringLocalized
    let ecgClassificationHighHeartRate: OTFStringLocalized
    let ecgClassificationInconclusive: OTFStringLocalized
    let ecgClassificationUnrecognized: OTFStringLocalized

    // Empty State Messages
    let emptyMessageHeartRate: OTFStringLocalized
    let emptyMessageBloodGlucose: OTFStringLocalized
    let emptyMessageBloodPressure: OTFStringLocalized
    let emptyMessageECG: OTFStringLocalized
    let emptyMessageRespiratoryRate: OTFStringLocalized
    let emptyMessageRestingHeartRate: OTFStringLocalized
    let emptyMessageOxygenSaturation: OTFStringLocalized
    let emptyMessageVO2Max: OTFStringLocalized

    // Guidance Steps
    let guidanceHeartRateStep1: OTFStringLocalized
    let guidanceHeartRateStep2: OTFStringLocalized
    let guidanceHeartRateStep3: OTFStringLocalized

    let guidanceBloodGlucoseStep1: OTFStringLocalized
    let guidanceBloodGlucoseStep2: OTFStringLocalized
    let guidanceBloodGlucoseStep3: OTFStringLocalized

    let guidanceBloodPressureStep1: OTFStringLocalized
    let guidanceBloodPressureStep2: OTFStringLocalized
    let guidanceBloodPressureStep3: OTFStringLocalized

    let guidanceECGStep1: OTFStringLocalized
    let guidanceECGStep2: OTFStringLocalized
    let guidanceECGStep3: OTFStringLocalized

    let guidanceRespiratoryRateStep1: OTFStringLocalized
    let guidanceRespiratoryRateStep2: OTFStringLocalized
    let guidanceRespiratoryRateStep3: OTFStringLocalized

    let guidanceRestingHeartRateStep1: OTFStringLocalized
    let guidanceRestingHeartRateStep2: OTFStringLocalized
    let guidanceRestingHeartRateStep3: OTFStringLocalized

    let guidanceOxygenSaturationStep1: OTFStringLocalized
    let guidanceOxygenSaturationStep2: OTFStringLocalized
    let guidanceOxygenSaturationStep3: OTFStringLocalized

    let guidanceVO2MaxStep1: OTFStringLocalized
    let guidanceVO2MaxStep2: OTFStringLocalized
    let guidanceVO2MaxStep3: OTFStringLocalized
}

extension HealthSensorsConfiguration: OTFVersionedDecodable {
    typealias Raw = RawHealthSensorsConfiguration

    static let fallback = HealthSensorsConfiguration(
        version: "2.0.0",
        title: "Health Sensors",
        menuSettings: "Settings",
        menuMockData: "Mock Data",
        menuResetMockSeed: "Reset Mock Seed",
        statusNeedsPermission: "Needs Permission",
        statusAccessDenied: "Access Denied",
        statusNoData: "No Data",
        statusSampleBased: "Sample-based",
        statusLive: "Live",
        statusMock: "Mock",
        statusError: "Error",
        labelLastUpdated: "Last updated",
        labelDataSource: "Source",
        labelHowToUpdate: "How to update this data",
        labelConnectivity: "Watch Connection",
        dataSourceHealth: "Health",
        dataSourceWatchLive: "Watch Live",
        dataSourceMock: "Mock",
        labelHealthAccessGranted: "Health access granted",
        labelHealthAccessRequired: "Health access needed",
        buttonGrantAccess: "Grant Health Access",
        buttonOpenSettings: "Open Settings",
        buttonOpenHealth: "Open Health",
        buttonStartLiveMeasurement: "Start Live Measurement on Watch",
        buttonSendOutcome: "Send Outcome",
        labelOutcomeFreshnessHint: "Take a new measurement. Only readings from the last 15 minutes can be sent.",
        connectivityConnected: "Connected",
        connectivityDisconnected: "Not Connected",
        // Secondary Metric Labels
        labelAverage: "Avg",
        labelMin: "Min",
        labelMax: "Max",
        labelSystolic: "Systolic",
        labelDiastolic: "Diastolic",
        emptyStateTitle: "No Data Available",
        // Card Titles
        cardTitleHeartRate: "Heart Rate",
        cardTitleBloodGlucose: "Blood Glucose",
        cardTitleBloodPressure: "Blood Pressure",
        cardTitleECG: "Electrocardiogram",
        cardTitleRespiratoryRate: "Respiratory Rate",
        cardTitleRestingHeartRate: "Resting Heart Rate",
        cardTitleOxygenSaturation: "Oxygen Saturation",
        cardTitleVO2Max: "VO₂ Max",
        // Card Symbols
        symbolHeartRate: "heart.fill",
        symbolBloodGlucose: "drop.fill",
        symbolBloodPressure: "waveform.path.ecg",
        symbolECG: "heart.text.square.fill",
        symbolRespiratoryRate: "lungs.fill",
        symbolRestingHeartRate: "heart.fill",
        symbolOxygenSaturation: "o.circle.fill",
        symbolVO2Max: "figure.run",
        // Card Subtitles
        cardSubtitleHeartRate: "Beats per minute",
        cardSubtitleBloodGlucose: "Sugar in blood",
        cardSubtitleBloodPressure: "Systolic & Diastolic",
        cardSubtitleECG: "Electrical heart activity",
        cardSubtitleRespiratoryRate: "Breaths per minute",
        cardSubtitleRestingHeartRate: "Resting beats per minute",
        cardSubtitleOxygenSaturation: "Oxygen level in blood",
        cardSubtitleVO2Max: "Max oxygen consumption",
        // Units
        unitBPM: "BPM",
        unitMgDL: "mg/dL",
        unitMmHg: "mmHg",
        unitRecords: "Records",
        unitBreathsPerMin: "br/min",
        unitPercent: "%",
        unitVO2Max: "mL/(kg·min)",
        // ECG Classification Labels
        ecgClassificationDefault: "ECG",
        ecgClassificationSinusRhythm: "Sinus Rhythm",
        ecgClassificationAtrialFibrillation: "Atrial Fibrillation",
        ecgClassificationLowHeartRate: "Low Heart Rate",
        ecgClassificationHighHeartRate: "High Heart Rate",
        ecgClassificationInconclusive: "Inconclusive",
        ecgClassificationUnrecognized: "Unrecognized",
        // Empty State Messages
        emptyMessageHeartRate: "No heart rate data found in HealthKit.",
        emptyMessageBloodGlucose: "No blood glucose data found in HealthKit.",
        emptyMessageBloodPressure: "No blood pressure data found in HealthKit.",
        emptyMessageECG: "No ECG records found on this device.",
        emptyMessageRespiratoryRate: "No respiratory rate data found.",
        emptyMessageRestingHeartRate: "No resting heart rate data found.",
        emptyMessageOxygenSaturation: "No oxygen saturation data found.",
        emptyMessageVO2Max: "No VO₂ Max data found.",
        // Guidance Steps
        guidanceHeartRateStep1: "Make sure your Apple Watch is paired and unlocked.",
        guidanceHeartRateStep2: "Open the Heart Rate app on your Apple Watch.",
        guidanceHeartRateStep3: "Wait for a measurement to complete.",
        guidanceBloodGlucoseStep1: "Data is typically added by a connected CGM or manual entry.",
        guidanceBloodGlucoseStep2: "Open the Health app to manually add a data point.",
        guidanceBloodGlucoseStep3: "Or sync with your glucose monitoring device.",
        guidanceBloodPressureStep1: "Use a connected blood pressure cuff.",
        guidanceBloodPressureStep2: "Or manually enter a reading in the Health app.",
        guidanceBloodPressureStep3: "Ensure both Systolic and Diastolic values are recorded.",
        guidanceECGStep1: "Open the ECG app on your Apple Watch.",
        guidanceECGStep2: "Hold your finger on the Digital Crown.",
        guidanceECGStep3: "Wait 30 seconds for the recording to finish.",
        guidanceRespiratoryRateStep1: "Wear your Apple Watch during sleep.",
        guidanceRespiratoryRateStep2: "Or use a supported third-party device.",
        guidanceRespiratoryRateStep3: "Check 'Respiratory Rate' in the Health app.",
        guidanceRestingHeartRateStep1: "Wear your Apple Watch consistently.",
        guidanceRestingHeartRateStep2: "Resting heart rate is calculated when you differ from active states.",
        guidanceRestingHeartRateStep3: "Check 'Resting Heart Rate' in the Health app.",
        guidanceOxygenSaturationStep1: "Open the Blood Oxygen app on your Apple Watch.",
        guidanceOxygenSaturationStep2: "Keep your wrist still during the 15-second measurement.",
        guidanceOxygenSaturationStep3: "Ensure the band is snug but comfortable.",
        guidanceVO2MaxStep1: "Record an Outdoor Walk, Run, or Hiking workout.",
        guidanceVO2MaxStep2: "Sustain efforts for at least 20 minutes.",
        guidanceVO2MaxStep3: "Check 'Cardio Fitness' in the Health app."
    )

    init(from raw: RawHealthSensorsConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.title = raw.title ?? fallback.title
        self.menuSettings = raw.menuSettings ?? fallback.menuSettings
        self.menuMockData = raw.menuMockData ?? fallback.menuMockData
        self.menuResetMockSeed = raw.menuResetMockSeed ?? fallback.menuResetMockSeed
        self.statusNeedsPermission = raw.statusNeedsPermission ?? fallback.statusNeedsPermission
        self.statusAccessDenied = raw.statusAccessDenied ?? fallback.statusAccessDenied
        self.statusNoData = raw.statusNoData ?? fallback.statusNoData
        self.statusSampleBased = raw.statusSampleBased ?? fallback.statusSampleBased
        self.statusLive = raw.statusLive ?? fallback.statusLive
        self.statusMock = raw.statusMock ?? fallback.statusMock
        self.statusError = raw.statusError ?? fallback.statusError
        self.labelLastUpdated = raw.labelLastUpdated ?? fallback.labelLastUpdated
        self.labelDataSource = raw.labelDataSource ?? fallback.labelDataSource
        self.labelHowToUpdate = raw.labelHowToUpdate ?? fallback.labelHowToUpdate
        self.labelConnectivity = raw.labelConnectivity ?? fallback.labelConnectivity
        self.dataSourceHealth = raw.dataSourceHealth ?? fallback.dataSourceHealth
        self.dataSourceWatchLive = raw.dataSourceWatchLive ?? fallback.dataSourceWatchLive
        self.dataSourceMock = raw.dataSourceMock ?? fallback.dataSourceMock
        self.labelHealthAccessGranted = raw.labelHealthAccessGranted ?? fallback.labelHealthAccessGranted
        self.labelHealthAccessRequired = raw.labelHealthAccessRequired ?? fallback.labelHealthAccessRequired
        self.buttonGrantAccess = raw.buttonGrantAccess ?? fallback.buttonGrantAccess
        self.buttonOpenSettings = raw.buttonOpenSettings ?? fallback.buttonOpenSettings
        self.buttonOpenHealth = raw.buttonOpenHealth ?? fallback.buttonOpenHealth
        self.buttonStartLiveMeasurement = raw.buttonStartLiveMeasurement ?? fallback.buttonStartLiveMeasurement
        self.buttonSendOutcome = raw.buttonSendOutcome ?? fallback.buttonSendOutcome
        self.labelOutcomeFreshnessHint = raw.labelOutcomeFreshnessHint ?? fallback.labelOutcomeFreshnessHint
        self.connectivityConnected = raw.connectivityConnected ?? fallback.connectivityConnected
        self.connectivityDisconnected = raw.connectivityDisconnected ?? fallback.connectivityDisconnected
        // Secondary Metric Labels
        self.labelAverage = raw.labelAverage ?? fallback.labelAverage
        self.labelMin = raw.labelMin ?? fallback.labelMin
        self.labelMax = raw.labelMax ?? fallback.labelMax
        self.labelSystolic = raw.labelSystolic ?? fallback.labelSystolic
        self.labelDiastolic = raw.labelDiastolic ?? fallback.labelDiastolic
        self.emptyStateTitle = raw.emptyStateTitle ?? fallback.emptyStateTitle
        // Card Titles
        self.cardTitleHeartRate = raw.cardTitleHeartRate ?? fallback.cardTitleHeartRate
        self.cardTitleBloodGlucose = raw.cardTitleBloodGlucose ?? fallback.cardTitleBloodGlucose
        self.cardTitleBloodPressure = raw.cardTitleBloodPressure ?? fallback.cardTitleBloodPressure
        self.cardTitleECG = raw.cardTitleECG ?? fallback.cardTitleECG
        self.cardTitleRespiratoryRate = raw.cardTitleRespiratoryRate ?? fallback.cardTitleRespiratoryRate
        self.cardTitleRestingHeartRate = raw.cardTitleRestingHeartRate ?? fallback.cardTitleRestingHeartRate
        self.cardTitleOxygenSaturation = raw.cardTitleOxygenSaturation ?? fallback.cardTitleOxygenSaturation
        self.cardTitleVO2Max = raw.cardTitleVO2Max ?? fallback.cardTitleVO2Max
        // Card Symbols
        self.symbolHeartRate = raw.symbolHeartRate ?? fallback.symbolHeartRate
        self.symbolBloodGlucose = raw.symbolBloodGlucose ?? fallback.symbolBloodGlucose
        self.symbolBloodPressure = raw.symbolBloodPressure ?? fallback.symbolBloodPressure
        self.symbolECG = raw.symbolECG ?? fallback.symbolECG
        self.symbolRespiratoryRate = raw.symbolRespiratoryRate ?? fallback.symbolRespiratoryRate
        self.symbolRestingHeartRate = raw.symbolRestingHeartRate ?? fallback.symbolRestingHeartRate
        self.symbolOxygenSaturation = raw.symbolOxygenSaturation ?? fallback.symbolOxygenSaturation
        self.symbolVO2Max = raw.symbolVO2Max ?? fallback.symbolVO2Max
        // Card Subtitles
        self.cardSubtitleHeartRate = raw.cardSubtitleHeartRate ?? fallback.cardSubtitleHeartRate
        self.cardSubtitleBloodGlucose = raw.cardSubtitleBloodGlucose ?? fallback.cardSubtitleBloodGlucose
        self.cardSubtitleBloodPressure = raw.cardSubtitleBloodPressure ?? fallback.cardSubtitleBloodPressure
        self.cardSubtitleECG = raw.cardSubtitleECG ?? fallback.cardSubtitleECG
        self.cardSubtitleRespiratoryRate = raw.cardSubtitleRespiratoryRate ?? fallback.cardSubtitleRespiratoryRate
        self.cardSubtitleRestingHeartRate = raw.cardSubtitleRestingHeartRate ?? fallback.cardSubtitleRestingHeartRate
        self.cardSubtitleOxygenSaturation = raw.cardSubtitleOxygenSaturation ?? fallback.cardSubtitleOxygenSaturation
        self.cardSubtitleVO2Max = raw.cardSubtitleVO2Max ?? fallback.cardSubtitleVO2Max
        // Units
        self.unitBPM = raw.unitBPM ?? fallback.unitBPM
        self.unitMgDL = raw.unitMgDL ?? fallback.unitMgDL
        self.unitMmHg = raw.unitMmHg ?? fallback.unitMmHg
        self.unitRecords = raw.unitRecords ?? fallback.unitRecords
        self.unitBreathsPerMin = raw.unitBreathsPerMin ?? fallback.unitBreathsPerMin
        self.unitPercent = raw.unitPercent ?? fallback.unitPercent
        self.unitVO2Max = raw.unitVO2Max ?? fallback.unitVO2Max
        // ECG Classification Labels
        self.ecgClassificationDefault = raw.ecgClassificationDefault ?? fallback.ecgClassificationDefault
        self.ecgClassificationSinusRhythm = raw.ecgClassificationSinusRhythm ?? fallback.ecgClassificationSinusRhythm
        self.ecgClassificationAtrialFibrillation = raw.ecgClassificationAtrialFibrillation ?? fallback.ecgClassificationAtrialFibrillation
        self.ecgClassificationLowHeartRate = raw.ecgClassificationLowHeartRate ?? fallback.ecgClassificationLowHeartRate
        self.ecgClassificationHighHeartRate = raw.ecgClassificationHighHeartRate ?? fallback.ecgClassificationHighHeartRate
        self.ecgClassificationInconclusive = raw.ecgClassificationInconclusive ?? fallback.ecgClassificationInconclusive
        self.ecgClassificationUnrecognized = raw.ecgClassificationUnrecognized ?? fallback.ecgClassificationUnrecognized

        // Empty State Messages
        self.emptyMessageHeartRate = raw.emptyMessageHeartRate ?? fallback.emptyMessageHeartRate
        self.emptyMessageBloodGlucose = raw.emptyMessageBloodGlucose ?? fallback.emptyMessageBloodGlucose
        self.emptyMessageBloodPressure = raw.emptyMessageBloodPressure ?? fallback.emptyMessageBloodPressure
        self.emptyMessageECG = raw.emptyMessageECG ?? fallback.emptyMessageECG
        self.emptyMessageRespiratoryRate = raw.emptyMessageRespiratoryRate ?? fallback.emptyMessageRespiratoryRate
        self.emptyMessageRestingHeartRate = raw.emptyMessageRestingHeartRate ?? fallback.emptyMessageRestingHeartRate
        self.emptyMessageOxygenSaturation = raw.emptyMessageOxygenSaturation ?? fallback.emptyMessageOxygenSaturation
        self.emptyMessageVO2Max = raw.emptyMessageVO2Max ?? fallback.emptyMessageVO2Max

        // Guidance Steps
        self.guidanceHeartRateStep1 = raw.guidanceHeartRateStep1 ?? fallback.guidanceHeartRateStep1
        self.guidanceHeartRateStep2 = raw.guidanceHeartRateStep2 ?? fallback.guidanceHeartRateStep2
        self.guidanceHeartRateStep3 = raw.guidanceHeartRateStep3 ?? fallback.guidanceHeartRateStep3

        self.guidanceBloodGlucoseStep1 = raw.guidanceBloodGlucoseStep1 ?? fallback.guidanceBloodGlucoseStep1
        self.guidanceBloodGlucoseStep2 = raw.guidanceBloodGlucoseStep2 ?? fallback.guidanceBloodGlucoseStep2
        self.guidanceBloodGlucoseStep3 = raw.guidanceBloodGlucoseStep3 ?? fallback.guidanceBloodGlucoseStep3

        self.guidanceBloodPressureStep1 = raw.guidanceBloodPressureStep1 ?? fallback.guidanceBloodPressureStep1
        self.guidanceBloodPressureStep2 = raw.guidanceBloodPressureStep2 ?? fallback.guidanceBloodPressureStep2
        self.guidanceBloodPressureStep3 = raw.guidanceBloodPressureStep3 ?? fallback.guidanceBloodPressureStep3

        self.guidanceECGStep1 = raw.guidanceECGStep1 ?? fallback.guidanceECGStep1
        self.guidanceECGStep2 = raw.guidanceECGStep2 ?? fallback.guidanceECGStep2
        self.guidanceECGStep3 = raw.guidanceECGStep3 ?? fallback.guidanceECGStep3

        self.guidanceRespiratoryRateStep1 = raw.guidanceRespiratoryRateStep1 ?? fallback.guidanceRespiratoryRateStep1
        self.guidanceRespiratoryRateStep2 = raw.guidanceRespiratoryRateStep2 ?? fallback.guidanceRespiratoryRateStep2
        self.guidanceRespiratoryRateStep3 = raw.guidanceRespiratoryRateStep3 ?? fallback.guidanceRespiratoryRateStep3

        self.guidanceRestingHeartRateStep1 = raw.guidanceRestingHeartRateStep1 ?? fallback.guidanceRestingHeartRateStep1
        self.guidanceRestingHeartRateStep2 = raw.guidanceRestingHeartRateStep2 ?? fallback.guidanceRestingHeartRateStep2
        self.guidanceRestingHeartRateStep3 = raw.guidanceRestingHeartRateStep3 ?? fallback.guidanceRestingHeartRateStep3

        self.guidanceOxygenSaturationStep1 = raw.guidanceOxygenSaturationStep1 ?? fallback.guidanceOxygenSaturationStep1
        self.guidanceOxygenSaturationStep2 = raw.guidanceOxygenSaturationStep2 ?? fallback.guidanceOxygenSaturationStep2
        self.guidanceOxygenSaturationStep3 = raw.guidanceOxygenSaturationStep3 ?? fallback.guidanceOxygenSaturationStep3

        self.guidanceVO2MaxStep1 = raw.guidanceVO2MaxStep1 ?? fallback.guidanceVO2MaxStep1
        self.guidanceVO2MaxStep2 = raw.guidanceVO2MaxStep2 ?? fallback.guidanceVO2MaxStep2
        self.guidanceVO2MaxStep3 = raw.guidanceVO2MaxStep3 ?? fallback.guidanceVO2MaxStep3
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawHealthSensorsConfiguration) throws -> HealthSensorsConfiguration {
        HealthSensorsConfiguration(from: raw)
    }
}
