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
struct PDFViewerStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized

    // URL string for the PDF to be displayed
    var pdfURLString: String
}

extension PDFViewerStepConfiguration {

    init(from raw: RawPDFViewerStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.pdfURLString = raw.pdfURLString ?? fb.pdfURLString
    }

    var step: ORKPDFViewerStep {
        let url = URL(string: pdfURLString)
        let step = ORKPDFViewerStep(identifier: identifier, pdfURL: url)
        step.title = title.localized
        return step
    }
}

extension PDFViewerStepConfiguration {
    static let fallback = PDFViewerStepConfiguration(
        identifier: "pdfViewerStep",
        title: "PDF Viewer",
        // Default to the ResearchKit.pdf in the main bundle, matching the sample
        pdfURLString: Bundle.main.bundleURL.appendingPathComponent("ResearchKit.pdf").absoluteString
    )
}

#Preview {
    let step = PDFViewerStepConfiguration.fallback.step
    return TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "pdfViewerTask", steps: [step]))
}
