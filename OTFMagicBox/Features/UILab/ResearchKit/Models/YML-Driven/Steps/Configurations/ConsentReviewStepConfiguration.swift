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
struct ConsentReviewStepConfiguration: Codable {
    // Step identity and UI
    var identifier: String
    var title: OTFStringLocalized
    var text: OTFStringLocalized?
    var reasonForConsent: OTFStringLocalized
    var requiresScrollToBottom: Bool

    // Minimal document fields (mirrors VisualConsentStepConfiguration approach)
    var documentTitle: OTFStringLocalized
    var signaturePageTitle: OTFStringLocalized
    var signaturePageContent: OTFStringLocalized

    // Participant signature configuration
    var participantTitle: OTFStringLocalized
    var participantSignatureIdentifier: String
}

extension ConsentReviewStepConfiguration {

    init(from raw: RawConsentReviewStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.text = raw.text ?? fb.text
        self.reasonForConsent = raw.reasonForConsent ?? fb.reasonForConsent
        self.requiresScrollToBottom = raw.requiresScrollToBottom ?? fb.requiresScrollToBottom

        self.documentTitle = raw.documentTitle ?? fb.documentTitle
        self.signaturePageTitle = raw.signaturePageTitle ?? fb.signaturePageTitle
        self.signaturePageContent = raw.signaturePageContent ?? fb.signaturePageContent

        self.participantTitle = raw.participantTitle ?? fb.participantTitle
        self.participantSignatureIdentifier = raw.participantSignatureIdentifier ?? fb.participantSignatureIdentifier
    }

    var step: ORKConsentReviewStep {
        // Build a minimal, valid consent document and participant signature
        let document = ORKConsentDocument()
        document.title = documentTitle.localized
        document.signaturePageTitle = signaturePageTitle.localized
        document.signaturePageContent = signaturePageContent.localized

        let participantSignature = ORKConsentSignature(
            forPersonWithTitle: participantTitle.localized,
            dateFormatString: nil,
            identifier: participantSignatureIdentifier
        )
        document.addSignature(participantSignature)

        // Create review step
        let review = ORKConsentReviewStep(
            identifier: identifier,
            signature: participantSignature,
            in: document
        )
        review.title = title.localized
        review.text = text?.localized
        review.reasonForConsent = reasonForConsent.localized
        review.requiresScrollToBottom = requiresScrollToBottom

        return review
    }
}

extension ConsentReviewStepConfiguration {
    static let fallback = ConsentReviewStepConfiguration(
        identifier: "consentReviewStep",
        title: "Consent Document",
        text: "Please review the consent and sign to continue.",
        reasonForConsent: "I agree to participate in this study.",
        requiresScrollToBottom: true,
        documentTitle: "Example Consent",
        signaturePageTitle: "Consent",
        signaturePageContent: "I agree to participate in this research study.",
        participantTitle: "Participant",
        participantSignatureIdentifier: "consentDocumentParticipantSignature"
    )
}

#Preview {
    TaskViewControllerRepresentable(
        task: ORKOrderedTask(identifier: "consentReviewPreview", steps: [ConsentReviewStepConfiguration.fallback.step])
    )
}
