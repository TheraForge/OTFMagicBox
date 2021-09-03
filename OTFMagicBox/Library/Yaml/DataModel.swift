//
//  DataModel.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import Foundation

struct Onboarding: Codable {
    let logo: String
    let description: String
}

struct Registration: Codable {
    let isDOB: String
    let isGender: String
}

struct Consent: Codable {
    let title: String
    let summary: String
    let content: String
}

struct HealthRecords: Codable {
    let enabled: String
    let permissionsText: String
    let permissionsTitle: String
}

struct Withdrawl: Codable {
    let withdrawTitle: String
    let withdrawText: String
    let withdrawalInstructionTitle: String
    let withdrawalInstructionText: String
}

struct HealthKitDataToRead: Codable {
    let type: String
}

struct DesignConfig: Codable {
    let name: String
    let textValue: String
}

struct DataModel: Codable {
    let designConfig: [DesignConfig]
    let studyTitle: String
    let teamName: String
    let teamEmail: String
    let teamPhone: String
    let copyright: String
    let teamWebsite: String
    let reviewConsentStepText: String
    let reasonForConsentText: String
    let consentFileName: String
    let passcodeOnReturnText: String
    let passcodeText: String
    let passcodeType: String
    let completionStepTitle: String
    let completionStepText: String
    let failedLoginTitle: String
    let failedLoginText: String
    let healthPermissionsTitle: String
    let healthPermissionsText: String
    let consentTitle: String
    let useCareKit: String
    let backgroundReadFrequency: String
    let loginPasswordless: String
    let loginStepTitle: String
    let loginStepText: String
    let registration: Registration
    let onboarding: [Onboarding]
    let consent: [Consent]
    let healthRecords: HealthRecords
    let healthKitDataToRead: [HealthKitDataToRead]
    let withdrawl: Withdrawl
}
