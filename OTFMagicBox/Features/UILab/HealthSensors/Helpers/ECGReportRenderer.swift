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

import HealthKit
import UIKit

protocol ECGReportRendering {
    func makeReport(
        reading: HealthKitDataManager.HealthMetricValue,
        waveform: ECGWaveform
    ) -> ECGReport?
}

struct ECGReportRenderer: ECGReportRendering {
    private enum FileConstants {
        static let pageSize = CGSize(width: 792, height: 612)
        static let pageMargin: CGFloat = 36
        static let millimetersPerInch: CGFloat = 25.4
        static let pointsPerInch: CGFloat = 72
        static let secondsPerStrip: TimeInterval = 10
        static let stripCount = 3
        static let stripHeight: CGFloat = 132
        static let stripSpacing: CGFloat = 12
        static let waveformWidth: CGFloat = 1.1
    }

    func makeReport(
        reading: HealthKitDataManager.HealthMetricValue,
        waveform: ECGWaveform
    ) -> ECGReport? {
        guard
            case .ecg(let classification, let averageBPM, _, _, let date) = reading,
            waveform.samples.count > 1,
            waveform.samples.allSatisfy({
                $0.timeSinceSampleStart.isFinite &&
                    $0.timeSinceSampleStart >= 0 &&
                    $0.millivolts.isFinite
            })
        else {
            return nil
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: FileConstants.pageSize))
        let data = renderer.pdfData { context in
            context.beginPage()
            drawHeader(
                classification: classification,
                averageBPM: averageBPM,
                date: date,
                in: context.cgContext
            )
            drawWaveform(waveform, in: context.cgContext)
            drawFooter(waveform: waveform, in: context.cgContext)
        }
        return ECGReport(
            pdfData: data,
            sourceSampleUUID: waveform.sourceSampleUUID,
            lead: waveform.lead
        )
    }

    private func drawHeader(
        classification: HKElectrocardiogram.Classification,
        averageBPM: Double?,
        date: Date,
        in context: CGContext
    ) {
        let title = HealthKitDataManager.HealthMetric.ecg.displayTitle(
            config: HealthSensorsConfigurationLoader.config
        )
        let classificationText = classification.displayTitle(config: .fallback)
        let bpmText = averageBPM.map {
            ECGReportCopy.averageBPM(Int($0.rounded()))
        } ?? ECGReportCopy.averageUnavailable
        let dateText = date.formatted(date: .abbreviated, time: .shortened)
        title.draw(
            at: CGPoint(x: FileConstants.pageMargin, y: 28),
            withAttributes: [.font: UIFont.systemFont(ofSize: 25, weight: .bold)]
        )
        classificationText.draw(
            at: CGPoint(x: FileConstants.pageMargin, y: 63),
            withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]
        )
        bpmText.draw(
            at: CGPoint(x: FileConstants.pageMargin + 220, y: 63),
            withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)]
        )
        dateText.draw(
            at: CGPoint(x: FileConstants.pageSize.width - FileConstants.pageMargin - 180, y: 31),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: FileConstants.pageMargin, y: 91))
        context.addLine(to: CGPoint(x: FileConstants.pageSize.width - FileConstants.pageMargin, y: 91))
        context.strokePath()
    }

    private func drawWaveform(_ waveform: ECGWaveform, in context: CGContext) {
        let pointsPerMillimeter = FileConstants.pointsPerInch / FileConstants.millimetersPerInch
        let stripWidth = 25 * pointsPerMillimeter * FileConstants.secondsPerStrip
        for stripIndex in 0..<FileConstants.stripCount {
            let rect = CGRect(
                x: FileConstants.pageMargin,
                y: 105 + CGFloat(stripIndex) * (FileConstants.stripHeight + FileConstants.stripSpacing),
                width: stripWidth,
                height: FileConstants.stripHeight
            )
            drawGrid(in: rect, context: context)
            drawStrip(
                waveform,
                startTime: Double(stripIndex) * FileConstants.secondsPerStrip,
                in: rect,
                context: context
            )
        }
    }

    private func drawGrid(in rect: CGRect, context: CGContext) {
        let pointsPerMillimeter = FileConstants.pointsPerInch / FileConstants.millimetersPerInch
        context.saveGState()
        context.clip(to: rect)

        var x = rect.minX
        var index = 0
        while x <= rect.maxX {
            context.setStrokeColor(UIColor.systemGray4.withAlphaComponent(index.isMultiple(of: 5) ? 0.8 : 0.35).cgColor)
            context.setLineWidth(index.isMultiple(of: 5) ? 0.45 : 0.2)
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.strokePath()
            x += pointsPerMillimeter
            index += 1
        }

        var y = rect.minY
        index = 0
        while y <= rect.maxY {
            context.setStrokeColor(UIColor.systemGray4.withAlphaComponent(index.isMultiple(of: 5) ? 0.8 : 0.35).cgColor)
            context.setLineWidth(index.isMultiple(of: 5) ? 0.45 : 0.2)
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.strokePath()
            y += pointsPerMillimeter
            index += 1
        }
        context.restoreGState()
    }

    private func drawStrip(
        _ waveform: ECGWaveform,
        startTime: TimeInterval,
        in rect: CGRect,
        context: CGContext
    ) {
        let endTime = startTime + FileConstants.secondsPerStrip
        let samples = waveform.samples.filter {
            $0.timeSinceSampleStart >= startTime && $0.timeSinceSampleStart <= endTime
        }
        guard let first = samples.first else { return }

        let centerY = rect.midY
        let pointsPerMillivolt = 10 * FileConstants.pointsPerInch / FileConstants.millimetersPerInch
        let path = CGMutablePath()
        path.move(to: point(for: first, startTime: startTime, rect: rect, centerY: centerY, scale: pointsPerMillivolt))
        for sample in samples.dropFirst() {
            path.addLine(to: point(for: sample, startTime: startTime, rect: rect, centerY: centerY, scale: pointsPerMillivolt))
        }
        context.saveGState()
        context.clip(to: rect)
        context.addPath(path)
        context.setStrokeColor(UIColor.tintColor.cgColor)
        context.setLineWidth(FileConstants.waveformWidth)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()

        "\(Int(startTime))s".draw(
            at: CGPoint(x: rect.minX + 4, y: rect.maxY - 17),
            withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }

    private func point(
        for sample: ECGVoltageSample,
        startTime: TimeInterval,
        rect: CGRect,
        centerY: CGFloat,
        scale: CGFloat
    ) -> CGPoint {
        let progress = (sample.timeSinceSampleStart - startTime) / FileConstants.secondsPerStrip
        return CGPoint(
            x: rect.minX + CGFloat(progress) * rect.width,
            y: centerY - CGFloat(sample.millivolts) * scale
        )
    }

    private func drawFooter(waveform: ECGWaveform, in context: CGContext) {
        let footer = ECGReportCopy.calibration(
            samplingFrequencyHz: Int(waveform.samplingFrequencyHz.rounded())
        )
        footer.draw(
            at: CGPoint(x: FileConstants.pageMargin, y: 552),
            withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)]
        )
        ECGReportCopy.provenance.draw(
            at: CGPoint(x: FileConstants.pageMargin, y: 572),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        _ = context
    }
}
