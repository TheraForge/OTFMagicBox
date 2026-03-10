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

import SwiftUI
import OTFTemplateBox
import OTFResearchKit
import RawModel

@RawGenerable
struct StaticResearchKitConfiguration {

    let version: String
    @NestedRaw let sections: [StaticResearchKitSection]
}

extension StaticResearchKitConfiguration: OTFVersionedDecodable {
    typealias Raw = RawStaticResearchKitConfiguration

    static let fallback = StaticResearchKitConfiguration(
        version: "2.0.0",
        sections: [
            StaticResearchKitSection(
                title: "Random tasks",
                tasks: [
                    StaticResearchKitPage(
                        title: "Audio Task",
                        configFileName: "audio_task"),
                    StaticResearchKitPage(
                        title: "Question Task",
                        configFileName: "question_task")
                ]
            )
        ]
    )

    init(from raw: RawStaticResearchKitConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version

        // Decode sections array with fallback if empty or missing
        let rawSections: [RawStaticResearchKitSection] = raw.sections ?? []
        let decodedSections = rawSections.map(StaticResearchKitSection.init(from:))
        self.sections = decodedSections.isEmpty ? fallback.sections : decodedSections
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawStaticResearchKitConfiguration) throws -> StaticResearchKitConfiguration {
        StaticResearchKitConfiguration(from: raw)
    }
}
