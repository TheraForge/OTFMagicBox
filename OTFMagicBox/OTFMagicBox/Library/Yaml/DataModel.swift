/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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

struct Onboarding: Codable, Equatable {
    let image: String
    let icon: String
    let title: String
    let color: String
    let description: String
}

struct Registration: Codable {
    let showDateOfBirth: String
    let showGender: String
}

struct Login: Codable {
    let loginPasswordless: String
    let loginStepTitle: String
    let loginStepText: String
    let failedLoginTitle: String
    let failedLoginText: String
}

struct LoginOptionsInfo: Codable {
    let text: String
    let icon: String
}

struct Consent: Codable {
     let reviewConsentStepText: String
     let reasonForConsentText: String
     let fileName: String
     let title: String
     let data: [ConsentDescription]
 }

 struct ConsentDescription: Codable {
     let show: String
     let summary: String
     let content: String
 }
 
struct Passcode: Codable {
    let enable: String
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

struct HealthKitTypes: Codable, Equatable  {
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
    let apiKey: String
    let studyTitle: String
    let teamName: String
    let teamEmail: String
    let teamPhone: String
    let copyright: String
    let teamWebsite: String
    let showAppleSignin: String
    let showGoogleSignin: String
    let googleClientID: String?
    let passcode: Passcode
    let completionStep: CompletionStep
    let useCareKit: String
    let showCheckupScreen: String
    let showStaticUIScreen: String
    let login: Login
    let loginOptionsInfo: LoginOptionsInfo
    let registration: Registration
    let onboarding: [Onboarding]
    let consent: Consent
    let healthRecords: HealthRecords
    let healthKitData: HealthKitData
    let withdrawal: Withdrawal
}
