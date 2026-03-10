/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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
struct StaticTask: Codable {

    let id: String
    let title: OTFStringLocalized
    let instructions: OTFStringLocalized
    let asset: String
    let impactsAdherence: Bool
    @NestedRaw let schedules: [StaticTaskSchedule]

    static let fallback = StaticTask(
        id: "doxylamine",
        title: "Take Doxylamine",
        instructions: "Take 25mg of doxylamine when you experience nausea.",
        asset: "pills",
        impactsAdherence: false,
        schedules: [.fallback]
    )
}

extension StaticTask {

    init(from raw: RawStaticTask) {
        let fallback = Self.fallback
        self.id = raw.id ?? fallback.id
        self.title = raw.title ?? fallback.title
        self.instructions = raw.instructions ?? fallback.instructions
        self.asset = raw.asset ?? fallback.asset
        self.impactsAdherence = raw.impactsAdherence ?? fallback.impactsAdherence

        let decoded = (raw.schedules ?? []).map { StaticTaskSchedule(from: $0) }
        self.schedules = decoded.isEmpty ? fallback.schedules : decoded
    }
}

@RawGenerable
struct StaticTaskSchedule: Codable {
    let startHour: Int
    let intervalDay: Int
    let text: OTFStringLocalized

    static let fallback = StaticTaskSchedule(
        startHour: 8,
        intervalDay: 1,
        text: "Anytime throughout the day"
    )
}

extension StaticTaskSchedule {
    init(from raw: RawStaticTaskSchedule) {
        let fallback = Self.fallback
        self.startHour = raw.startHour ?? fallback.startHour
        self.intervalDay = raw.intervalDay ?? fallback.intervalDay
        self.text = raw.text ?? fallback.text
    }
}
