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

struct ECGVoltageSample: Equatable {
    let timeSinceSampleStart: TimeInterval
    let millivolts: Double
}

struct ECGWaveform: Equatable {
    static let appleWatchLead = "appleWatchSimilarToLeadI"

    let sourceSampleUUID: UUID?
    let lead: String
    let samplingFrequencyHz: Double
    let samples: [ECGVoltageSample]

    var duration: TimeInterval {
        samples.last?.timeSinceSampleStart ?? 0
    }

    static func synthetic(
        averageBPM: Double,
        duration: TimeInterval = 30,
        samplingFrequencyHz: Double = 512
    ) -> ECGWaveform {
        let safeBPM = max(averageBPM, 1)
        let sampleCount = max(Int(duration * samplingFrequencyHz), 1)
        let beatInterval = 60 / safeBPM
        let samples = (0..<sampleCount).map { index -> ECGVoltageSample in
            let time = Double(index) / samplingFrequencyHz
            let phase = time.truncatingRemainder(dividingBy: beatInterval)
            let value =
                gaussian(phase, center: beatInterval * 0.18, width: 0.035, amplitude: 0.12) +
                gaussian(phase, center: beatInterval * 0.34, width: 0.012, amplitude: -0.16) +
                gaussian(phase, center: beatInterval * 0.37, width: 0.010, amplitude: 1.05) +
                gaussian(phase, center: beatInterval * 0.40, width: 0.014, amplitude: -0.25) +
                gaussian(phase, center: beatInterval * 0.64, width: 0.070, amplitude: 0.28) +
                sin(time * .pi * 2 * 0.18) * 0.025
            return ECGVoltageSample(timeSinceSampleStart: time, millivolts: value)
        }
        return ECGWaveform(
            sourceSampleUUID: nil,
            lead: appleWatchLead,
            samplingFrequencyHz: samplingFrequencyHz,
            samples: samples
        )
    }

    private static func gaussian(
        _ value: Double,
        center: Double,
        width: Double,
        amplitude: Double
    ) -> Double {
        let distance = (value - center) / width
        return amplitude * exp(-0.5 * distance * distance)
    }
}

struct ECGReport: Equatable {
    static let formatVersion = "magicbox-ecg-pdf-v1"
    static let mimeType = "application/pdf"

    let pdfData: Data
    let sourceSampleUUID: UUID?
    let lead: String
    let format: String
    let mimeType: String

    init?(
        pdfData: Data,
        sourceSampleUUID: UUID?,
        lead: String = ECGWaveform.appleWatchLead,
        format: String = ECGReport.formatVersion,
        mimeType: String = ECGReport.mimeType
    ) {
        guard
            pdfData.starts(with: Data("%PDF-".utf8)),
            lead == ECGWaveform.appleWatchLead,
            format == ECGReport.formatVersion,
            mimeType == ECGReport.mimeType
        else {
            return nil
        }
        self.pdfData = pdfData
        self.sourceSampleUUID = sourceSampleUUID
        self.lead = lead
        self.format = format
        self.mimeType = mimeType
    }
}

struct ECGReportAttachment: Equatable {
    let attachmentID: String
    let fileName: String
    let encryptedFileKey: String
    let hashFileKey: String
    let sourceSampleUUID: UUID?
    let lead: String
    let format: String
    let mimeType: String

    init?(
        attachmentID: String,
        fileName: String,
        encryptedFileKey: String,
        hashFileKey: String,
        sourceSampleUUID: UUID?,
        lead: String = ECGWaveform.appleWatchLead,
        format: String = ECGReport.formatVersion,
        mimeType: String = ECGReport.mimeType
    ) {
        guard
            !attachmentID.isEmpty,
            !fileName.isEmpty,
            !encryptedFileKey.isEmpty,
            !hashFileKey.isEmpty,
            lead == ECGWaveform.appleWatchLead,
            format == ECGReport.formatVersion,
            mimeType == ECGReport.mimeType
        else {
            return nil
        }
        self.attachmentID = attachmentID
        self.fileName = fileName
        self.encryptedFileKey = encryptedFileKey
        self.hashFileKey = hashFileKey
        self.sourceSampleUUID = sourceSampleUUID
        self.lead = lead
        self.format = format
        self.mimeType = mimeType
    }
}
