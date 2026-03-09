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
import RawModel

@RawGenerable
struct AppStyle: Codable, Identifiable {
    var id: String { name }
    let name: String
    let useLargeNavigationTitle: Bool
    let tintColor: OTFColor
    let accentColor: OTFColor
    let buttonHighlightColor: OTFColor
    let borderColor: OTFColor
    let headerProminenceIncreased: Bool
    let textFont: OTFFont
    let textFontWeight: OTFFontWeight
    let headerFont: OTFFont
    let headerFontWeight: OTFFontWeight
    let titleFont: OTFFont
    let titleFontWeight: OTFFontWeight
    let buttonTextFontWeight: OTFFontWeight
    let disabledTintColor: OTFColor

    // MARK: - Fallbacks (safe defaults)
    
    static let custom = AppStyle(
        name: "customStyle",
        useLargeNavigationTitle: true,
        tintColor: .systemBlue,
        accentColor: .systemBlue,
        buttonHighlightColor: .systemBlue,
        borderColor: .label,
        headerProminenceIncreased: true,
        textFont: .body,
        textFontWeight: .regular,
        headerFont: .title2,
        headerFontWeight: .semibold,
        titleFont: .title,
        titleFontWeight: .bold,
        buttonTextFontWeight: .semibold,
        disabledTintColor: .systemBlue
    )

    static let health = AppStyle(
        name: "healthStyle",
        useLargeNavigationTitle: true,
        tintColor: .systemBlue,
        accentColor: .systemBlue,
        buttonHighlightColor: .systemBlue,
        borderColor: .systemGray3,
        headerProminenceIncreased: true,
        textFont: .body,
        textFontWeight: .regular,
        headerFont: .title2,
        headerFontWeight: .bold,
        titleFont: .title,
        titleFontWeight: .bold,
        buttonTextFontWeight: .semibold,
        disabledTintColor: .systemBlue
    )

    static let careKit = AppStyle(
        name: "careKitStyle",
        useLargeNavigationTitle: false,
        tintColor: .systemTeal,
        accentColor: .systemTeal,
        buttonHighlightColor: .systemTeal,
        borderColor: .systemGray4,
        headerProminenceIncreased: true,
        textFont: .body,
        textFontWeight: .medium,
        headerFont: .title2,
        headerFontWeight: .bold,
        titleFont: .title,
        titleFontWeight: .bold,
        buttonTextFontWeight: .semibold,
        disabledTintColor: .systemTeal
    )
}

extension AppStyle {
    init(from raw: RawAppStyle) {
        let fallback = Self.custom
        self.name = raw.name ?? fallback.name
        self.useLargeNavigationTitle = raw.useLargeNavigationTitle ?? fallback.useLargeNavigationTitle
        self.tintColor = raw.tintColor ?? fallback.tintColor
        self.accentColor = raw.accentColor ?? fallback.accentColor
        self.buttonHighlightColor = raw.buttonHighlightColor ?? fallback.buttonHighlightColor
        self.borderColor = raw.borderColor ?? fallback.borderColor
        self.headerProminenceIncreased = raw.headerProminenceIncreased ?? fallback.headerProminenceIncreased
        self.textFont = raw.textFont ?? fallback.textFont
        self.textFontWeight = raw.textFontWeight ?? fallback.textFontWeight
        self.headerFont = raw.headerFont ?? fallback.headerFont
        self.headerFontWeight = raw.headerFontWeight ?? fallback.headerFontWeight
        self.titleFont = raw.titleFont ?? fallback.titleFont
        self.titleFontWeight = raw.titleFontWeight ?? fallback.titleFontWeight
        self.buttonTextFontWeight = raw.buttonTextFontWeight ?? fallback.buttonTextFontWeight
        self.disabledTintColor = raw.disabledTintColor ?? fallback.disabledTintColor
    }
}
