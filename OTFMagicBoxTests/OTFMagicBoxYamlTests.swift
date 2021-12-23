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

import XCTest
@testable import OTFMagicBox

class OTFMagicBoxYamlTests: XCTestCase {

    /*************************************************   THERAFORGE CONFIGURATIONS TESTS        *******************************************************************************/
    
    func testPrimaryColor() {
        let inputValue = YmlReader().primaryColor
        let expectedValue = UIColor().getColor(colorValue: "#5b4337")
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testTintColor() {
        let inputValue = YmlReader().tintColor
        let expectedValue = UIColor().getColor(colorValue: "#b6133f")
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testRegistrationIsDOB() {
        let inputValue = YmlReader().registration?.showDateOfBirth
        let expectedValue = Constants.true
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testRegistrationIsGender() {
        let inputValue = YmlReader().registration?.showGender
        let expectedValue = Constants.true
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    /*************************************************   CARDINALKIT CONFIGURATIONS TESTS        *******************************************************************************/
   
    func testStudyTitle() {
        let inputValue = YmlReader().studyTitle
        let expectedValue = "TheraForge"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    
    func testLoginPasswordless() {
        let inputValue = YmlReader().loginPasswordless
        let expectedValue = false
        XCTAssertEqual(inputValue, expectedValue);
    }

    func testLoginStepTitle() {
        let inputValue = YmlReader().loginStepTitle
        let expectedValue = "Almost done!"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testLoginStepText() {
        let inputValue = YmlReader().loginStepText
        let expectedValue = "We need to confirm your email address and send you a copy of the consent you just signed."
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testOnboardingData() {
        let inputValue = YmlReader().onboardingData?.first
        let expectedValue: Onboarding = Onboarding(image: "heart.circle", description: "Take PRIME care of your health")
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testTeamEmail() {
        let inputValue = YmlReader().teamEmail
        let expectedValue = "contact@theraforge.com"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testConsentTitle() {
        let inputValue = YmlReader().consentTitle
        let expectedValue = "TheraForge Consent"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testPasscodeType() {
        let inputValue = YmlReader().passcodeType
        let expectedValue = "4"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testFailedLoginTitle() {
        let inputValue = YmlReader().failedLoginTitle
        let expectedValue = "Unable to Login"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testHealthPermissionsTitle() {
        let inputValue = YmlReader().healthPermissionsTitle
        let expectedValue = "Permission to read Activity Data 🏃🏽‍♀️"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testUseCareKit() {
        let inputValue = YmlReader().useCareKit
        let expectedValue = true
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testHealthRecordsPermissionTitle() {
        let inputValue = YmlReader().healthRecords?.permissionsTitle
        let expectedValue = "Permission to read Health Records 🏥"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testHealthKitTypes() {
        let inputValue = YmlReader().healthKitDataToRead.first
        let expectedValue = HealthKitTypes(type: "StepCount")
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testCompletionStepTitle() {
        let inputValue = YmlReader().completionStepTitle
        let expectedValue = "Welcome aboard."
        XCTAssertEqual(inputValue, expectedValue);
    }


}

