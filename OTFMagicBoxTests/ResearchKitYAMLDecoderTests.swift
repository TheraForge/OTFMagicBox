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
import OTFResearchKit
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("ResearchKit YAML one-key decoders")
struct ResearchKitYAMLDecoderTests {
    @Test("Answer type decodes valid single-key payload and rejects malformed key counts")
    func answerTypeDecodesSingleKeyPayload() throws {
        let answer = try researchKitDecodeJSON(ResearchKitAnswerType.self, from: [
            "boolean": [
                "yesString": researchKitLocalized("Yes"),
                "noString": researchKitLocalized("No")
            ]
        ])

        guard case .boolean(let config) = answer else {
            Issue.record("Expected boolean answer type")
            return
        }
        #expect(config.yesString.localized == "Yes")
        #expect(config.noString.localized == "No")

        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitAnswerType.self, from: [:])
        }
        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitAnswerType.self, from: [
                "boolean": ["yesString": researchKitLocalized("Yes"), "noString": researchKitLocalized("No")],
                "text": ["maximumLength": 20]
            ])
        }
    }

    @Test("Step type decodes valid single-key payload and rejects malformed key counts")
    func stepTypeDecodesSingleKeyPayload() throws {
        let step = try researchKitDecodeJSON(ResearchKitStep.self, from: [
            "instruction": [
                "identifier": "intro",
                "title": researchKitLocalized("Intro"),
                "text": researchKitLocalized("Welcome"),
                "detailText": researchKitLocalized("Details")
            ]
        ])

        guard case .instruction(let config) = step else {
            Issue.record("Expected instruction step")
            return
        }
        #expect(config.identifier == "intro")
        #expect(config.title.localized == "Intro")

        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitStep.self, from: [:])
        }
        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitStep.self, from: [
                "instruction": [
                    "identifier": "intro",
                    "title": researchKitLocalized("Intro"),
                    "text": researchKitLocalized("Welcome"),
                    "detailText": researchKitLocalized("Details")
                ],
                "completion": [
                    "identifier": "done",
                    "title": researchKitLocalized("Done"),
                    "text": researchKitLocalized("Complete")
                ]
            ])
        }
    }

    @Test("Task type decodes valid single-key ordered task payload and rejects malformed key counts")
    func taskTypeDecodesSingleKeyPayload() throws {
        let task = try researchKitDecodeJSON(ResearchKitTaskType.self, from: [
            "orderedTask": [
                "identifier": "survey",
                "steps": [
                    [
                        "instruction": [
                            "identifier": "intro",
                            "title": researchKitLocalized("Intro"),
                            "text": researchKitLocalized("Welcome"),
                            "detailText": researchKitLocalized("Details")
                        ]
                    ]
                ]
            ]
        ])

        guard case .orderedTask(let config) = task else {
            Issue.record("Expected ordered task")
            return
        }
        #expect(config.identifier == "survey")
        #expect(config.steps.count == 1)

        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitTaskType.self, from: [:])
        }
        #expect(throws: DecodingError.self) {
            _ = try researchKitDecodeJSON(ResearchKitTaskType.self, from: [
                "orderedTask": ["identifier": "survey", "steps": []],
                "shortWalk": ["identifier": "walk"]
            ])
        }
    }
}

@Suite("ResearchKit YAML view model")
struct ResearchKitYMLViewModelTests {
    @Test("Loads section index and resolves page task using injected decoder")
    func loadsSectionIndexAndResolvesPageTask() throws {
        let page = StaticResearchKitPage(title: "Custom Survey", configFileName: "custom_survey")
        let indexConfig = StaticResearchKitConfiguration(
            version: "2.0.0",
            sections: [
                StaticResearchKitSection(title: "Surveys", tasks: [page])
            ]
        )
        let taskConfig = StaticResearchKitTaskConfiguration(
            version: "2.0.0",
            task: .orderedTask(OrderedTaskConfiguration(
                identifier: "custom-survey",
                steps: [
                    .instruction(InstructionStepConfiguration(
                        identifier: "intro",
                        title: "Intro",
                        text: "Start",
                        detailText: "Read this first."
                    ))
                ]
            ))
        )
        let decoder = ResearchKitFakeYAMLDecoder(stubs: [
            "StaticResearchKitConfiguration": indexConfig,
            "custom_survey": taskConfig
        ])

        let model = YMLResearchKitViewModel(decoder: decoder)
        let task = try #require(model.task(for: page) as? ORKOrderedTask)

        #expect(decoder.decodedFiles == ["StaticResearchKitConfiguration", "custom_survey"])
        #expect(model.config.sections.map(\.title.localized) == ["Surveys"])
        #expect(model.config.sections.first?.tasks.map(\.configFileName) == ["custom_survey"])
        #expect(task.identifier == "custom-survey")
        #expect(task.steps.map(\.identifier) == ["intro"])
    }

    @Test("Falls back to default index and task when decoder fails")
    func fallsBackToDefaultIndexAndTaskWhenDecoderFails() throws {
        let decoder = ResearchKitFakeYAMLDecoder(error: ResearchKitFakeYAMLDecoderError.requestedFailure)
        let model = YMLResearchKitViewModel(decoder: decoder)
        let page = StaticResearchKitPage(title: "Broken Survey", configFileName: "broken_survey")

        let task = try #require(model.task(for: page) as? ORKOrderedTask)

        #expect(decoder.decodedFiles == ["StaticResearchKitConfiguration", "broken_survey"])
        #expect(model.config.sections.map(\.title.localized) == StaticResearchKitConfiguration.fallback.sections.map(\.title.localized))
        #expect(task.identifier == OrderedTaskConfiguration.fallback.identifier)
    }
}

func researchKitDecodeJSON<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

func researchKitLocalized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}

private final class ResearchKitFakeYAMLDecoder: OTFYAMLDecoding {
    private let stubs: [String: Any]
    private let error: Error?
    private(set) var decodedFiles: [String] = []

    init(stubs: [String: Any] = [:], error: Error? = nil) {
        self.stubs = stubs
        self.error = error
    }

    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        decodedFiles.append(file)
        if let error {
            throw error
        }
        guard let value = stubs[file] as? T else {
            throw ResearchKitFakeYAMLDecoderError.missingStub(file)
        }
        return value
    }
}

private enum ResearchKitFakeYAMLDecoderError: Error {
    case requestedFailure
    case missingStub(String)
}
