/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.
 
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

import SwiftUI

struct CountProgressRow: View {
    
    static var lessonsCompleted: CountProgressRow {
        CountProgressRow(title: "Lessons Completed",
                         completed: 3, total: 5,
                         color: .green, lineWidth: 4.0)
    }
    
    static var appointmentsScheduled: CountProgressRow {
        CountProgressRow(title: "Appointments",
                         completed: 1, total: 3,
                         color: .green, lineWidth: 4.0)
    }
    
    var title: String
    var completed: Int
    var total: Int
    var color: Color
    var lineWidth: CGFloat
    var opacity: Double = 0.3
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.otfTextColor)
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
            Spacer()
            Text("\(completed) of \(total)")
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .foregroundColor(color)
            RingProgressView(progress: total < 1 ? 0 : Float(completed) / Float(total),
                        color: color,
                        lineWidth: lineWidth)
            .frame(width: Metrics.FRAME_ROW_WIDTH, height: Metrics.FRAME_ROW_HEIGHT)
        }
    }
}

struct CountProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        CountProgressRow.lessonsCompleted
    }
}
