//
//  OTFMagicBoxYamlTests.swift
//  OTFMagicBoxTests
//
//  Created by Spurti Benakatti on 24/09/21.
//

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
        let expectedValue = "true"
        XCTAssertEqual(inputValue, expectedValue);
    }
    
    func testRegistrationIsGender() {
        let inputValue = YmlReader().registration?.showGender
        let expectedValue = "true"
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

