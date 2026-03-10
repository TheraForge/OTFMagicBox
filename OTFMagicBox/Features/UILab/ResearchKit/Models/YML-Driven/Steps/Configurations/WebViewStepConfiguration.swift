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
struct WebViewStepConfiguration: Codable {
    var identifier: String
    var title: OTFStringLocalized

    // Embedded HTML to be displayed in the web view step
    var html: String

    // Optional custom CSS injected into the page
    var customCSS: String?

    // Whether to show a signature area after the content
    var showSignatureAfterContent: Bool
}

extension WebViewStepConfiguration {

    init(from raw: RawWebViewStepConfiguration) {
        let fb = Self.fallback
        self.identifier = raw.identifier ?? fb.identifier
        self.title = raw.title ?? fb.title
        self.html = raw.html ?? fb.html
        self.customCSS = raw.customCSS ?? fb.customCSS
        self.showSignatureAfterContent = raw.showSignatureAfterContent ?? fb.showSignatureAfterContent
    }

    var step: ORKWebViewStep {
        let step = ORKWebViewStep(identifier: identifier, html: html)
        step.title = title.localized
        step.customCSS = customCSS
        step.showSignatureAfterContent = showSignatureAfterContent
        return step
    }
}

extension WebViewStepConfiguration {
    static let fallback = WebViewStepConfiguration(
        identifier: "webViewStep",
        title: "Web View",
        html: """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
            <meta charset="utf-8" />
            <style>
                body { font-family: -apple-system, Helvetica, Arial, sans-serif; padding: 16px; }
                .answer-box { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px; }
                .continue-button { margin-top: 16px; padding: 12px 16px; border-radius: 10px; border: 1px solid #2e6e9e; color: #2e6e9e; background: #fff; }
            </style>
            <script>
                function completeStep() {
                    var answer = document.getElementById("answer").value;
                    window.webkit.messageHandlers.ResearchKit.postMessage(answer);
                }
            </script>
        </head>
        <body>
            <input id="answer" class="answer-box" placeholder="Type your answer" />
            <button onclick="completeStep();" class="continue-button">Continue</button>
        </body>
        </html>
        """,
        customCSS: nil,
        showSignatureAfterContent: true
    )
}

#Preview {
    TaskViewControllerRepresentable(task: ORKOrderedTask(identifier: "webViewTask", steps: [WebViewStepConfiguration.fallback.step]))
}
