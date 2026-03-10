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
import RawModel

@RawGenerable
struct OnboardingConfiguration: Codable {
    let version: String
    @NestedRaw let pages: [OnboardingPage]

    let primaryButtonTitle: OTFStringLocalized
    let primaryButtonBackgroundColor: OTFColor
    let primaryButtonTitleColor: OTFColor

    let secondaryButtonTitle: OTFStringLocalized
    let secondaryButtonBackgroundColor: OTFColor
    let secondaryButtonTitleColor: OTFColor
}

extension OnboardingConfiguration: OTFVersionedDecodable {
    typealias Raw = RawOnboardingConfiguration

    static let fallback = OnboardingConfiguration(
        version: "2.0.0",
        pages: [OnboardingPage.fallbackWelcome, .fallbackVitals, .fallbackActivities],
        primaryButtonTitle: "Sign Up",
        primaryButtonBackgroundColor: .label,
        primaryButtonTitleColor: .systemBackground,
        secondaryButtonTitle: "Sign In",
        secondaryButtonBackgroundColor: .blue,
        secondaryButtonTitleColor: .white
    )

    init(from raw: RawOnboardingConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version

        let decoded = (raw.pages ?? []).map { OnboardingPage(from: $0) }
        self.pages = decoded.isEmpty ? fallback.pages : decoded

        self.primaryButtonTitle = raw.primaryButtonTitle ?? fallback.primaryButtonTitle
        self.primaryButtonBackgroundColor = raw.primaryButtonBackgroundColor ?? fallback.primaryButtonBackgroundColor
        self.primaryButtonTitleColor = raw.primaryButtonTitleColor ?? fallback.primaryButtonTitleColor

        self.secondaryButtonTitle = raw.secondaryButtonTitle ?? fallback.secondaryButtonTitle
        self.secondaryButtonBackgroundColor = raw.secondaryButtonBackgroundColor ?? fallback.secondaryButtonBackgroundColor
        self.secondaryButtonTitleColor = raw.secondaryButtonTitleColor ?? fallback.secondaryButtonTitleColor
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawOnboardingConfiguration) throws -> OnboardingConfiguration {
        OnboardingConfiguration(from: raw)
    }
}
