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

 4. Commercial redistribution in any form requires an explicit license agreement with
 the copyright holder(s). Please contact support@hippocratestech.com for further information
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
import OTFCareKitStore
import OTFTemplateBox

enum ProfileUserInfoKey {
    static let attachments = "attachments"
    static let location = "location"
    static let conditions = "conditions"
}

struct MedicalCondition: Codable, Equatable, Hashable, Identifiable {
    let system: String
    let code: String
    let name: String

    var id: String { "\(system)|\(code)" }
}

struct ReportedCondition: Codable, Equatable, Hashable {
    let coding: MedicalCondition
    let onset: Date?
    let notes: String?

    init(coding: MedicalCondition, onset: Date? = nil, notes: String? = nil) {
        self.coding = coding
        self.onset = onset
        self.notes = notes
    }
}

enum ConditionsReportingStatus: String, Codable, Equatable {
    case reported
    case none
    case unknown
}

struct ConditionsResponse: Codable, Equatable {
    let status: ConditionsReportingStatus
    let items: [ReportedCondition]

    init(status: ConditionsReportingStatus, items: [ReportedCondition]) {
        self.status = status
        self.items = status == .reported ? uniqueReportedConditions(items) : []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedStatus = try container.decode(ConditionsReportingStatus.self, forKey: .status)
        let decodedItems = try container.decode([ReportedCondition].self, forKey: .items)

        try Self.validate(status: decodedStatus, items: decodedItems)
        status = decodedStatus
        items = uniqueReportedConditions(decodedItems)
    }

    func encode(to encoder: Encoder) throws {
        try Self.validate(status: status, items: items)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(items, forKey: .items)
    }

    private static func validate(status: ConditionsReportingStatus, items: [ReportedCondition]) throws {
        switch status {
        case .reported:
            guard !items.isEmpty,
                  items.allSatisfy({
                      $0.coding.system == HealthProfileConditionCatalogue.snomedSystem &&
                          normalizedText($0.coding.code) != nil &&
                          normalizedText($0.coding.name) != nil
                  }) else {
                throw HealthProfileMetadataError.invalidConditionsResponse
            }
        case .none, .unknown:
            guard items.isEmpty else {
                throw HealthProfileMetadataError.invalidConditionsResponse
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case items
    }
}

private struct RawConditionUserInfoItem: Codable, Equatable {
    let code: String
    let name: String

    init(condition: MedicalCondition) {
        code = condition.code
        name = condition.name
    }
}

struct ProfileLocation: Codable, Equatable {
    /// The user's self-reported country. It is encoded as `displayName` to retain
    /// compatibility with the backend userInfo contract.
    var country: String?
    var city: String?
    var addressLine1: String?
    var addressLine2: String?
    var region: String?
    var postalCode: String?
    var countryCode: String?

    init(
        country: String? = nil,
        city: String? = nil,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        region: String? = nil,
        postalCode: String? = nil,
        countryCode: String? = nil
    ) {
        self.country = country
        self.city = city
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.region = region
        self.postalCode = postalCode
        self.countryCode = countryCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        city = [
            try container.decodeIfPresent(String.self, forKey: .city),
            try container.decodeIfPresent(String.self, forKey: .locality)
        ].compactMap(normalizedText).first
        addressLine1 = try container.decodeIfPresent(String.self, forKey: .addressLine1)
        addressLine2 = try container.decodeIfPresent(String.self, forKey: .addressLine2)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
    }

    func encode(to encoder: Encoder) throws {
        let location = normalized
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(location.country, forKey: .country)
        try container.encodeIfPresent(location.city, forKey: .city)
        try container.encodeIfPresent(location.addressLine1, forKey: .addressLine1)
        try container.encodeIfPresent(location.addressLine2, forKey: .addressLine2)
        try container.encodeIfPresent(location.region, forKey: .region)
        try container.encodeIfPresent(location.postalCode, forKey: .postalCode)
        try container.encodeIfPresent(location.countryCode, forKey: .countryCode)
    }

    var normalized: ProfileLocation {
        var location = self
        location.country = normalizedText(country)
        location.city = normalizedText(city)
        location.addressLine1 = normalizedText(addressLine1)
        location.addressLine2 = normalizedText(addressLine2)
        location.region = normalizedText(region)
        location.postalCode = normalizedText(postalCode)
        location.countryCode = normalizedCountryCode(countryCode)
        return location
    }

    var isEmpty: Bool {
        country == nil &&
            city == nil &&
            addressLine1 == nil &&
            addressLine2 == nil &&
            region == nil &&
            postalCode == nil &&
            countryCode == nil
    }

    var bestAvailableSummary: String? {
        let location = normalized
        var components = [
            location.addressLine1,
            location.addressLine2,
            location.city,
            location.region,
            location.postalCode,
            location.countryCode
        ].compactMap { $0 }
        if let country = location.country, country != location.city {
            components.insert(country, at: 0)
        }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    var hasStructuredAddress: Bool {
        let location = normalized
        return location.addressLine1 != nil ||
            location.addressLine2 != nil ||
            location.region != nil ||
            location.postalCode != nil ||
            location.countryCode != nil
    }

    var hasValidCountryCode: Bool {
        guard countryCode != nil else { return true }
        return normalizedCountryCode(countryCode) != nil
    }

    var hasValidCallingCode: Bool {
        guard normalizedText(countryCode) != nil else { return true }
        return normalizedCallingCode(countryCode) != nil
    }

    private enum CodingKeys: String, CodingKey {
        case city
        case addressLine1
        case addressLine2
        case region
        case postalCode
        case countryCode
        case country = "displayName"
        case locality
    }
}

enum HealthProfileConditionCatalogue {
    static let snomedSystem = "http://snomed.info/sct"

    static let conditions: [MedicalCondition] = [
        condition(code: "44054006", name: "Type 2 diabetes mellitus"),
        condition(code: "46635009", name: "Type 1 diabetes mellitus"),
        condition(code: "38341003", name: "Hypertensive disorder, systemic arterial"),
        condition(code: "84114007", name: "Heart failure"),
        condition(code: "53741008", name: "Coronary arteriosclerosis"),
        condition(code: "22298006", name: "Myocardial infarction"),
        condition(code: "230690007", name: "Cerebrovascular accident"),
        condition(code: "13645005", name: "Chronic obstructive pulmonary disease"),
        condition(code: "195967001", name: "Asthma"),
        condition(code: "233604007", name: "Pneumonia"),
        condition(code: "65363002", name: "Otitis media"),
        condition(code: "444814009", name: "Viral upper respiratory tract infection"),
        condition(code: "36971009", name: "Acute sinusitis"),
        condition(code: "10509002", name: "Acute bronchitis"),
        condition(code: "193462001", name: "Chronic kidney disease"),
        condition(code: "709044004", name: "Chronic kidney disease stage 3"),
        condition(code: "271737000", name: "Anemia"),
        condition(code: "64859006", name: "Osteoporosis"),
        condition(code: "396275006", name: "Osteoarthritis"),
        condition(code: "370143000", name: "Major depressive disorder")
    ]

    static let defaultLabels: [String: OTFStringLocalized] = [
        "44054006": label("Type 2 diabetes mellitus", "Diabetes mellitus tipo 2", "داء السكري من النوع الثاني"),
        "46635009": label("Type 1 diabetes mellitus", "Diabetes mellitus tipo 1", "داء السكري من النوع الأول"),
        "38341003": label("Hypertensive disorder, systemic arterial", "Hipertensão arterial sistémica", "اضطراب ارتفاع ضغط الدم الشرياني الجهازي"),
        "84114007": label("Heart failure", "Insuficiência cardíaca", "قصور القلب"),
        "53741008": label("Coronary arteriosclerosis", "Aterosclerose coronária", "تصلب الشرايين التاجية"),
        "22298006": label("Myocardial infarction", "Enfarte do miocárdio", "احتشاء عضلة القلب"),
        "230690007": label("Cerebrovascular accident", "Acidente vascular cerebral", "سكتة دماغية"),
        "13645005": label("Chronic obstructive pulmonary disease", "Doença pulmonar obstrutiva crónica", "مرض الانسداد الرئوي المزمن"),
        "195967001": label("Asthma", "Asma", "الربو"),
        "233604007": label("Pneumonia", "Pneumonia", "الالتهاب الرئوي"),
        "65363002": label("Otitis media", "Otite média", "التهاب الأذن الوسطى"),
        "444814009": label("Viral upper respiratory tract infection", "Infeção viral das vias respiratórias superiores", "عدوى فيروسية في الجهاز التنفسي العلوي"),
        "36971009": label("Acute sinusitis", "Sinusite aguda", "التهاب الجيوب الأنفية الحاد"),
        "10509002": label("Acute bronchitis", "Bronquite aguda", "التهاب الشعب الهوائية الحاد"),
        "193462001": label("Chronic kidney disease", "Doença renal crónica", "مرض الكلى المزمن"),
        "709044004": label("Chronic kidney disease stage 3", "Doença renal crónica estádio 3", "مرض الكلى المزمن، المرحلة الثالثة"),
        "271737000": label("Anemia", "Anemia", "فقر الدم"),
        "64859006": label("Osteoporosis", "Osteoporose", "هشاشة العظام"),
        "396275006": label("Osteoarthritis", "Osteoartrose", "الفصال العظمي"),
        "370143000": label("Major depressive disorder", "Perturbação depressiva major", "الاضطراب الاكتئابي الشديد")
    ]

    static func condition(withID identifier: String) -> MedicalCondition? {
        conditions.first { $0.id == identifier }
    }

    static func condition(withCode code: String) -> MedicalCondition? {
        conditions.first { $0.code == code }
    }

    static func localizedName(
        for condition: MedicalCondition,
        configuredLabels: [String: OTFStringLocalized]
    ) -> String {
        guard condition.system == snomedSystem,
              let localized = normalizedText(configuredLabels[condition.code]?.localized) else {
            return condition.name
        }
        return localized
    }

    private static func condition(code: String, name: String) -> MedicalCondition {
        MedicalCondition(system: snomedSystem, code: code, name: name)
    }

    private static func label(_ english: String, _ portuguese: String, _ arabic: String) -> OTFStringLocalized {
        OTFStringLocalized(localized: ["en": english, "pt": portuguese, "ar": arabic])
    }
}

struct HealthProfileDraft: Equatable {
    var location: ProfileLocation
    var selectedConditions: Set<MedicalCondition>
    var reportingStatus: ConditionsReportingStatus?
    private var unrecognizedReportedItems: [ReportedCondition]

    init(patient: OCKPatient) {
        location = patient.profileLocation ?? ProfileLocation()
        selectedConditions = []
        reportingStatus = patient.conditionsResponse?.status
        unrecognizedReportedItems = []

        guard let response = patient.conditionsResponse, response.status == .reported else { return }
        for item in response.items {
            if let configuredCondition = HealthProfileConditionCatalogue.condition(withID: item.coding.id) {
                selectedConditions.insert(configuredCondition)
            } else {
                unrecognizedReportedItems.append(item)
            }
        }
    }

    mutating func setCondition(_ condition: MedicalCondition, isSelected: Bool) {
        if isSelected {
            reportingStatus = .reported
            selectedConditions.insert(condition)
        } else {
            selectedConditions.remove(condition)
            if selectedConditions.isEmpty && unrecognizedReportedItems.isEmpty {
                reportingStatus = nil
            }
        }
    }

    mutating func setReportingStatus(_ status: ConditionsReportingStatus) {
        guard status != .reported else { return }
        reportingStatus = status
        selectedConditions.removeAll()
        unrecognizedReportedItems.removeAll()
    }

    mutating func clearConditions() {
        reportingStatus = nil
        selectedConditions.removeAll()
        unrecognizedReportedItems.removeAll()
    }

    func apply(
        to patient: inout OCKPatient,
        applyLocation: Bool = true,
        applyConditions: Bool = true
    ) throws {
        let initialDraft = HealthProfileDraft(patient: patient)
        let locationChanged = applyLocation && location != initialDraft.location
        let conditionsChanged = applyConditions && (
            reportingStatus != initialDraft.reportingStatus ||
            selectedConditions != initialDraft.selectedConditions ||
            unrecognizedReportedItems != initialDraft.unrecognizedReportedItems
        )
        guard locationChanged || conditionsChanged else { return }
        guard !locationChanged || location.hasValidCallingCode else {
            throw HealthProfileDraftValidationError.invalidCountryCode
        }

        var updatedPatient = patient
        if locationChanged {
            try updatedPatient.setProfileLocation(location)
        }
        if conditionsChanged {
            try updatedPatient.setConditionsResponse(makeConditionsResponse())
        }
        patient = updatedPatient
    }

    private func makeConditionsResponse() -> ConditionsResponse? {
        guard let reportingStatus else { return nil }
        guard reportingStatus == .reported else {
            return ConditionsResponse(status: reportingStatus, items: [])
        }

        let selectedItems = HealthProfileConditionCatalogue.conditions
            .filter(selectedConditions.contains)
            .map { ReportedCondition(coding: $0) }
        return ConditionsResponse(
            status: .reported,
            items: selectedItems + unrecognizedReportedItems
        )
    }
}

enum HealthProfileDraftValidationError: Error, Equatable {
    case invalidCountryCode
}

extension OCKPatient {
    var conditionsResponse: ConditionsResponse? {
        guard let encoded = userInfo?[ProfileUserInfoKey.conditions] else { return nil }
        if let response = try? decodeHealthProfileValue(ConditionsResponse.self, from: encoded) {
            return response
        }
        guard let rawItems = try? decodeHealthProfileValue([RawConditionUserInfoItem].self, from: encoded),
              rawItems.allSatisfy({
                  normalizedText($0.code) != nil && normalizedText($0.name) != nil
              }) else {
            return nil
        }
        guard !rawItems.isEmpty else {
            return ConditionsResponse(status: .none, items: [])
        }
        return ConditionsResponse(
            status: .reported,
            items: rawItems.map {
                ReportedCondition(coding: MedicalCondition(
                    system: HealthProfileConditionCatalogue.snomedSystem,
                    code: $0.code,
                    name: $0.name
                ))
            }
        )
    }

    var profileLocation: ProfileLocation? {
        guard let encoded = userInfo?[ProfileUserInfoKey.location] else { return nil }
        return decodeProfileLocation(from: encoded)?.normalized
    }

    mutating func setConditionsResponse(_ response: ConditionsResponse?) throws {
        guard let response else {
            removeProfileUserInfoValue(forKey: ProfileUserInfoKey.conditions)
            return
        }
        guard let encoded = try encodedConditionsUserInfoValue(response) else {
            removeProfileUserInfoValue(forKey: ProfileUserInfoKey.conditions)
            return
        }
        setProfileUserInfoValue(
            encoded,
            forKey: ProfileUserInfoKey.conditions
        )
    }

    mutating func setProfileLocation(_ location: ProfileLocation?) throws {
        guard let normalizedLocation = location?.normalized, !normalizedLocation.isEmpty else {
            removeProfileUserInfoValue(forKey: ProfileUserInfoKey.location)
            return
        }
        setProfileUserInfoValue(
            try encodeHealthProfileValue(normalizedLocation),
            forKey: ProfileUserInfoKey.location
        )
    }

    private func decodeProfileLocation(from encoded: String) -> ProfileLocation? {
        if let location = try? decodeHealthProfileValue(ProfileLocation.self, from: encoded) {
            return location
        }
        guard let legacyLocation = try? decodeHealthProfileValue(String.self, from: encoded) else {
            let plainLocation = normalizedText(encoded)
            guard let plainLocation,
                  !plainLocation.hasPrefix("{"),
                  !plainLocation.hasPrefix("[") else {
                return nil
            }
            return ProfileLocation(city: plainLocation)
        }
        return ProfileLocation(city: legacyLocation)
    }

    private mutating func setProfileUserInfoValue(_ value: String, forKey key: String) {
        var values = userInfo ?? [:]
        values[key] = value
        userInfo = values
    }

    private mutating func removeProfileUserInfoValue(forKey key: String) {
        guard var values = userInfo else { return }
        values.removeValue(forKey: key)
        userInfo = values.isEmpty ? nil : values
    }
}

func encodeHealthProfileValue<Value: Encodable>(_ value: Value) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    guard let encodedValue = String(data: data, encoding: .utf8) else {
        throw HealthProfileMetadataError.invalidUTF8
    }
    return encodedValue
}

func encodedConditionsUserInfoValue(_ response: ConditionsResponse) throws -> String? {
    guard response.items.allSatisfy({ $0.onset == nil && $0.notes == nil }) else {
        throw HealthProfileMetadataError.unsupportedConditionsExtension
    }
    switch response.status {
    case .reported:
        return try encodeHealthProfileValue(response.items.map {
            RawConditionUserInfoItem(condition: $0.coding)
        })
    case .none:
        return try encodeHealthProfileValue([RawConditionUserInfoItem]())
    case .unknown:
        return nil
    }
}

private func decodeHealthProfileValue<Value: Decodable>(_ type: Value.Type, from encoded: String) throws -> Value {
    try JSONDecoder().decode(Value.self, from: Data(encoded.utf8))
}

private func uniqueReportedConditions(_ items: [ReportedCondition]) -> [ReportedCondition] {
    var seen = Set<String>()
    return items.filter { seen.insert($0.coding.id).inserted }
}

private func normalizedText(_ value: String?) -> String? {
    guard let value else { return nil }
    let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalizedValue.isEmpty ? nil : normalizedValue
}

private func normalizedCountryCode(_ value: String?) -> String? {
    guard let normalizedValue = normalizedText(value) else { return nil }
    if normalizedValue.hasPrefix("+") {
        return normalizedCallingCode(normalizedValue)
    }
    let uppercasedValue = normalizedValue.uppercased()
    guard uppercasedValue.count == 2, isoCountryCodes.contains(uppercasedValue) else {
        return nil
    }
    return uppercasedValue
}

private func normalizedCallingCode(_ value: String?) -> String? {
    guard let normalizedValue = normalizedText(value), normalizedValue.hasPrefix("+") else {
        return nil
    }
    let digits = normalizedValue.dropFirst()
    guard (1 ... 3).contains(digits.count) else { return nil }

    var asciiDigits = ""
    for character in digits {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first,
              scalar.properties.generalCategory == .decimalNumber,
              let digit = character.wholeNumberValue,
              (0 ... 9).contains(digit) else {
            return nil
        }
        asciiDigits.append(String(digit))
    }
    guard asciiDigits.first != "0" else { return nil }
    return "+" + asciiDigits
}

private let isoCountryCodes = Set(Locale.Region.isoRegions.map(\.identifier))

enum HealthProfileMetadataError: Error {
    case invalidUTF8
    case invalidConditionsResponse
    case unsupportedConditionsExtension
}
