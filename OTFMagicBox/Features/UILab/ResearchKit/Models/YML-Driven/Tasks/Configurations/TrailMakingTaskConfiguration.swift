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
struct TrailMakingTaskConfiguration: Codable {

    var identifier: String

    // Display / intended use
    var title: OTFStringLocalized

    // Specific parameters
    var trailmakingInstruction: OTFStringLocalized?
    var trailType: TrailMakingType
}

/// Encodes the trail type (A or B) and maps to ORKTrailMakingTypeIdentifier.
enum TrailMakingType: String, Codable {
    // swiftlint:disable:next identifier_name
    case A
    // swiftlint:disable:next identifier_name
    case B

    var ork: ORKTrailMakingTypeIdentifier {
        switch self {
        case .A: return ORKTrailMakingTypeIdentifier.A
        case .B: return ORKTrailMakingTypeIdentifier.B
        }
    }
}

extension TrailMakingTaskConfiguration {

    init(from raw: RawTrailMakingTaskConfiguration) {
        let fallback = Self.fallback
        self.identifier = raw.identifier ?? fallback.identifier
        self.title = raw.title ?? fallback.title
        self.trailmakingInstruction = raw.trailmakingInstruction ?? fallback.trailmakingInstruction
        self.trailType = raw.trailType ?? fallback.trailType
    }

    var task: ORKTask {
        ORKOrderedTask.trailmakingTask(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            trailmakingInstruction: trailmakingInstruction?.localized,
            trailType: trailType.ork,
            options: []
        )
    }
}

extension TrailMakingTaskConfiguration {

    static let fallback = TrailMakingTaskConfiguration(
        identifier: "trailMaking",
        title: "Trail Making",
        trailmakingInstruction: "Connect the circles in order as quickly as you can.",
        trailType: .B
    )
}

#Preview {
    TaskViewControllerRepresentable(task: TrailMakingTaskConfiguration.fallback.task)
}
