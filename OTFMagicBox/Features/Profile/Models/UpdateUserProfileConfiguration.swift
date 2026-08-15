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

    let healthProfileTitle: OTFStringLocalized
    let healthProfilePrivacyNotice: OTFStringLocalized
    let locationLabel: OTFStringLocalized
    let locationDisplayNameLabel: OTFStringLocalized
    let locationDisplayNamePlaceholder: OTFStringLocalized
    let cityLabel: OTFStringLocalized
    let cityPlaceholder: OTFStringLocalized
    let fullAddressTitle: OTFStringLocalized
    let addressLine1Label: OTFStringLocalized
    let addressLine2Label: OTFStringLocalized
    let regionLabel: OTFStringLocalized
    let postalCodeLabel: OTFStringLocalized
    let countryCodeLabel: OTFStringLocalized
    let countryCodePlaceholder: OTFStringLocalized
    let clearLocationTitle: OTFStringLocalized
    let conditionsLabel: OTFStringLocalized
    let conditionsSelectionText: OTFStringLocalized
    let conditionsNoneReportedText: OTFStringLocalized
    let conditionsUnknownText: OTFStringLocalized
    let clearConditionsTitle: OTFStringLocalized
    let conditionLabels: [String: OTFStringLocalized]
    let countryCodeValidationMessage: OTFStringLocalized
    let profileSaveErrorTitle: OTFStringLocalized
    let profileSaveErrorMessage: OTFStringLocalized
    let saveErrorDismissTitle: OTFStringLocalized

    let editPhotoTitle: OTFStringLocalized
    let changePhotoDialogTitle: OTFStringLocalized
    let chooseFromPhotosTitle: OTFStringLocalized
    let removePhotoTitle: OTFStringLocalized
    let cancelTitle: OTFStringLocalized
}

extension UpdateUserProfileConfiguration: OTFVersionedDecodable {
    typealias Raw = RawUpdateUserProfileConfiguration

    static let fallback = UpdateUserProfileConfiguration(
        version: "2.4.0",
        navTitle: "Profile",
        personalInfoTitle: "Personal Information",
        firstNameLabel: "First Name",
        lastNameLabel: "Last Name",
        birthdateLabel: "Birthdate",
        genderLabel: "Gender",
        notSetText: "Not set",
        healthProfileTitle: "Health Profile",
        healthProfilePrivacyNotice: "Optional self-reported location and health conditions help complete your profile. Provide only the minimum location detail needed; a country, city, or region is enough when a full address is not needed. This feature does not access GPS or precise device location. You can edit or clear these values at any time.",
        locationLabel: "Location",
        locationDisplayNameLabel: "Country",
        locationDisplayNamePlaceholder: "Enter your country",
        cityLabel: "City",
        cityPlaceholder: "Enter your city",
        fullAddressTitle: "Full address",
        addressLine1Label: "Address line 1",
        addressLine2Label: "Address line 2",
        regionLabel: "State / region",
        postalCodeLabel: "Postal code",
        countryCodeLabel: "Country calling code",
        countryCodePlaceholder: "Enter calling code, for example +351",
        clearLocationTitle: "Clear location",
        conditionsLabel: "Health conditions",
        conditionsSelectionText: "Select all that apply or None reported.",
        conditionsNoneReportedText: "None reported",
        conditionsUnknownText: "Not sure",
        clearConditionsTitle: "Clear conditions",
        conditionLabels: HealthProfileConditionCatalogue.defaultLabels,
        countryCodeValidationMessage: "Use a valid country calling code, for example +351.",
        profileSaveErrorTitle: "Unable to save profile",
        profileSaveErrorMessage: "Your changes are still available to edit. Please try again.",
        saveErrorDismissTitle: "OK",
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
        healthProfileTitle = raw.healthProfileTitle ?? fallback.healthProfileTitle
        healthProfilePrivacyNotice = raw.healthProfilePrivacyNotice ?? fallback.healthProfilePrivacyNotice
        locationLabel = raw.locationLabel ?? fallback.locationLabel
        locationDisplayNameLabel = raw.locationDisplayNameLabel ?? fallback.locationDisplayNameLabel
        locationDisplayNamePlaceholder = raw.locationDisplayNamePlaceholder ?? fallback.locationDisplayNamePlaceholder
        cityLabel = raw.cityLabel ?? fallback.cityLabel
        cityPlaceholder = raw.cityPlaceholder ?? fallback.cityPlaceholder
        fullAddressTitle = raw.fullAddressTitle ?? fallback.fullAddressTitle
        addressLine1Label = raw.addressLine1Label ?? fallback.addressLine1Label
        addressLine2Label = raw.addressLine2Label ?? fallback.addressLine2Label
        regionLabel = raw.regionLabel ?? fallback.regionLabel
        postalCodeLabel = raw.postalCodeLabel ?? fallback.postalCodeLabel
        countryCodeLabel = raw.countryCodeLabel ?? fallback.countryCodeLabel
        countryCodePlaceholder = raw.countryCodePlaceholder ?? fallback.countryCodePlaceholder
        clearLocationTitle = raw.clearLocationTitle ?? fallback.clearLocationTitle
        conditionsLabel = raw.conditionsLabel ?? fallback.conditionsLabel
        conditionsSelectionText = raw.conditionsSelectionText ?? fallback.conditionsSelectionText
        conditionsNoneReportedText = raw.conditionsNoneReportedText ?? fallback.conditionsNoneReportedText
        conditionsUnknownText = raw.conditionsUnknownText ?? fallback.conditionsUnknownText
        clearConditionsTitle = raw.clearConditionsTitle ?? fallback.clearConditionsTitle
        conditionLabels = raw.conditionLabels ?? fallback.conditionLabels
        countryCodeValidationMessage = raw.countryCodeValidationMessage ?? fallback.countryCodeValidationMessage
        profileSaveErrorTitle = raw.profileSaveErrorTitle ?? fallback.profileSaveErrorTitle
        profileSaveErrorMessage = raw.profileSaveErrorMessage ?? fallback.profileSaveErrorMessage
        saveErrorDismissTitle = raw.saveErrorDismissTitle ?? fallback.saveErrorDismissTitle
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

extension UpdateUserProfileConfiguration {
    func conditionLabel(for condition: MedicalCondition) -> String {
        HealthProfileConditionCatalogue.localizedName(
            for: condition,
            configuredLabels: conditionLabels
        )
    }
}
