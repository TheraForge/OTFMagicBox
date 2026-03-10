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
import UIKit

@RawGenerable
struct SpeechRecognitionTaskConfiguration: Codable {

    var identifier: String

    // Display
    var title: OTFStringLocalized

    // Speech recognition parameters
    // Use ORKSpeechRecognizerLocale raw string constants (e.g., ORKSpeechRecognizerLocaleEnglishUS)
    var speechRecognizerLocale: String

    // Optional asset name for the image shown to the participant
    var speechRecognitionImageAssetName: String?

    // Optional text shown to the participant
    var speechRecognitionText: OTFStringLocalized?

    var shouldHideTranscript: Bool
    var allowsEdittingTranscript: Bool
}

extension SpeechRecognitionTaskConfiguration {

    init(from raw: RawSpeechRecognitionTaskConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier
        self.title = raw.title ?? Self.fallback.title
        self.speechRecognizerLocale = raw.speechRecognizerLocale ?? Self.fallback.speechRecognizerLocale
        self.speechRecognitionImageAssetName = raw.speechRecognitionImageAssetName ?? Self.fallback.speechRecognitionImageAssetName
        self.speechRecognitionText = raw.speechRecognitionText ?? Self.fallback.speechRecognitionText
        self.shouldHideTranscript = raw.shouldHideTranscript ?? Self.fallback.shouldHideTranscript
        self.allowsEdittingTranscript = raw.allowsEdittingTranscript ?? Self.fallback.allowsEdittingTranscript
    }

    var task: ORKTask {
        let image: UIImage?
        if let name = speechRecognitionImageAssetName, !name.isEmpty {
            image = UIImage(named: name)
        } else {
            image = nil
        }

        return ORKOrderedTask.speechRecognitionTask(
            withIdentifier: identifier,
            intendedUseDescription: title.localized,
            speechRecognizerLocale: ORKSpeechRecognizerLocale(rawValue: speechRecognizerLocale),
            speechRecognitionImage: image,
            speechRecognitionText: speechRecognitionText?.localized,
            shouldHideTranscript: shouldHideTranscript,
            allowsEdittingTranscript: allowsEdittingTranscript,
            options: []
        )
    }
}

extension SpeechRecognitionTaskConfiguration {

    static let fallback = SpeechRecognitionTaskConfiguration(
        identifier: "speechRecognitionTask",
        title: "Speech Recognition",
        speechRecognizerLocale: "en-US",
        speechRecognitionImageAssetName: nil,
        speechRecognitionText: "A quick brown fox jumps over the lazy dog.",
        shouldHideTranscript: false,
        allowsEdittingTranscript: true
    )
}

#Preview {
    TaskViewControllerRepresentable(task: SpeechRecognitionTaskConfiguration.fallback.task)
}
