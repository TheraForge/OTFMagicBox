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
import OTFTemplateBox
import RawModel

@RawGenerable
struct UILabConfiguration: Codable {
    let version: String

    // UI Lab Main Title
    let uiTitle: OTFStringLocalized

    // UI Lab Categories
    let uiLabCareKit: OTFStringLocalized
    let uiLabResearchKit: OTFStringLocalized
    let uiLabCoreMotion: OTFStringLocalized
    let uiLabHealthSensors: OTFStringLocalized
    let uiLabPlayground: OTFStringLocalized
    let uiLabPlaygroundStep: OTFStringLocalized
    let uiLabPlaygroundAnswer: OTFStringLocalized
    let uiLabPlatform: OTFStringLocalized
    let uiLabUIKit: OTFStringLocalized
    let uiLabSwiftUI: OTFStringLocalized

    // CareKit View Types
    let uiLabContact: OTFStringLocalized
    let uiLabTask: OTFStringLocalized
    let uiLabNumericProgress: OTFStringLocalized
    let uiLabLabeledValue: OTFStringLocalized
    let uiLabOtherTasks: OTFStringLocalized

    // Styles
    let uiLabStyleSimple: OTFStringLocalized
    let uiLabStyleDetailed: OTFStringLocalized
    let uiLabStyleInstruction: OTFStringLocalized
    let uiLabStyleButtonLog: OTFStringLocalized
    let uiLabStyleGrid: OTFStringLocalized
    let uiLabStyleChecklist: OTFStringLocalized

    // ResearchKit Options
    let uiLabProgrammatic: OTFStringLocalized
    let uiLabYMLDriven: OTFStringLocalized

    // General Messages
    let uiLabAccountDeleted: OTFStringLocalized
    let uiLabAccountDeletedMessage: OTFStringLocalized
}

extension UILabConfiguration: OTFVersionedDecodable {
    typealias Raw = RawUILabConfiguration

    static let fallback = UILabConfiguration(
        version: "2.0.0",
        uiTitle: "UI Lab",
        uiLabCareKit: "CareKit",
        uiLabResearchKit: "ResearchKit",
        uiLabCoreMotion: "CoreMotion",
        uiLabHealthSensors: "Health Sensors",
        uiLabPlayground: "Playground",
        uiLabPlaygroundStep: "Step",
        uiLabPlaygroundAnswer: "Answer",
        uiLabPlatform: "Platform",
        uiLabUIKit: "UIKit",
        uiLabSwiftUI: "SwiftUI",
        uiLabContact: "Contact",
        uiLabTask: "Task",
        uiLabNumericProgress: "Numeric Progress",
        uiLabLabeledValue: "Labeled Value",
        uiLabOtherTasks: "Other Tasks",
        uiLabStyleSimple: "Simple",
        uiLabStyleDetailed: "Detailed",
        uiLabStyleInstruction: "Instruction",
        uiLabStyleButtonLog: "Button Log",
        uiLabStyleGrid: "Grid",
        uiLabStyleChecklist: "Checklist",
        uiLabProgrammatic: "Programmatic",
        uiLabYMLDriven: "YML Driven",
        uiLabAccountDeleted: "Account Deleted",
        uiLabAccountDeletedMessage: "Your account is deleted from one of your device"
    )

    init(from raw: RawUILabConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.uiTitle = raw.uiTitle ?? fallback.uiTitle
        self.uiLabCareKit = raw.uiLabCareKit ?? fallback.uiLabCareKit
        self.uiLabResearchKit = raw.uiLabResearchKit ?? fallback.uiLabResearchKit
        self.uiLabCoreMotion = raw.uiLabCoreMotion ?? fallback.uiLabCoreMotion
        self.uiLabHealthSensors = raw.uiLabHealthSensors ?? fallback.uiLabHealthSensors
        self.uiLabPlayground = raw.uiLabPlayground ?? fallback.uiLabPlayground
        self.uiLabPlaygroundStep = raw.uiLabPlaygroundStep ?? fallback.uiLabPlaygroundStep
        self.uiLabPlaygroundAnswer = raw.uiLabPlaygroundAnswer ?? fallback.uiLabPlaygroundAnswer
        self.uiLabPlatform = raw.uiLabPlatform ?? fallback.uiLabPlatform
        self.uiLabUIKit = raw.uiLabUIKit ?? fallback.uiLabUIKit
        self.uiLabSwiftUI = raw.uiLabSwiftUI ?? fallback.uiLabSwiftUI
        self.uiLabContact = raw.uiLabContact ?? fallback.uiLabContact
        self.uiLabTask = raw.uiLabTask ?? fallback.uiLabTask
        self.uiLabNumericProgress = raw.uiLabNumericProgress ?? fallback.uiLabNumericProgress
        self.uiLabLabeledValue = raw.uiLabLabeledValue ?? fallback.uiLabLabeledValue
        self.uiLabOtherTasks = raw.uiLabOtherTasks ?? fallback.uiLabOtherTasks
        self.uiLabStyleSimple = raw.uiLabStyleSimple ?? fallback.uiLabStyleSimple
        self.uiLabStyleDetailed = raw.uiLabStyleDetailed ?? fallback.uiLabStyleDetailed
        self.uiLabStyleInstruction = raw.uiLabStyleInstruction ?? fallback.uiLabStyleInstruction
        self.uiLabStyleButtonLog = raw.uiLabStyleButtonLog ?? fallback.uiLabStyleButtonLog
        self.uiLabStyleGrid = raw.uiLabStyleGrid ?? fallback.uiLabStyleGrid
        self.uiLabStyleChecklist = raw.uiLabStyleChecklist ?? fallback.uiLabStyleChecklist
        self.uiLabProgrammatic = raw.uiLabProgrammatic ?? fallback.uiLabProgrammatic
        self.uiLabYMLDriven = raw.uiLabYMLDriven ?? fallback.uiLabYMLDriven
        self.uiLabAccountDeleted = raw.uiLabAccountDeleted ?? fallback.uiLabAccountDeleted
        self.uiLabAccountDeletedMessage = raw.uiLabAccountDeletedMessage ?? fallback.uiLabAccountDeletedMessage
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawUILabConfiguration) throws -> UILabConfiguration {
        UILabConfiguration(from: raw)
    }
}
