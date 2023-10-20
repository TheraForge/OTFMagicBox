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

struct Login: Codable {
    let loginPasswordless: String
    let loginStepTitle: String
    let loginStepText: String
    let failedLoginTitle: String
    let failedLoginText: String
}
 
struct Passcode: Codable {
    let enable: String
    let passcodeOnReturnText: String
    let passcodeText: String
    let passcodeType: String
}

struct DesignConfig: Codable {
    let name: String
    let textValue: String
}

struct DefaultConfig: Codable{
    let apiKey: String
    let en: DataModel
    let fr: DataModel
    let designConfig: [DesignConfig]
    let teamWebsite: String
    let showAppleSignin: String
    let showGoogleSignin: String
    let teamEmail: String
    let teamPhone: String
    let showCheckupScreen: String
    let showStaticUIScreen: String
    let useCareKit: String
    let appTheme: ThemeCustomization
}

struct DataModel: Codable {
    let appTitle: String
    let teamName: String
    let copyright: String
}

struct ThemeCustomization: Codable{
    let backgroundColor: String
    let textColor: String
    let separatorColor: String
    let cellbackgroundColor: String
    let buttonTextColor: String
    let borderColor: String
    let headerColor: String
    let textWeight: String
    let textFont: String
    let screenTitleFont: String
    let screenTitleWeight: String
    let headerTitleFont: String
    let headerTitleWeight: String
    let appTitleSize: String
}
