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
struct SensorTaskConfiguration: Codable {
    let version: String
    let sentLabel: OTFStringLocalized
    let pendingLabel: OTFStringLocalized
    let sentValueFormat: OTFStringLocalized
    let sendResultLabel: OTFStringLocalized
    let reviewLabel: OTFStringLocalized
    let mockSensorTaskTitle: OTFStringLocalized
    let taskTitleHeartRate: OTFStringLocalized
    let taskTitleBloodGlucose: OTFStringLocalized
    let taskTitleBloodPressure: OTFStringLocalized
    let taskTitleECG: OTFStringLocalized
    let taskTitleRespiratoryRate: OTFStringLocalized
    let taskTitleRestingHeartRate: OTFStringLocalized
    let taskTitleOxygenSaturation: OTFStringLocalized
    let taskTitleVO2Max: OTFStringLocalized
    let taskInstructionsHeartRate: OTFStringLocalized
    let taskInstructionsBloodGlucose: OTFStringLocalized
    let taskInstructionsBloodPressure: OTFStringLocalized
    let taskInstructionsECG: OTFStringLocalized
    let taskInstructionsRespiratoryRate: OTFStringLocalized
    let taskInstructionsRestingHeartRate: OTFStringLocalized
    let taskInstructionsOxygenSaturation: OTFStringLocalized
    let taskInstructionsVO2Max: OTFStringLocalized
}

extension SensorTaskConfiguration: OTFVersionedDecodable {
    typealias Raw = RawSensorTaskConfiguration

    static let fallback = SensorTaskConfiguration(
        version: "2.0.0",
        sentLabel: "Heart rate sent",
        pendingLabel: "Send your heart rate",
        sentValueFormat: "Sent %@",
        sendResultLabel: "Send Result",
        reviewLabel: "Review",
        mockSensorTaskTitle: "Mock Sensor task",
        taskTitleHeartRate: "Send your Heart Rate",
        taskTitleBloodGlucose: "Send your Blood Glucose",
        taskTitleBloodPressure: "Send your Blood Pressure",
        taskTitleECG: "Send your ECG",
        taskTitleRespiratoryRate: "Send your Respiratory Rate",
        taskTitleRestingHeartRate: "Send your Resting Heart Rate",
        taskTitleOxygenSaturation: "Send your Oxygen Saturation",
        taskTitleVO2Max: "Send your VO2 Max",
        taskInstructionsHeartRate: "Tap to review and send your heart rate.",
        taskInstructionsBloodGlucose: "Tap to review and send your blood glucose.",
        taskInstructionsBloodPressure: "Tap to review and send your blood pressure.",
        taskInstructionsECG: "Tap to review and send your ECG.",
        taskInstructionsRespiratoryRate: "Tap to review and send your respiratory rate.",
        taskInstructionsRestingHeartRate: "Tap to review and send your resting heart rate.",
        taskInstructionsOxygenSaturation: "Tap to review and send your oxygen saturation.",
        taskInstructionsVO2Max: "Tap to review and send your VO2 max."
    )

    init(from raw: RawSensorTaskConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.sentLabel = raw.sentLabel ?? fallback.sentLabel
        self.pendingLabel = raw.pendingLabel ?? fallback.pendingLabel
        self.sentValueFormat = raw.sentValueFormat ?? fallback.sentValueFormat
        self.sendResultLabel = raw.sendResultLabel ?? fallback.sendResultLabel
        self.reviewLabel = raw.reviewLabel ?? fallback.reviewLabel
        self.mockSensorTaskTitle = raw.mockSensorTaskTitle ?? fallback.mockSensorTaskTitle
        self.taskTitleHeartRate = raw.taskTitleHeartRate ?? fallback.taskTitleHeartRate
        self.taskTitleBloodGlucose = raw.taskTitleBloodGlucose ?? fallback.taskTitleBloodGlucose
        self.taskTitleBloodPressure = raw.taskTitleBloodPressure ?? fallback.taskTitleBloodPressure
        self.taskTitleECG = raw.taskTitleECG ?? fallback.taskTitleECG
        self.taskTitleRespiratoryRate = raw.taskTitleRespiratoryRate ?? fallback.taskTitleRespiratoryRate
        self.taskTitleRestingHeartRate = raw.taskTitleRestingHeartRate ?? fallback.taskTitleRestingHeartRate
        self.taskTitleOxygenSaturation = raw.taskTitleOxygenSaturation ?? fallback.taskTitleOxygenSaturation
        self.taskTitleVO2Max = raw.taskTitleVO2Max ?? fallback.taskTitleVO2Max
        self.taskInstructionsHeartRate = raw.taskInstructionsHeartRate ?? fallback.taskInstructionsHeartRate
        self.taskInstructionsBloodGlucose = raw.taskInstructionsBloodGlucose ?? fallback.taskInstructionsBloodGlucose
        self.taskInstructionsBloodPressure = raw.taskInstructionsBloodPressure ?? fallback.taskInstructionsBloodPressure
        self.taskInstructionsECG = raw.taskInstructionsECG ?? fallback.taskInstructionsECG
        self.taskInstructionsRespiratoryRate = raw.taskInstructionsRespiratoryRate ?? fallback.taskInstructionsRespiratoryRate
        self.taskInstructionsRestingHeartRate = raw.taskInstructionsRestingHeartRate ?? fallback.taskInstructionsRestingHeartRate
        self.taskInstructionsOxygenSaturation = raw.taskInstructionsOxygenSaturation ?? fallback.taskInstructionsOxygenSaturation
        self.taskInstructionsVO2Max = raw.taskInstructionsVO2Max ?? fallback.taskInstructionsVO2Max
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawSensorTaskConfiguration) throws -> SensorTaskConfiguration {
        SensorTaskConfiguration(from: raw)
    }
}
