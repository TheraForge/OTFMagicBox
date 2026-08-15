/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import Testing
@testable import OTFMagicBox

@Suite("UI Lab domain models")
struct UILabDomainModelTests {
    @Test("Snippet playground type exposes stable cases and identifiers")
    func snippetPlaygroundTypeExposesStableCasesAndIdentifiers() {
        #expect(SnippetPlaygroundType.allCases == [.step, .answer])
        #expect(SnippetPlaygroundType.allCases.map(\.id) == ["step", "answer"])
    }

    @Test("UI Lab view types expose stable route order and UI Lab-owned titles")
    func uiLabViewTypesExposeStableRouteOrderAndUILabOwnedTitles() {
        #expect(UILabViewType.allCases == [
            .careKit,
            .researchKit,
            .coreMotion,
            .healthSensors,
            .healthEducationCenter,
            .playground
        ])
        #expect(UILabViewType.allCases.map(\.id) == [
            "careKit",
            "researchKit",
            "coreMotion",
            "healthSensors",
            "healthEducationCenter",
            "playground"
        ])
        #expect(UILabViewType.allCases.map(\.title) == [
            UILabConfigurationLoader.config.uiLabCareKit.localized,
            UILabConfigurationLoader.config.uiLabResearchKit.localized,
            UILabConfigurationLoader.config.uiLabCoreMotion.localized,
            UILabConfigurationLoader.config.uiLabHealthSensors.localized,
            UILabConfigurationLoader.config.uiLabHealthEducationCenter.localized,
            UILabConfigurationLoader.config.uiLabPlayground.localized
        ])
        #expect(
            UILabViewType.healthEducationCenter.title
                == UILabConfigurationLoader.config.uiLabHealthEducationCenter.localized
        )
    }

    @Test("CareKit style enums expose stable identifiers titles and SwiftUI support")
    func careKitStyleEnumsExposeStableIdentifiersTitlesAndSwiftUISupport() {
        #expect(TaskStyle.allCases == [.simple, .instruction, .buttonLog, .grid, .checklist])
        #expect(TaskStyle.allCases.map(\.id) == ["simple", "instruction", "buttonLog", "grid", "checklist"])
        #expect(TaskStyle.allCases.map(\.title) == [
            UILabConfigurationLoader.config.uiLabStyleSimple.localized,
            UILabConfigurationLoader.config.uiLabStyleInstruction.localized,
            UILabConfigurationLoader.config.uiLabStyleButtonLog.localized,
            UILabConfigurationLoader.config.uiLabStyleGrid.localized,
            UILabConfigurationLoader.config.uiLabStyleChecklist.localized
        ])
        #expect(TaskStyle.allCases.map(\.supportsSwiftUI) == [true, true, false, false, false])

        #expect(OtherTaskType.allCases == [.numericProgress, .labeledValue])
        #expect(OtherTaskType.allCases.map(\.id) == ["numericProgress", "labeledValue"])
        #expect(OtherTaskType.allCases.map(\.title) == [
            UILabConfigurationLoader.config.uiLabNumericProgress.localized,
            UILabConfigurationLoader.config.uiLabLabeledValue.localized
        ])
    }
}
