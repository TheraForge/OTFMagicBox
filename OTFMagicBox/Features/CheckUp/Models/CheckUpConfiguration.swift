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
struct CheckUpConfiguration: Codable {
    let version: String

    // Screen text
    let navigationTitle: OTFStringLocalized
    let sectionHeaderTitle: OTFStringLocalized

    // Alert
    let alertAccountDeletedTitle: OTFStringLocalized
    let alertAccountDeletedMessage: OTFStringLocalized
    let alertOkButtonTitle: OTFStringLocalized

    // Rows
    let rowActivitiesTitle: OTFStringLocalized
    let rowActivitiesColor: OTFColor
    let rowActivitiesLineWidth: Double

    let rowMedicationsTitle: OTFStringLocalized
    let rowMedicationsColor: OTFColor
    let rowMedicationsLineWidth: Double

    let rowCheckupsTitle: OTFStringLocalized
    let rowCheckupsColor: OTFColor
    let rowCheckupsLineWidth: Double

    let rowAppointmentsTitle: OTFStringLocalized
    let rowAppointmentsColor: OTFColor
    let rowAppointmentsLineWidth: Double
}

extension CheckUpConfiguration: OTFVersionedDecodable {
    typealias Raw = RawCheckUpConfiguration

    static let fallback = CheckUpConfiguration(
        version: "2.0.0",
        navigationTitle: "Check-Up",
        sectionHeaderTitle: "Today",
        alertAccountDeletedTitle: "Account Deleted",
        alertAccountDeletedMessage: "Your account was removed from this device.",
        alertOkButtonTitle: "OK",
        rowActivitiesTitle: "Physical Activities",
        rowActivitiesColor: .blue,
        rowActivitiesLineWidth: 4.0,
        rowMedicationsTitle: "Medications Taken",
        rowMedicationsColor: .green,
        rowMedicationsLineWidth: 4.0,
        rowCheckupsTitle: "Checkups",
        rowCheckupsColor: .green,
        rowCheckupsLineWidth: 4.0,
        rowAppointmentsTitle: "Appointments",
        rowAppointmentsColor: .green,
        rowAppointmentsLineWidth: 4.0
    )

    init(from raw: RawCheckUpConfiguration) {
        let fallback = Self.fallback
        version = raw.version ?? fallback.version

        navigationTitle = raw.navigationTitle ?? fallback.navigationTitle
        sectionHeaderTitle = raw.sectionHeaderTitle ?? fallback.sectionHeaderTitle

        alertAccountDeletedTitle = raw.alertAccountDeletedTitle ?? fallback.alertAccountDeletedTitle
        alertAccountDeletedMessage = raw.alertAccountDeletedMessage ?? fallback.alertAccountDeletedMessage
        alertOkButtonTitle = raw.alertOkButtonTitle ?? fallback.alertOkButtonTitle

        rowActivitiesTitle = raw.rowActivitiesTitle ?? fallback.rowActivitiesTitle
        rowActivitiesColor = raw.rowActivitiesColor ?? fallback.rowActivitiesColor
        rowActivitiesLineWidth = raw.rowActivitiesLineWidth ?? fallback.rowActivitiesLineWidth

        rowMedicationsTitle = raw.rowMedicationsTitle ?? fallback.rowMedicationsTitle
        rowMedicationsColor = raw.rowMedicationsColor ?? fallback.rowMedicationsColor
        rowMedicationsLineWidth = raw.rowMedicationsLineWidth ?? fallback.rowMedicationsLineWidth

        rowCheckupsTitle = raw.rowCheckupsTitle ?? fallback.rowCheckupsTitle
        rowCheckupsColor = raw.rowCheckupsColor ?? fallback.rowCheckupsColor
        rowCheckupsLineWidth = raw.rowCheckupsLineWidth ?? fallback.rowCheckupsLineWidth

        rowAppointmentsTitle = raw.rowAppointmentsTitle ?? fallback.rowAppointmentsTitle
        rowAppointmentsColor = raw.rowAppointmentsColor ?? fallback.rowAppointmentsColor
        rowAppointmentsLineWidth = raw.rowAppointmentsLineWidth ?? fallback.rowAppointmentsLineWidth
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawCheckUpConfiguration) throws -> CheckUpConfiguration {
        CheckUpConfiguration(from: raw)
    }
}
