/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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

import UIKit
import SwiftUI
import OTFCareKit
import OTFCareKitStore

enum TaskStyle: String, CaseIterable, Codable, Identifiable {

    case simple, instruction, buttonLog, grid, checklist

    var id: String { rawValue }

    var title: String {
        let config = UILabConfigurationLoader.config
        return switch self {
        case .simple: config.uiLabStyleSimple.localized
        case .instruction: config.uiLabStyleInstruction.localized
        case .buttonLog: config.uiLabStyleButtonLog.localized
        case .grid: config.uiLabStyleGrid.localized
        case .checklist: config.uiLabStyleChecklist.localized
        }
    }

    var supportsSwiftUI: Bool {
        switch self {
        case .simple, .instruction: return true
        default: return false
        }
    }

    func uiKitViewController(for task: StaticTask, and date: Date, storeManager: OCKSynchronizedStoreManager) -> UIViewController {
        switch self {
        case .simple: OCKSimpleTaskViewController(taskID: task.id, eventQuery: .init(for: date), storeManager: storeManager)
        case .instruction: OCKInstructionsTaskViewController(taskID: task.id, eventQuery: .init(for: date), storeManager: storeManager)
        case .buttonLog: OCKButtonLogTaskViewController(taskID: task.id, eventQuery: .init(for: date), storeManager: storeManager)
        case .checklist: OCKChecklistTaskViewController(taskID: task.id, eventQuery: .init(for: date), storeManager: storeManager)
        case .grid: OCKGridTaskViewController(taskID: task.id, eventQuery: .init(for: date), storeManager: storeManager)
        }
    }
}
