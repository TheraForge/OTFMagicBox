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

import Charts
import SwiftUI

struct MetricSeriesChartView: View {
    
    private enum FileConstants {
        static let chartValue = "Date"
        static let chartHeight: CGFloat = 180
        static let colors: [Color] = [.red, .blue, .green, .orange]
        static let denseLinePointThreshold = 24
        static let lineWidth: CGFloat = 2
        static let linePointSize: CGFloat = 18
        static let scatterPointSize: CGFloat = 36
    }
    
    let series: [MetricSeries]
    let chartType: HealthKitDataManager.HealthMetric.ChartType
    
    var body: some View {
        Chart {
            ForEach(Array(series.enumerated()), id: \.element.id) { index, line in
                ForEach(line.points) { point in
                    switch chartType {
                    case .line:
                        LineMark(
                            x: .value(FileConstants.chartValue, point.date),
                            y: .value(line.label, point.value)
                        )
                        .lineStyle(StrokeStyle(lineWidth: FileConstants.lineWidth))
                        .foregroundStyle(FileConstants.colors[index % FileConstants.colors.count])
                        .interpolationMethod(.monotone)
                        
                        if line.points.count <= FileConstants.denseLinePointThreshold {
                            PointMark(
                                x: .value(FileConstants.chartValue, point.date),
                                y: .value(line.label, point.value)
                            )
                            .foregroundStyle(FileConstants.colors[index % FileConstants.colors.count])
                            .symbolSize(FileConstants.linePointSize)
                        }
                        
                    case .bar:
                        BarMark(
                            x: .value(FileConstants.chartValue, point.date),
                            y: .value(line.label, point.value)
                        )
                        .foregroundStyle(FileConstants.colors[index % FileConstants.colors.count])
                        
                    case .scatter:
                        PointMark(
                            x: .value(FileConstants.chartValue, point.date),
                            y: .value(line.label, point.value)
                        )
                        .foregroundStyle(FileConstants.colors[index % FileConstants.colors.count])
                        .symbolSize(FileConstants.scatterPointSize)
                    }
                }
            }
        }
        .frame(height: FileConstants.chartHeight)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
    }
}

#Preview {
    let points = [
        MetricPoint(date: Date(), value: 80),
        MetricPoint(date: Date().addingTimeInterval(-60), value: 85)
    ]
    let series = [MetricSeries(label: "HR", unit: "bpm", points: points)]
    MetricSeriesChartView(series: series, chartType: .line)
}
