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
import UIKit
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct SpatialSpanMemoryTaskConfiguration: Codable {

    var identifier: String

    // Display
    var title: OTFStringLocalized

    // Spatial span parameters
    var initialSpan: Int
    var minimumSpan: Int
    var maximumSpan: Int
    var playSpeed: TimeInterval
    var maximumTests: Int
    var maximumConsecutiveFailures: Int
    // Asset name for a template image in the asset catalog (optional)
    var customTargetImageName: String?
    // Localized plural name for the custom target (optional)
    var customTargetPluralName: OTFStringLocalized?
    var requireReversal: Bool
}

extension SpatialSpanMemoryTaskConfiguration {

    init(from raw: RawSpatialSpanMemoryTaskConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.initialSpan = raw.initialSpan ?? Self.fallback.initialSpan
        self.minimumSpan = raw.minimumSpan ?? Self.fallback.minimumSpan
        self.maximumSpan = raw.maximumSpan ?? Self.fallback.maximumSpan
        self.playSpeed = raw.playSpeed ?? Self.fallback.playSpeed
        self.maximumTests = raw.maximumTests ?? Self.fallback.maximumTests
        self.maximumConsecutiveFailures = raw.maximumConsecutiveFailures ?? Self.fallback.maximumConsecutiveFailures
        self.customTargetImageName = raw.customTargetImageName ?? Self.fallback.customTargetImageName
        self.customTargetPluralName = raw.customTargetPluralName ?? Self.fallback.customTargetPluralName
        self.requireReversal = raw.requireReversal ?? Self.fallback.requireReversal
    }

    var task: ORKTask {
        let image = customTargetImageName.flatMap { UIImage(named: $0) }
        return ORKOrderedTask.spatialSpanMemoryTask(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            initialSpan: initialSpan,
            minimumSpan: minimumSpan,
            maximumSpan: maximumSpan,
            playSpeed: playSpeed,
            maximumTests: maximumTests,
            maximumConsecutiveFailures: maximumConsecutiveFailures,
            customTargetImage: image,
            customTargetPluralName: customTargetPluralName?.localized,
            requireReversal: requireReversal,
            options: []
        )
    }
}

extension SpatialSpanMemoryTaskConfiguration {

    static let fallback = SpatialSpanMemoryTaskConfiguration(
        identifier: "spatialSpanMemoryTask",
        title: "Spatial Span Memory",
        initialSpan: 3,
        minimumSpan: 2,
        maximumSpan: 15,
        playSpeed: 1.0,
        maximumTests: 5,
        maximumConsecutiveFailures: 3,
        customTargetImageName: nil,
        customTargetPluralName: nil,
        requireReversal: false
    )
}

#Preview {
    TaskViewControllerRepresentable(task: SpatialSpanMemoryTaskConfiguration.fallback.task)
}
