//
//  DataModel.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import Foundation

struct Onboarding: Codable {
    let image: String
    let description: String
}

struct Registration: Codable {
    let isDOB: String
    let isGender: String
}

struct Login: Codable {
    let loginPasswordless: Bool
    let loginStepTitle: String
    let loginStepText: String
    let failedLoginTitle: String
    let failedLoginText: String
}

struct Consent: Codable {
    let reviewConsentStepText: String
    let reasonForConsentText: String
    let fileName: String
    let title: String
    let data: [ConsentData]
}

struct ConsentData: Codable {
    let title: String
    let summary: String
    let content: String
}

struct Passcode: Codable {
    let enable: Bool
    let passcodeOnReturnText: String
    let passcodeText: String
    let passcodeType: String
}

struct HealthKitData: Codable {
    let healthPermissionsTitle: String
    let healthPermissionsText: String
    let backgroundReadFrequency: String
    let healthKitTypes: [HealthKitTypes]
}

struct HealthRecords: Codable {
    let enabled: String
    let permissionsText: String
    let permissionsTitle: String
}

struct Withdrawal: Codable {
    let withdrawTitle: String
    let withdrawText: String
    let withdrawalInstructionTitle: String
    let withdrawalInstructionText: String
}

struct HealthKitTypes: Codable {
    let type: String
}

struct CompletionStep: Codable {
    let title: String
    let text: String
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
    let passcode: Passcode
    let completionStep: CompletionStep
    let useCareKit: Bool
    let login: Login
    let registration: Registration
    let onboarding: [Onboarding]
    let consent: Consent
    let healthRecords: HealthRecords
    let healthKitData: HealthKitData
    let withdrawal: Withdrawal
}
