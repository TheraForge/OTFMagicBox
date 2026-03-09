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
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct PSATTaskConfiguration: Codable {

    var identifier: String

    // Display
    var title: OTFStringLocalized

    // PSAT parameters
    var presentationMode: PSATPresentationMode
    var interStimulusInterval: TimeInterval
    var stimulusDuration: TimeInterval
    var seriesLength: Int
}

struct PSATPresentationMode: OptionSet, Codable {
    let rawValue: Int

    static let auditory = PSATPresentationMode(rawValue: 1 << 0)
    static let visual   = PSATPresentationMode(rawValue: 1 << 1)

    init(rawValue: Int) { self.rawValue = rawValue }

    var orkValue: ORKPSATPresentationMode {
        var mode: ORKPSATPresentationMode = []
        if contains(.auditory) { mode.insert(.auditory) }
        if contains(.visual) { mode.insert(.visual) }
        return mode
    }
}

extension PSATTaskConfiguration {

    init(from raw: RawPSATTaskConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.presentationMode = raw.presentationMode ?? Self.fallback.presentationMode
        self.interStimulusInterval = raw.interStimulusInterval ?? Self.fallback.interStimulusInterval
        self.stimulusDuration = raw.stimulusDuration ?? Self.fallback.stimulusDuration
        self.seriesLength = raw.seriesLength ?? Self.fallback.seriesLength
    }

    var task: ORKTask {
        ORKOrderedTask.psatTask(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            presentationMode: presentationMode.orkValue,
            interStimulusInterval: interStimulusInterval,
            stimulusDuration: stimulusDuration,
            seriesLength: seriesLength,
            options: []
        )
    }
}

extension PSATTaskConfiguration {

    static let fallback = PSATTaskConfiguration(
        identifier: "psatTask",
        title: "PSAT",
        presentationMode: [.auditory, .visual],
        interStimulusInterval: 3.0,
        stimulusDuration: 1.0,
        seriesLength: 60
    )
}

#Preview {
    TaskViewControllerRepresentable(task: PSATTaskConfiguration.fallback.task)
}
