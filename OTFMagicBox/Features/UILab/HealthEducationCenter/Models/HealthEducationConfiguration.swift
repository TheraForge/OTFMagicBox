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
import OTFTemplateBox
import RawModel

@RawGenerable
struct HealthEducationConfiguration: Codable {
    let version: String
    let title: OTFStringLocalized
    let loadingLabel: OTFStringLocalized
    let loadErrorTitle: OTFStringLocalized
    let loadErrorMessage: OTFStringLocalized
    let retryButtonTitle: OTFStringLocalized
    let closeButtonTitle: OTFStringLocalized
    let openArticleAccessibilityHint: OTFStringLocalized
    let articleLanguageLabel: OTFStringLocalized
    @NestedRaw let articles: [HealthEducationArticle]
}

extension HealthEducationConfiguration: OTFVersionedDecodable {
    typealias Raw = RawHealthEducationConfiguration

    static let fallback = HealthEducationConfiguration(
        version: "2.0.0",
        title: "Health Education Center",
        loadingLabel: "Loading article",
        loadErrorTitle: "Unable to Load Article",
        loadErrorMessage: "Check your connection or try again.",
        retryButtonTitle: "Try Again",
        closeButtonTitle: "Close",
        openArticleAccessibilityHint: "Opens article",
        articleLanguageLabel: "Article available in English",
        articles: [
            HealthEducationArticle(
                id: "no-code-health-app",
                imageName: "health-education-no-code",
                title: "Build a Health App in Under an Hour with No-Code",
                summary: "Learn how no-code tools can quickly turn a healthcare idea into a working app.",
                url: "https://www.hippocratestech.com/build-a-health-app-in-under-an-hour-with-no-code/"
            ),
            HealthEducationArticle(
                id: "type-2-diabetes",
                imageName: "health-education-diabetes",
                title: "Understanding Type 2 Diabetes",
                summary: "What it is, common signs, and everyday steps that support healthier living.",
                url: "type-2-diabetes.html"
            ),
            HealthEducationArticle(
                id: "asthma",
                imageName: "health-education-asthma",
                title: "Living Well with Asthma",
                summary: "Learn about symptoms, common triggers, and practical ways to support asthma control.",
                url: "asthma.html"
            )
        ]
    )

    init(from raw: RawHealthEducationConfiguration) {
        let fallback = Self.fallback
        version = raw.version ?? fallback.version
        title = Self.localizedValue(raw.title, fallback: fallback.title)
        loadingLabel = Self.localizedValue(raw.loadingLabel, fallback: fallback.loadingLabel)
        loadErrorTitle = Self.localizedValue(raw.loadErrorTitle, fallback: fallback.loadErrorTitle)
        loadErrorMessage = Self.localizedValue(raw.loadErrorMessage, fallback: fallback.loadErrorMessage)
        retryButtonTitle = Self.localizedValue(raw.retryButtonTitle, fallback: fallback.retryButtonTitle)
        closeButtonTitle = Self.localizedValue(raw.closeButtonTitle, fallback: fallback.closeButtonTitle)
        openArticleAccessibilityHint = Self.localizedValue(
            raw.openArticleAccessibilityHint,
            fallback: fallback.openArticleAccessibilityHint
        )
        articleLanguageLabel = Self.localizedValue(
            raw.articleLanguageLabel,
            fallback: fallback.articleLanguageLabel
        )

        var identifiers = Set<String>()
        let decodedArticles = (raw.articles ?? [])
            .compactMap(HealthEducationArticle.init(from:))
            .filter { identifiers.insert($0.id).inserted }
        articles = decodedArticles.isEmpty ? fallback.articles : decodedArticles
    }

    static func migrate(
        from version: OTFSemanticVersion,
        raw: RawHealthEducationConfiguration
    ) throws -> HealthEducationConfiguration {
        HealthEducationConfiguration(from: raw)
    }

    private static func localizedValue(
        _ value: OTFStringLocalized?,
        fallback: OTFStringLocalized
    ) -> OTFStringLocalized {
        guard let value,
              !value.localized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return value
    }
}
