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
struct ReactionTimeTaskConfiguration: Codable {

    var identifier: String

    // Display
    var title: OTFStringLocalized

    // Reaction time parameters
    var maximumStimulusInterval: TimeInterval
    var minimumStimulusInterval: TimeInterval
    var thresholdAcceleration: Double
    var numberOfAttempts: Int
    var timeout: TimeInterval

    // Optional success sound from bundle
    var successSoundResourceName: String?
    var successSoundResourceExtension: String?

    // System sound IDs (0 = no sound)
    var timeoutSoundID: UInt32
    var failureSoundID: UInt32
}

extension ReactionTimeTaskConfiguration {

    init(from raw: RawReactionTimeTaskConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.maximumStimulusInterval = raw.maximumStimulusInterval ?? Self.fallback.maximumStimulusInterval
        self.minimumStimulusInterval = raw.minimumStimulusInterval ?? Self.fallback.minimumStimulusInterval
        self.thresholdAcceleration = raw.thresholdAcceleration ?? Self.fallback.thresholdAcceleration
        self.numberOfAttempts = raw.numberOfAttempts ?? Self.fallback.numberOfAttempts
        self.timeout = raw.timeout ?? Self.fallback.timeout
        self.successSoundResourceName = raw.successSoundResourceName ?? Self.fallback.successSoundResourceName
        self.successSoundResourceExtension = raw.successSoundResourceExtension ?? Self.fallback.successSoundResourceExtension
        self.timeoutSoundID = raw.timeoutSoundID ?? Self.fallback.timeoutSoundID
        self.failureSoundID = raw.failureSoundID ?? Self.fallback.failureSoundID
    }

    var task: ORKTask {
        let successSoundID: UInt32 = {
            guard
                let name = successSoundResourceName,
                let ext = successSoundResourceExtension,
                let url = Bundle.main.url(forResource: name, withExtension: ext),
                let systemSound = SystemSound(soundURL: url)
            else { return 0 }
            return systemSound.soundID
        }()

        return ORKOrderedTask.reactionTime(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            maximumStimulusInterval: maximumStimulusInterval,
            minimumStimulusInterval: minimumStimulusInterval,
            thresholdAcceleration: thresholdAcceleration,
            numberOfAttempts: Int32(numberOfAttempts),
            timeout: timeout,
            successSound: successSoundID,
            timeoutSound: timeoutSoundID,
            failureSound: failureSoundID,
            options: []
        )
    }
}

extension ReactionTimeTaskConfiguration {

    static let fallback = ReactionTimeTaskConfiguration(
        identifier: "reactionTime",
        title: "Reaction Time",
        maximumStimulusInterval: 10,
        minimumStimulusInterval: 4,
        thresholdAcceleration: 0.5,
        numberOfAttempts: 3,
        timeout: 3,
        successSoundResourceName: "tap",
        successSoundResourceExtension: "aif",
        timeoutSoundID: 0,
        failureSoundID: UInt32(kSystemSoundID_Vibrate)
    )
}

#Preview {
    TaskViewControllerRepresentable(task: ReactionTimeTaskConfiguration.fallback.task)
}
