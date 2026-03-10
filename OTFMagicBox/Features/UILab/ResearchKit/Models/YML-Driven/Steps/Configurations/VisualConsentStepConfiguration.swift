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
struct VisualConsentStepConfiguration: Codable {
    var identifier: String

    // Document-level fields
    var documentTitle: OTFStringLocalized
    var signaturePageTitle: OTFStringLocalized
    var signaturePageContent: OTFStringLocalized

    // Content for a minimal overview section
    var sectionTitle: OTFStringLocalized
    var sectionSummary: OTFStringLocalized
    var sectionHTMLContent: OTFStringLocalized?
}

extension VisualConsentStepConfiguration {

    init(from raw: RawVisualConsentStepConfiguration) {
        self.identifier = raw.identifier ?? Self.fallback.identifier

        self.documentTitle = raw.documentTitle ?? Self.fallback.documentTitle
        self.signaturePageTitle = raw.signaturePageTitle ?? Self.fallback.signaturePageTitle
        self.signaturePageContent = raw.signaturePageContent ?? Self.fallback.signaturePageContent

        self.sectionTitle = raw.sectionTitle ?? Self.fallback.sectionTitle
        self.sectionSummary = raw.sectionSummary ?? Self.fallback.sectionSummary
        self.sectionHTMLContent = raw.sectionHTMLContent ?? Self.fallback.sectionHTMLContent
    }

    var step: ORKVisualConsentStep {
        // Build a minimal, valid consent document with one visible Overview section
        let document = ORKConsentDocument()
        document.title = documentTitle.localized
        document.signaturePageTitle = signaturePageTitle.localized
        document.signaturePageContent = signaturePageContent.localized

        let overview = ORKConsentSection(type: .overview)
        overview.title = sectionTitle.localized
        overview.summary = sectionSummary.localized
        if let html = sectionHTMLContent?.localized, !html.isEmpty {
            overview.htmlContent = html
        }

        document.sections = [overview]

        // Note: Signatures are typically added for the review step, not required for visual consent.
        return ORKVisualConsentStep(identifier: identifier, document: document)
    }
}

extension VisualConsentStepConfiguration {
    static let fallback = VisualConsentStepConfiguration(
        identifier: "visualConsentStep",
        documentTitle: "Example Consent",
        signaturePageTitle: "Consent",
        signaturePageContent: "I agree to participate in this research study.",
        sectionTitle: "Welcome",
        sectionSummary: "This study will explain how we collect and use your data.",
        sectionHTMLContent: "<p>Please read the following information carefully.</p>"
    )
}

#Preview {
    TaskViewControllerRepresentable(
        task: ORKOrderedTask(
            identifier: "visualConsentPreview",
            steps: [VisualConsentStepConfiguration.fallback.step]
        )
    )
}
