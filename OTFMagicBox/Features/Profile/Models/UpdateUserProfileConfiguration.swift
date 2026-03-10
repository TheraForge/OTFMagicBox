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
struct UpdateUserProfileConfiguration: Codable {
    let version: String
    let navTitle: OTFStringLocalized

    let personalInfoTitle: OTFStringLocalized
    let firstNameLabel: OTFStringLocalized
    let lastNameLabel: OTFStringLocalized
    let birthdateLabel: OTFStringLocalized
    let genderLabel: OTFStringLocalized
    let notSetText: OTFStringLocalized

    let editPhotoTitle: OTFStringLocalized
    let changePhotoDialogTitle: OTFStringLocalized
    let chooseFromPhotosTitle: OTFStringLocalized
    let removePhotoTitle: OTFStringLocalized
    let cancelTitle: OTFStringLocalized
}

extension UpdateUserProfileConfiguration: OTFVersionedDecodable {
    typealias Raw = RawUpdateUserProfileConfiguration

    static let fallback = UpdateUserProfileConfiguration(
        version: "2.0.0",
        navTitle: "Profile",
        personalInfoTitle: "Personal Information",
        firstNameLabel: "First Name",
        lastNameLabel: "Last Name",
        birthdateLabel: "Birthdate",
        genderLabel: "Gender",
        notSetText: "Not set",
        editPhotoTitle: "Edit Photo",
        changePhotoDialogTitle: "Change Photo",
        chooseFromPhotosTitle: "Choose from Photos",
        removePhotoTitle: "Remove Photo",
        cancelTitle: "Cancel"
    )

    init(from raw: RawUpdateUserProfileConfiguration) {
        let fallback = Self.fallback
        version = raw.version ?? fallback.version
        navTitle = raw.navTitle ?? fallback.navTitle
        personalInfoTitle = raw.personalInfoTitle ?? fallback.personalInfoTitle
        firstNameLabel = raw.firstNameLabel ?? fallback.firstNameLabel
        lastNameLabel = raw.lastNameLabel ?? fallback.lastNameLabel
        birthdateLabel = raw.birthdateLabel ?? fallback.birthdateLabel
        genderLabel = raw.genderLabel ?? fallback.genderLabel
        notSetText = raw.notSetText ?? fallback.notSetText
        editPhotoTitle = raw.editPhotoTitle ?? fallback.editPhotoTitle
        changePhotoDialogTitle = raw.changePhotoDialogTitle ?? fallback.changePhotoDialogTitle
        chooseFromPhotosTitle = raw.chooseFromPhotosTitle ?? fallback.chooseFromPhotosTitle
        removePhotoTitle = raw.removePhotoTitle ?? fallback.removePhotoTitle
        cancelTitle = raw.cancelTitle ?? fallback.cancelTitle
    }

    static func migrate(from version: OTFSemanticVersion, raw: Raw) throws -> UpdateUserProfileConfiguration {
        UpdateUserProfileConfiguration(from: raw)
    }
}
