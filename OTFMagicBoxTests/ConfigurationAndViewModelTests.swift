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
@preconcurrency import OTFCareKitStore
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("Configuration loading view models")
struct ConfigurationLoadingViewModelTests {
    @Test("Onboarding view model loads decoded configuration")
    func onboardingLoadsDecodedConfiguration() {
        let config = makeOnboardingConfiguration(primaryButtonTitle: "Create Account")
        let decoder = FakeYAMLDecoder(stubs: ["OnboardingConfiguration": config])

        let model = OnboardingViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["OnboardingConfiguration"])
        #expect(model.config.primaryButtonTitle.localized == "Create Account")
        #expect(model.currentPage == 0)
    }

    @Test("Onboarding view model falls back after decoder failure")
    func onboardingFallsBackAfterDecoderFailure() {
        let decoder = FakeYAMLDecoder(error: FakeYAMLDecoderError.requestedFailure)

        let model = OnboardingViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["OnboardingConfiguration"])
        #expect(
            model.config.primaryButtonTitle.localized == OnboardingConfiguration.fallback.primaryButtonTitle.localized
        )
        #expect(model.config.pages.count == OnboardingConfiguration.fallback.pages.count)
    }

    @Test("Contacts view model loads decoded configuration")
    func contactsLoadsDecodedConfiguration() {
        let config = makeContactsConfiguration(navTitle: "Care Team", emptySymbol: "person.crop.circle")
        let decoder = FakeYAMLDecoder(stubs: ["ContactsConfiguration": config])

        let model = ContactsViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["ContactsConfiguration"])
        #expect(model.config.navTitle.localized == "Care Team")
        #expect(model.config.emptySymbol == "person.crop.circle")
        #expect(!model.showAlert)
        #expect(model.alertMessage.isEmpty)
    }

    @Test("Contacts view model falls back after decoder failure")
    func contactsFallsBackAfterDecoderFailure() {
        let decoder = FakeYAMLDecoder(error: FakeYAMLDecoderError.requestedFailure)

        let model = ContactsViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["ContactsConfiguration"])
        #expect(model.config.navTitle.localized == ContactsConfiguration.fallback.navTitle.localized)
        #expect(model.config.emptySymbol == ContactsConfiguration.fallback.emptySymbol)
    }

    @Test("Contacts alert state records user-visible message")
    func contactsAlertStateRecordsMessage() {
        let model = ContactsViewModel(decoder: FakeYAMLDecoder(stubs: [
            "ContactsConfiguration": makeContactsConfiguration()
        ]))

        model.showAlert(message: "Network unavailable")

        #expect(model.showAlert)
        #expect(model.alertMessage == "Network unavailable")
    }

    @Test("Schedule view model loads decoded configuration")
    func scheduleLoadsDecodedConfiguration() {
        let config = makeScheduleConfiguration(navTitle: "Care Plan", todayLabel: "Jump to Today")
        let decoder = FakeYAMLDecoder(stubs: ["ScheduleConfiguration": config])

        let model = ScheduleViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["ScheduleConfiguration"])
        #expect(model.config.navTitle.localized == "Care Plan")
        #expect(model.config.todayLabel.localized == "Jump to Today")
    }

    @Test("Schedule view model falls back after decoder failure")
    func scheduleFallsBackAfterDecoderFailure() {
        let decoder = FakeYAMLDecoder(error: FakeYAMLDecoderError.requestedFailure)

        let model = ScheduleViewModel(decoder: decoder)

        #expect(decoder.decodedFiles == ["ScheduleConfiguration"])
        #expect(model.config.navTitle.localized == ScheduleConfiguration.fallback.navTitle.localized)
        #expect(model.config.todayLabel.localized == ScheduleConfiguration.fallback.todayLabel.localized)
    }

    @Test("Schedule UI strings are derived from configuration")
    func scheduleUIStringsAreDerivedFromConfiguration() {
        let config = makeScheduleConfiguration(
            emptyDayTitle: "Nothing scheduled",
            emptyDaySubtitle: "Enjoy the open day.",
            deletedAlertTitle: "Removed",
            deletedAlertMessage: "This account is no longer available."
        )
        let model = ScheduleViewModel(decoder: FakeYAMLDecoder(stubs: ["ScheduleConfiguration": config]))

        #expect(model.uiStrings.noTasksTitle == "Nothing scheduled")
        #expect(model.uiStrings.noTasksSubtitle == "Enjoy the open day.")
        #expect(model.uiStrings.deletedAlertTitle == "Removed")
        #expect(model.uiStrings.deletedAlertMessage == "This account is no longer available.")
    }

    @Test("Schedule go to today uses injected clock")
    func scheduleGoToTodayUsesInjectedClock() throws {
        let expectedDate = try fixedDate(day: 26)
        let model = ScheduleViewModel(
            decoder: FakeYAMLDecoder(stubs: ["ScheduleConfiguration": makeScheduleConfiguration()]),
            calendar: fixedCalendar,
            now: { expectedDate }
        )
        model.selectedDate = try fixedDate(day: 4)

        model.goToToday()

        #expect(model.selectedDate == expectedDate)
    }

    @Test("Schedule today symbol is deterministic with injected clock and validator")
    func scheduleTodaySymbolUsesInjectedClockAndValidator() throws {
        let maySeventh = try fixedDate(day: 7)
        let dynamicModel = ScheduleViewModel(
            decoder: FakeYAMLDecoder(stubs: ["ScheduleConfiguration": makeScheduleConfiguration()]),
            calendar: fixedCalendar,
            now: { maySeventh },
            systemImageExists: { $0 == "7.calendar" }
        )
        let disabledModel = ScheduleViewModel(
            decoder: FakeYAMLDecoder(stubs: [
                "ScheduleConfiguration": makeScheduleConfiguration(useDynamicCalendarSymbol: false)
            ]),
            calendar: fixedCalendar,
            now: { maySeventh },
            systemImageExists: { _ in true }
        )
        let missingSymbolModel = ScheduleViewModel(
            decoder: FakeYAMLDecoder(stubs: ["ScheduleConfiguration": makeScheduleConfiguration()]),
            calendar: fixedCalendar,
            now: { maySeventh },
            systemImageExists: { _ in false }
        )

        #expect(dynamicModel.todaySymbol == "7.calendar")
        #expect(disabledModel.todaySymbol == "calendar")
        #expect(missingSymbolModel.todaySymbol == "calendar")
    }
}

@Suite("Static CareKit view model")
struct StaticCareKitViewModelTests {
    @Test("Loads decoded configuration and inserts static task and contact into injected store")
    func loadsDecodedConfigurationAndInsertsStaticStoreModels() async throws {
        let config = makeStaticCareKitConfiguration()
        let decoder = FakeYAMLDecoder(stubs: ["StaticCareKitConfiguration": config])
        let store = OCKStore(name: "StaticCareKitViewModelTests-\(UUID().uuidString)", type: .inMemory)

        let model = StaticCareKitViewModel(decoder: decoder, ockStore: store)

        let task = try await waitForStaticCareKitTask(in: store, id: "hydration")
        let contact = try await waitForStaticCareKitContact(in: store, id: "GraceHopper")

        #expect(decoder.decodedFiles == ["StaticCareKitConfiguration"])
        #expect(model.config.task.id == "hydration")
        #expect(model.config.contact.id == "GraceHopper")
        #expect(task.title == "Hydration")
        #expect(task.instructions == "Drink water with breakfast.")
        #expect(task.asset == "drop")
        #expect(task.impactsAdherence)
        #expect(contact.name.givenName == "Grace")
        #expect(contact.name.familyName == "Hopper")
        #expect(contact.role == "Nurse")
        #expect(contact.emailAddresses?.first?.value == "grace@example.com")
        #expect(contact.phoneNumbers?.first?.value == "555-0101")
        #expect(contact.address?.city == "Lisbon")
    }

    @Test("Falls back after decoder failure and still inserts fallback models")
    func fallsBackAfterDecoderFailureAndInsertsFallbackModels() async throws {
        let decoder = FakeYAMLDecoder(error: FakeYAMLDecoderError.requestedFailure)
        let store = OCKStore(name: "StaticCareKitViewModelFallbackTests-\(UUID().uuidString)", type: .inMemory)

        let model = StaticCareKitViewModel(decoder: decoder, ockStore: store)

        let task = try await waitForStaticCareKitTask(in: store, id: StaticTask.fallback.id)
        let contact = try await waitForStaticCareKitContact(in: store, id: StaticContact.fallback.id)

        #expect(decoder.decodedFiles == ["StaticCareKitConfiguration"])
        #expect(model.config.version == StaticCareKitConfiguration.fallback.version)
        #expect(task.title == StaticTask.fallback.title.localized)
        #expect(contact.name.givenName == StaticContact.fallback.name)
        #expect(contact.name.familyName == StaticContact.fallback.surname)
    }
}

@Suite("Configuration raw migration")
struct ConfigurationRawMigrationTests {
    @Test("App configuration migrates partial raw values and fills missing defaults")
    func appConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawAppConfiguration.self, from: [
            "version": "2.0.0",
            "apiKey": "custom.api.key",
            "useCareKit": false,
            "scheduleTitle": localized("Care Plan")
        ])

        let config = AppConfiguration(from: raw)

        #expect(config.apiKey == "custom.api.key")
        #expect(!config.useCareKit)
        #expect(config.scheduleTitle.localized == "Care Plan")
        #expect(config.teamEmail == AppConfiguration.fallback.teamEmail)
        #expect(config.profileSymbol == AppConfiguration.fallback.profileSymbol)
        #expect(config.enableLocation == AppConfiguration.fallback.enableLocation)
        #expect(config.enableConditions == AppConfiguration.fallback.enableConditions)
    }

    @Test("Contacts configuration migrates partial raw values and fills missing defaults")
    func contactsConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawContactsConfiguration.self, from: [
            "version": "2.0.0",
            "navTitle": localized("Care Team"),
            "emptySymbol": "person.crop.circle"
        ])

        let config = ContactsConfiguration(from: raw)

        #expect(config.navTitle.localized == "Care Team")
        #expect(config.emptySymbol == "person.crop.circle")
        #expect(config.emptyTitle.localized == ContactsConfiguration.fallback.emptyTitle.localized)
        #expect(config.okayActionTitle.localized == ContactsConfiguration.fallback.okayActionTitle.localized)
    }

    @Test("Schedule configuration migrates partial raw values and fills missing defaults")
    func scheduleConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawScheduleConfiguration.self, from: [
            "version": "2.0.0",
            "todayLabel": localized("Jump"),
            "useDynamicCalendarSymbol": false
        ])

        let config = ScheduleConfiguration(from: raw)

        #expect(config.todayLabel.localized == "Jump")
        #expect(!config.useDynamicCalendarSymbol)
        #expect(config.navTitle.localized == ScheduleConfiguration.fallback.navTitle.localized)
        #expect(config.deletedAlertMessage.localized == ScheduleConfiguration.fallback.deletedAlertMessage.localized)
    }

    @Test("Onboarding configuration falls back to default pages when raw pages are empty")
    func onboardingConfigurationUsesDefaultPagesWhenRawPagesAreEmpty() throws {
        let raw = try decodeRaw(RawOnboardingConfiguration.self, from: [
            "version": "2.0.0",
            "pages": [],
            "primaryButtonTitle": localized("Begin")
        ])

        let config = OnboardingConfiguration(from: raw)

        #expect(config.primaryButtonTitle.localized == "Begin")
        #expect(config.pages.count == OnboardingConfiguration.fallback.pages.count)
        #expect(
            config.secondaryButtonTitle.localized == OnboardingConfiguration.fallback.secondaryButtonTitle.localized
        )
    }

    @Test("Onboarding configuration migrates nonempty pages and button styling")
    func onboardingConfigurationMigratesNonemptyPagesAndButtonStyling() throws {
        let raw = try decodeRaw(RawOnboardingConfiguration.self, from: [
            "version": "2.1.0",
            "pages": [
                [
                    "illustration": "custom_welcome",
                    "title": localized("Start Here"),
                    "subtitle": localized("A focused onboarding page.")
                ],
                [
                    "title": localized("Fallback Art")
                ]
            ],
            "primaryButtonTitle": localized("Create Account"),
            "secondaryButtonTitle": localized("I Have an Account")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try OnboardingConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.1.0")
        #expect(config.pages.count == 2)
        #expect(config.pages.first?.illustration == "custom_welcome")
        #expect(config.pages.first?.title.localized == "Start Here")
        #expect(config.pages.first?.subtitle.localized == "A focused onboarding page.")
        #expect(config.pages.last?.illustration == OnboardingPage.fallbackWelcome.illustration)
        #expect(config.pages.last?.title.localized == "Fallback Art")
        #expect(config.primaryButtonTitle.localized == "Create Account")
        #expect(config.secondaryButtonTitle.localized == "I Have an Account")
        #expect(config.primaryButtonBackgroundColor == OnboardingConfiguration.fallback.primaryButtonBackgroundColor)
        #expect(config.secondaryButtonTitleColor == OnboardingConfiguration.fallback.secondaryButtonTitleColor)
    }

    @Test("CheckUp configuration migrates partial raw values and fills missing defaults")
    func checkUpConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawCheckUpConfiguration.self, from: [
            "version": "2.1.0",
            "navigationTitle": localized("Daily Review"),
            "rowActivitiesTitle": localized("Movement"),
            "rowActivitiesLineWidth": 7.5
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try CheckUpConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.1.0")
        #expect(config.navigationTitle.localized == "Daily Review")
        #expect(config.rowActivitiesTitle.localized == "Movement")
        #expect(config.rowActivitiesLineWidth == 7.5)
        #expect(config.sectionHeaderTitle.localized == CheckUpConfiguration.fallback.sectionHeaderTitle.localized)
        #expect(config.rowMedicationsLineWidth == CheckUpConfiguration.fallback.rowMedicationsLineWidth)
        #expect(config.alertOkButtonTitle.localized == CheckUpConfiguration.fallback.alertOkButtonTitle.localized)
    }

    @Test("Log configuration migrates partial raw values and fills missing defaults")
    func logConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawLogConfiguration.self, from: [
            "version": "1.2.0",
            "featureTitle": localized("Device Diagnostics"),
            "rowsMaxLines": 8
        ])
        let version = try #require(OTFSemanticVersion(string: "1.0.0"))

        let config = try LogConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "1.2.0")
        #expect(config.featureTitle.localized == "Device Diagnostics")
        #expect(config.rowsMaxLines == 8)
        #expect(config.navTitle.localized == LogConfiguration.fallback.navTitle.localized)
        #expect(config.copyTitle.localized == LogConfiguration.fallback.copyTitle.localized)
        #expect(config.defaultDaysBack == LogConfiguration.fallback.defaultDaysBack)
    }

    @Test("Update user profile configuration migrates partial raw values and fills missing defaults")
    func updateUserProfileConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawUpdateUserProfileConfiguration.self, from: [
            "version": "2.4.0",
            "navTitle": localized("Account"),
            "removePhotoTitle": localized("Delete Photo")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try UpdateUserProfileConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.4.0")
        #expect(config.navTitle.localized == "Account")
        #expect(config.removePhotoTitle.localized == "Delete Photo")
        #expect(config.personalInfoTitle.localized == UpdateUserProfileConfiguration.fallback.personalInfoTitle.localized)
        #expect(config.chooseFromPhotosTitle.localized == UpdateUserProfileConfiguration.fallback.chooseFromPhotosTitle.localized)
        #expect(config.cancelTitle.localized == UpdateUserProfileConfiguration.fallback.cancelTitle.localized)
        #expect(config.healthProfileTitle.localized == UpdateUserProfileConfiguration.fallback.healthProfileTitle.localized)
        #expect(config.healthProfilePrivacyNotice.localized == UpdateUserProfileConfiguration.fallback.healthProfilePrivacyNotice.localized)
        #expect(config.healthProfilePrivacyNotice.localized.contains("minimum location detail"))
        #expect(config.healthProfilePrivacyNotice.localized.contains("GPS"))
        #expect(config.profileSaveErrorMessage.localized == UpdateUserProfileConfiguration.fallback.profileSaveErrorMessage.localized)
        #expect(config.locationDisplayNameLabel.localized == "Country")
        #expect(config.cityLabel.localized == "City")
        #expect(config.countryCodePlaceholder.localized == "Enter calling code, for example +351")
        #expect(config.conditionsUnknownText.localized == "Not sure")
        #expect(config.conditionLabels.count == 20)
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        #expect(config.conditionLabel(for: asthma) == "Asthma")
        #expect(!config.profileSaveErrorMessage.localized.contains(asthma.code))
    }

    @Test("Update user profile condition labels use configured text and canonical fallback")
    func updateUserProfileConditionLabelsUseConfiguredTextAndCanonicalFallback() throws {
        let asthma = try #require(HealthProfileConditionCatalogue.condition(withCode: "195967001"))
        let configuredRaw = try decodeRaw(RawUpdateUserProfileConfiguration.self, from: [
            "conditionLabels": [
                asthma.code: localized("Configured asthma label")
            ]
        ])
        let misconfiguredRaw = try decodeRaw(RawUpdateUserProfileConfiguration.self, from: [
            "conditionLabels": [:]
        ])

        #expect(UpdateUserProfileConfiguration(from: configuredRaw).conditionLabel(for: asthma) == "Configured asthma label")
        #expect(UpdateUserProfileConfiguration(from: misconfiguredRaw).conditionLabel(for: asthma) == asthma.name)
    }

    @Test("Health sensors configuration migrates partial raw values and fills missing defaults")
    func healthSensorsConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawHealthSensorsConfiguration.self, from: [
            "version": "2.4.0",
            "title": localized("Vitals"),
            "statusLive": localized("Streaming"),
            "buttonGrantAccess": localized("Allow Health"),
            "cardTitleHeartRate": localized("Pulse"),
            "guidanceHeartRateStep1": localized("Wear your watch")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try HealthSensorsConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.4.0")
        #expect(config.title.localized == "Vitals")
        #expect(config.statusLive.localized == "Streaming")
        #expect(config.buttonGrantAccess.localized == "Allow Health")
        #expect(config.cardTitleHeartRate.localized == "Pulse")
        #expect(config.guidanceHeartRateStep1.localized == "Wear your watch")
        #expect(config.menuSettings.localized == HealthSensorsConfiguration.fallback.menuSettings.localized)
        #expect(config.unitVO2Max.localized == HealthSensorsConfiguration.fallback.unitVO2Max.localized)
        #expect(
            config.guidanceOxygenSaturationStep3.localized ==
                HealthSensorsConfiguration.fallback.guidanceOxygenSaturationStep3.localized
        )
    }

    @Test("Profile configuration migrates partial raw values and fills missing defaults")
    func profileConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawProfileConfiguration.self, from: [
            "version": "2.5.0",
            "navTitle": localized("Account"),
            "logoutButtonTitle": localized("Sign Out"),
            "deleteAccountConfirmActionTitle": localized("Remove Account")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try ProfileConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.5.0")
        #expect(config.navTitle.localized == "Account")
        #expect(config.logoutButtonTitle.localized == "Sign Out")
        #expect(config.deleteAccountConfirmActionTitle.localized == "Remove Account")
        #expect(config.sectionSupportTitle.localized == ProfileConfiguration.fallback.sectionSupportTitle.localized)
        #expect(config.privacyPolicyTitle.localized == ProfileConfiguration.fallback.privacyPolicyTitle.localized)
        #expect(config.termsOfServiceTitle.localized == ProfileConfiguration.fallback.termsOfServiceTitle.localized)
    }

    @Test("Change password configuration migrates partial raw values and fills missing defaults")
    func changePasswordConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawChangePasswordConfiguration.self, from: [
            "version": "2.2.0",
            "navTitle": localized("Security"),
            "resetButtonTitle": localized("Update Password")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try ChangePasswordConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.2.0")
        #expect(config.navTitle.localized == "Security")
        #expect(config.resetButtonTitle.localized == "Update Password")
        #expect(config.emailLabel.localized == ChangePasswordConfiguration.fallback.emailLabel.localized)
        #expect(config.failureAlertTitle.localized == ChangePasswordConfiguration.fallback.failureAlertTitle.localized)
    }

    @Test("Legal configurations migrate content and preserve fallback defaults")
    func legalConfigurationsMigrateContentAndPreserveFallbackDefaults() throws {
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))
        let privacyRaw = try decodeRaw(RawPrivacyPolicyConfiguration.self, from: [
            "version": "2.1.0",
            "content": localized("Privacy copy")
        ])
        let termsRaw = try decodeRaw(RawTermsOfServiceConfiguration.self, from: [
            "content": localized("Terms copy")
        ])

        let privacy = try PrivacyPolicyConfiguration.migrate(from: version, raw: privacyRaw)
        let terms = try TermsOfServiceConfiguration.migrate(from: version, raw: termsRaw)

        #expect(privacy.version == "2.1.0")
        #expect(privacy.content.localized == "Privacy copy")
        #expect(PrivacyPolicyConfiguration.fallback.content.localized.contains("self-reported"))
        #expect(PrivacyPolicyConfiguration.fallback.content.localized.contains("GPS"))
        #expect(PrivacyPolicyConfiguration.fallback.content.localized.contains("not confirmation"))
        #expect(PrivacyPolicyConfiguration.fallback.content.localized.contains("security"))
        #expect(terms.version == TermsOfServiceConfiguration.fallback.version)
        #expect(terms.content.localized == "Terms copy")
    }

    @Test("UI Lab configuration migrates raw values and fills missing defaults")
    func uiLabConfigurationMigratesRawValuesAndFillsMissingDefaults() throws {
        let raw = try decodeRaw(RawUILabConfiguration.self, from: [
            "version": "2.9.0",
            "uiTitle": localized("Lab"),
            "uiLabCareKit": localized("Care"),
            "uiLabResearchKit": localized("Research"),
            "uiLabCoreMotion": localized("Motion"),
            "uiLabHealthSensors": localized("Sensors"),
            "uiLabPlayground": localized("Play"),
            "uiLabPlaygroundStep": localized("Steps"),
            "uiLabPlaygroundAnswer": localized("Answers"),
            "uiLabPlatform": localized("Device"),
            "uiLabContact": localized("Contact"),
            "uiLabTask": localized("Task"),
            "uiLabNumericProgress": localized("Progress"),
            "uiLabLabeledValue": localized("Value"),
            "uiLabOtherTasks": localized("Other"),
            "uiLabStyleSimple": localized("Simple"),
            "uiLabStyleDetailed": localized("Detailed"),
            "uiLabStyleInstruction": localized("Instruction"),
            "uiLabStyleButtonLog": localized("Button"),
            "uiLabStyleGrid": localized("Grid"),
            "uiLabStyleChecklist": localized("Checklist"),
            "uiLabProgrammatic": localized("Code"),
            "uiLabYMLDriven": localized("YAML"),
            "uiLabAccountDeleted": localized("Deleted"),
            "uiLabAccountDeletedMessage": localized("Removed elsewhere")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try UILabConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.9.0")
        #expect(config.uiTitle.localized == "Lab")
        #expect(config.uiLabCareKit.localized == "Care")
        #expect(config.uiLabResearchKit.localized == "Research")
        #expect(config.uiLabCoreMotion.localized == "Motion")
        #expect(config.uiLabHealthSensors.localized == "Sensors")
        #expect(config.uiLabPlayground.localized == "Play")
        #expect(config.uiLabPlaygroundStep.localized == "Steps")
        #expect(config.uiLabPlaygroundAnswer.localized == "Answers")
        #expect(config.uiLabPlatform.localized == "Device")
        #expect(config.uiLabSwiftUI.localized == UILabConfiguration.fallback.uiLabSwiftUI.localized)
        #expect(config.uiLabUIKit.localized == UILabConfiguration.fallback.uiLabUIKit.localized)
        #expect(config.uiLabContact.localized == "Contact")
        #expect(config.uiLabTask.localized == "Task")
        #expect(config.uiLabNumericProgress.localized == "Progress")
        #expect(config.uiLabLabeledValue.localized == "Value")
        #expect(config.uiLabOtherTasks.localized == "Other")
        #expect(config.uiLabStyleSimple.localized == "Simple")
        #expect(config.uiLabStyleDetailed.localized == "Detailed")
        #expect(config.uiLabStyleInstruction.localized == "Instruction")
        #expect(config.uiLabStyleButtonLog.localized == "Button")
        #expect(config.uiLabStyleGrid.localized == "Grid")
        #expect(config.uiLabStyleChecklist.localized == "Checklist")
        #expect(config.uiLabProgrammatic.localized == "Code")
        #expect(config.uiLabYMLDriven.localized == "YAML")
        #expect(config.uiLabAccountDeleted.localized == "Deleted")
        #expect(config.uiLabAccountDeletedMessage.localized == "Removed elsewhere")
    }

    @Test("Sensor task configuration migrates partial raw values and fills missing defaults")
    func sensorTaskConfigurationMigratesPartialRawValues() throws {
        let raw = try decodeRaw(RawSensorTaskConfiguration.self, from: [
            "version": "2.6.0",
            "sentLabel": localized("Result sent"),
            "taskTitleHeartRate": localized("Share pulse"),
            "taskInstructionsVO2Max": localized("Review cardio fitness")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try SensorTaskConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.6.0")
        #expect(config.sentLabel.localized == "Result sent")
        #expect(config.taskTitleHeartRate.localized == "Share pulse")
        #expect(config.taskInstructionsVO2Max.localized == "Review cardio fitness")
        #expect(config.pendingLabel.localized == SensorTaskConfiguration.fallback.pendingLabel.localized)
        #expect(config.taskTitleBloodPressure.localized == SensorTaskConfiguration.fallback.taskTitleBloodPressure.localized)
    }

    @Test("Sensor task configuration maps every metric title and instruction fallback")
    func sensorTaskConfigurationMapsEveryMetricTitleAndInstructionFallback() throws {
        let raw = try decodeRaw(RawSensorTaskConfiguration.self, from: [
            "version": "3.2.0",
            "taskTitleHeartRate": localized("Pulse"),
            "taskTitleBloodGlucose": localized("Glucose"),
            "taskTitleBloodPressure": localized("Pressure"),
            "taskTitleECG": localized("ECG Review"),
            "taskTitleRespiratoryRate": localized("Breathing"),
            "taskTitleRestingHeartRate": localized("Resting Pulse"),
            "taskTitleOxygenSaturation": localized("Oxygen"),
            "taskTitleVO2Max": localized("Cardio Fitness"),
            "taskInstructionsHeartRate": localized("Review pulse")
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try SensorTaskConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "3.2.0")
        #expect(config.taskTitleHeartRate.localized == "Pulse")
        #expect(config.taskTitleBloodGlucose.localized == "Glucose")
        #expect(config.taskTitleBloodPressure.localized == "Pressure")
        #expect(config.taskTitleECG.localized == "ECG Review")
        #expect(config.taskTitleRespiratoryRate.localized == "Breathing")
        #expect(config.taskTitleRestingHeartRate.localized == "Resting Pulse")
        #expect(config.taskTitleOxygenSaturation.localized == "Oxygen")
        #expect(config.taskTitleVO2Max.localized == "Cardio Fitness")
        #expect(config.taskInstructionsHeartRate.localized == "Review pulse")
        #expect(config.taskInstructionsBloodGlucose.localized == SensorTaskConfiguration.fallback.taskInstructionsBloodGlucose.localized)
        #expect(config.sentValueFormat.localized == SensorTaskConfiguration.fallback.sentValueFormat.localized)
    }

    @Test("Static ResearchKit configuration falls back for missing and empty nested arrays")
    func staticResearchKitConfigurationFallsBackForMissingAndEmptyNestedArrays() throws {
        let missingSectionsRaw = try decodeRaw(RawStaticResearchKitConfiguration.self, from: [
            "version": "3.0.0"
        ])
        let emptySectionRaw = try decodeRaw(RawStaticResearchKitConfiguration.self, from: [
            "version": "3.0.1",
            "sections": [
                [
                    "title": localized("Empty Section"),
                    "tasks": []
                ]
            ]
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let missingSections = try StaticResearchKitConfiguration.migrate(from: version, raw: missingSectionsRaw)
        let emptySection = try StaticResearchKitConfiguration.migrate(from: version, raw: emptySectionRaw)

        #expect(missingSections.version == "3.0.0")
        #expect(missingSections.sections.map(\.title.localized) == StaticResearchKitConfiguration.fallback.sections.map(\.title.localized))
        #expect(emptySection.sections.map(\.title.localized) == ["Empty Section"])
        #expect(emptySection.sections.first?.tasks.map(\.configFileName) == StaticResearchKitSection.fallback.tasks.map(\.configFileName))
    }

    @Test("Static ResearchKit configuration migrates nested section and page values")
    func staticResearchKitConfigurationMigratesNestedSectionAndPageValues() throws {
        let raw = try decodeRaw(RawStaticResearchKitConfiguration.self, from: [
            "version": "3.1.0",
            "sections": [
                [
                    "title": localized("Surveys"),
                    "tasks": [
                        [
                            "title": localized("Morning Check"),
                            "configFileName": "morning_check"
                        ],
                        [
                            "title": localized("Fallback File")
                        ]
                    ]
                ]
            ]
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try StaticResearchKitConfiguration.migrate(from: version, raw: raw)
        let section = try #require(config.sections.first)

        #expect(config.version == "3.1.0")
        #expect(section.id == "Surveys")
        #expect(section.tasks.map(\.id) == ["Morning Check", "Fallback File"])
        #expect(section.tasks.map(\.configFileName) == ["morning_check", StaticResearchKitPage.fallback.configFileName])
    }

    @Test("Static CareKit configuration migrates nested raw values and fills missing defaults")
    func staticCareKitConfigurationMigratesNestedRawValues() throws {
        let raw = try decodeRaw(RawStaticCareKitConfiguration.self, from: [
            "version": "2.7.0",
            "contact": [
                "name": "Ada",
                "surname": "Lovelace",
                "role": localized("Researcher"),
                "address": [
                    "city": "Lisbon"
                ]
            ],
            "task": [
                "id": "walk",
                "title": localized("Walk"),
                "schedules": [
                    [
                        "startHour": 10,
                        "text": localized("Morning")
                    ]
                ]
            ],
            "numericProgress": [
                "title": [
                    "text": "Steps"
                ],
                "isComplete": true
            ],
            "labeledValue": [
                "state": [
                    "type": "unknown",
                    "value": [
                        "text": "88"
                    ]
                ]
            ]
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try StaticCareKitConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.7.0")
        #expect(config.contact.name == "Ada")
        #expect(config.contact.id == "AdaLovelace")
        #expect(config.contact.role.localized == "Researcher")
        #expect(config.contact.address.city == "Lisbon")
        #expect(config.contact.address.street == StaticAddress.fallback.street)
        #expect(config.task.id == "walk")
        #expect(config.task.title.localized == "Walk")
        #expect(config.task.schedules.first?.startHour == 10)
        #expect(config.task.schedules.first?.intervalDay == StaticTaskSchedule.fallback.intervalDay)
        #expect(config.numericProgress.title.text == "Steps")
        #expect(config.numericProgress.isComplete)
        #expect(config.labeledValue.state.value.text == "88")
        #expect(config.labeledValue.state.state == .incomplete)
        #expect(config.labeledValue.detail.text == StaticLabeledValue.fallback.detail.text)
    }
}

@Suite("Root destination mapping")
struct RootDestinationMappingTests {
    @Test(
        "Root destinations use configured titles and symbols",
        arguments: [
            (RootDestination.schedule, "Care Plan", "calendar.badge.clock"),
            (.contacts, "Care Team", "person.2"),
            (.checkup, "Review", "checkmark.seal"),
            (.ui, "Lab", "rectangle.3.group"),
            (.profile, "Account", "person.crop.circle"),
            (.playground, "Sandbox", "hammer")
        ]
    )
    func rootDestinationsUseConfiguredTitlesAndSymbols(
        destination: RootDestination,
        expectedTitle: String,
        expectedSymbol: String
    ) {
        let config = makeAppConfiguration(
            scheduleTitle: "Care Plan",
            contactsTitle: "Care Team",
            checkupTitle: "Review",
            uiTitle: "Lab",
            profileTitle: "Account",
            playgroundTitle: "Sandbox",
            scheduleSymbol: "calendar.badge.clock",
            contactsSymbol: "person.2",
            checkupSymbol: "checkmark.seal",
            playgroundSymbol: "hammer",
            uiSymbol: "rectangle.3.group",
            profileSymbol: "person.crop.circle"
        )

        #expect(destination.title(from: config) == expectedTitle)
        #expect(destination.symbol(from: config) == expectedSymbol)
    }

    @Test("Root destination case order remains stable for tab routing")
    func rootDestinationCaseOrderRemainsStableForTabRouting() {
        #expect(RootDestination.allCases == [.schedule, .contacts, .checkup, .ui, .profile, .playground])
        #expect(RootDestination.allCases.map(\.id) == RootDestination.allCases)
    }
}

private enum FakeYAMLDecoderError: Error {
    case requestedFailure
    case missingStub(String)
    case typeMismatch(file: String, expectedType: Any.Type)
}

private final class FakeYAMLDecoder: OTFYAMLDecoding {
    private let stubs: [String: Any]
    private let error: Error?
    private(set) var decodedFiles: [String] = []

    init(stubs: [String: Any] = [:], error: Error? = nil) {
        self.stubs = stubs
        self.error = error
    }

    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        decodedFiles.append(file)

        if let error {
            throw error
        }
        guard let value = stubs[file] else {
            throw FakeYAMLDecoderError.missingStub(file)
        }
        guard let typedValue = value as? T else {
            throw FakeYAMLDecoderError.typeMismatch(file: file, expectedType: T.self)
        }
        return typedValue
    }
}

private let fixedCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

private func fixedDate(day: Int) throws -> Date {
    let components = DateComponents(
        calendar: fixedCalendar,
        timeZone: fixedCalendar.timeZone,
        year: 2026,
        month: 5,
        day: day,
        hour: 9
    )
    return try #require(fixedCalendar.date(from: components))
}

private func decodeRaw<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: dictionary)
    return try JSONDecoder().decode(T.self, from: data)
}

private func localized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}

private func makeOnboardingConfiguration(
    primaryButtonTitle: OTFStringLocalized = "Sign Up"
) -> OnboardingConfiguration {
    OnboardingConfiguration(
        version: "2.0.0",
        pages: OnboardingConfiguration.fallback.pages,
        primaryButtonTitle: primaryButtonTitle,
        primaryButtonBackgroundColor: .label,
        primaryButtonTitleColor: .systemBackground,
        secondaryButtonTitle: "Sign In",
        secondaryButtonBackgroundColor: .blue,
        secondaryButtonTitleColor: .white
    )
}

private func makeContactsConfiguration(
    navTitle: OTFStringLocalized = "Contacts",
    emptySymbol: String = "person.3"
) -> ContactsConfiguration {
    ContactsConfiguration(
        version: "2.0.0",
        navTitle: navTitle,
        emptyTitle: "No contacts yet",
        emptyDescription: "Your care team will appear here once added.",
        emptySymbol: emptySymbol,
        deletedAlertTitle: "Account Deleted",
        deletedAlertMessage: "Your account was deleted. You'll be returned to onboarding.",
        okayActionTitle: "OK"
    )
}

private func makeScheduleConfiguration(
    navTitle: OTFStringLocalized = "Schedule",
    todayLabel: OTFStringLocalized = "Today",
    useDynamicCalendarSymbol: Bool = true,
    emptyDayTitle: OTFStringLocalized = "No tasks",
    emptyDaySubtitle: OTFStringLocalized = "No tasks scheduled for this date.",
    deletedAlertTitle: OTFStringLocalized = "Account Deleted",
    deletedAlertMessage: OTFStringLocalized = "Your account was deleted. You'll be returned to onboarding."
) -> ScheduleConfiguration {
    ScheduleConfiguration(
        version: "2.0.0",
        navTitle: navTitle,
        todayLabel: todayLabel,
        useDynamicCalendarSymbol: useDynamicCalendarSymbol,
        showLeadingTodayButton: true,
        emptyDayTitle: emptyDayTitle,
        emptyDaySubtitle: emptyDaySubtitle,
        deletedAlertTitle: deletedAlertTitle,
        deletedAlertMessage: deletedAlertMessage
    )
}

private func makeStaticCareKitConfiguration() -> StaticCareKitConfiguration {
    StaticCareKitConfiguration(
        version: "2.0.0",
        contact: StaticContact(
            version: "2.0.0",
            name: "Grace",
            surname: "Hopper",
            asset: "stethoscope",
            role: "Nurse",
            title: "RN",
            email: "grace@example.com",
            phoneNumber: "555-0101",
            address: StaticAddress(
                street: "Care Street",
                city: "Lisbon",
                postalCode: "1000",
                state: "Lisbon"
            )
        ),
        task: StaticTask(
            id: "hydration",
            title: "Hydration",
            instructions: "Drink water with breakfast.",
            asset: "drop",
            impactsAdherence: true,
            schedules: [
                StaticTaskSchedule(
                    startHour: 8,
                    intervalDay: 1,
                    text: "Morning"
                )
            ]
        ),
        numericProgress: .fallback,
        labeledValue: .fallback
    )
}

private func waitForStaticCareKitTask(in store: OCKStore, id: String) async throws -> OCKTask {
    for _ in 0..<100 {
        if let task = try await fetchStaticCareKitTasks(in: store).first(where: { $0.id == id }) {
            return task
        }
        try await Task.sleep(nanoseconds: 10_000_000)
    }
    return try #require(try await fetchStaticCareKitTasks(in: store).first(where: { $0.id == id }))
}

private func waitForStaticCareKitContact(in store: OCKStore, id: String) async throws -> OCKContact {
    for _ in 0..<100 {
        if let contact = try await fetchStaticCareKitContacts(in: store).first(where: { $0.id == id }) {
            return contact
        }
        try await Task.sleep(nanoseconds: 10_000_000)
    }
    return try #require(try await fetchStaticCareKitContacts(in: store).first(where: { $0.id == id }))
}

private func fetchStaticCareKitTasks(in store: OCKStore) async throws -> [OCKTask] {
    let result = await withCheckedContinuation { continuation in
        store.fetchTasks(query: OCKTaskQuery(), callbackQueue: .main) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let tasks):
        return tasks
    case .failure(let error):
        throw error
    }
}

private func fetchStaticCareKitContacts(in store: OCKStore) async throws -> [OCKContact] {
    let result = await withCheckedContinuation { continuation in
        store.fetchContacts(query: OCKContactQuery(), callbackQueue: .main) { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .success(let contacts):
        return contacts
    case .failure(let error):
        throw error
    }
}
