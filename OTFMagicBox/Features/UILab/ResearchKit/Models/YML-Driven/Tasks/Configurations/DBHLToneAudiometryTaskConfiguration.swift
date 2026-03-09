// DBHLToneAudiometryTaskConfiguration.swift
import Foundation
import OTFTemplateBox
import OTFResearchKit
import RawModel
import SwiftUI

@RawGenerable
struct DBHLToneAudiometryTaskConfiguration: Codable {

    var identifier: String

    // Display
    var title: OTFStringLocalized
}

extension DBHLToneAudiometryTaskConfiguration {

    init(from raw: RawDBHLToneAudiometryTaskConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
    }

    var task: ORKTask {
        ORKOrderedTask.dBHLToneAudiometryTask(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            options: []
        )
    }
}

extension DBHLToneAudiometryTaskConfiguration {

    static let fallback = DBHLToneAudiometryTaskConfiguration(
        identifier: "dBHLToneAudiometryTask",
        title: "dBHL Tone Audiometry"
    )
}

#Preview {
    TaskViewControllerRepresentable(task: DBHLToneAudiometryTaskConfiguration.fallback.task)
}
