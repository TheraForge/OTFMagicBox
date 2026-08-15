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

#if !os(watchOS)

import Foundation
import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI
import UIKit

private enum ScheduleTaskMutationSync {
    static func schedule(reason: String) {
        CareKitStoreManager.shared.scheduleCloudantSyncForExplicitLocalMutation(reason: reason)
    }

    static func wrap(
        reason: String,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) -> ((Result<OCKAnyOutcome, Error>) -> Void)? {
        guard let completion else {
            return { result in
                if case .success = result {
                    schedule(reason: reason)
                }
            }
        }

        return { result in
            if case .success = result {
                schedule(reason: reason)
            }
            completion(result)
        }
    }
}

private protocol ScheduleTaskMutationSyncing {}

private extension ScheduleTaskMutationSyncing {
    func scheduleTaskOutcomeMutation(
        reason: String,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) -> ((Result<OCKAnyOutcome, Error>) -> Void)? {
        ScheduleTaskMutationSync.wrap(reason: reason, completion: completion)
    }
}

final class SyncingTaskController: OCKTaskController, ScheduleTaskMutationSyncing {
    override func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        super.setEvent(
            atIndexPath: indexPath,
            isComplete: isComplete,
            completion: scheduleTaskOutcomeMutation(reason: "ios task toggle", completion: completion)
        )
    }

    override func appendOutcomeValue(
        value: OCKOutcomeValueUnderlyingType,
        at indexPath: IndexPath,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) {
        super.appendOutcomeValue(
            value: value,
            at: indexPath,
            completion: scheduleTaskOutcomeMutation(reason: "ios task outcome value", completion: completion)
        )
    }

    override func initiateDeletionForOutcomeValue(
        atIndex index: Int,
        eventIndexPath: IndexPath,
        deletionCompletion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) throws -> UIAlertController {
        try super.initiateDeletionForOutcomeValue(
            atIndex: index,
            eventIndexPath: eventIndexPath,
            deletionCompletion: scheduleTaskOutcomeMutation(reason: "ios task outcome delete", completion: deletionCompletion)
        )
    }
}

final class SyncingSimpleTaskController: OCKSimpleTaskController, ScheduleTaskMutationSyncing {
    override func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        super.setEvent(
            atIndexPath: indexPath,
            isComplete: isComplete,
            completion: scheduleTaskOutcomeMutation(reason: "ios simple task toggle", completion: completion)
        )
    }
}

final class SyncingInstructionsTaskController: OCKInstructionsTaskController, ScheduleTaskMutationSyncing {
    override func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        super.setEvent(
            atIndexPath: indexPath,
            isComplete: isComplete,
            completion: scheduleTaskOutcomeMutation(reason: "ios instructions task toggle", completion: completion)
        )
    }
}

final class SyncingButtonLogTaskController: OCKButtonLogTaskController, ScheduleTaskMutationSyncing {
    override func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        super.setEvent(
            atIndexPath: indexPath,
            isComplete: isComplete,
            completion: scheduleTaskOutcomeMutation(reason: "ios button log toggle", completion: completion)
        )
    }

    override func appendOutcomeValue(
        value: OCKOutcomeValueUnderlyingType,
        at indexPath: IndexPath,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) {
        super.appendOutcomeValue(
            value: value,
            at: indexPath,
            completion: scheduleTaskOutcomeMutation(reason: "ios button log value", completion: completion)
        )
    }

    override func initiateDeletionForOutcomeValue(
        atIndex index: Int,
        eventIndexPath: IndexPath,
        deletionCompletion: ((Result<OCKAnyOutcome, Error>) -> Void)?
    ) throws -> UIAlertController {
        try super.initiateDeletionForOutcomeValue(
            atIndex: index,
            eventIndexPath: eventIndexPath,
            deletionCompletion: scheduleTaskOutcomeMutation(reason: "ios button log delete", completion: deletionCompletion)
        )
    }
}

final class SyncingSimpleTaskViewController: OCKTaskViewController<SyncingSimpleTaskController, OCKSimpleTaskViewSynchronizer> {
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        super.init(viewSynchronizer: .init(), task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SyncingInstructionsTaskViewController: OCKTaskViewController<SyncingInstructionsTaskController, OCKInstructionsTaskViewSynchronizer> {
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        super.init(viewSynchronizer: .init(), task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SyncingButtonLogTaskViewController: OCKTaskViewController<SyncingButtonLogTaskController, OCKButtonLogTaskViewSynchronizer> {
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        super.init(viewSynchronizer: .init(), task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SyncingGridTaskViewController: OCKGridTaskViewController {
    override init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        super.init(task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at indexPath: IndexPath, sender: Any?) {
        super.taskView(taskView, didCompleteEvent: isComplete, at: indexPath, sender: sender)
        ScheduleTaskMutationSync.schedule(reason: "ios grid task toggle")
    }

    override func taskView(_ taskView: UIView & OCKTaskDisplayable, didCreateOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        super.taskView(taskView, didCreateOutcomeValueAt: index, eventIndexPath: eventIndexPath, sender: sender)
        ScheduleTaskMutationSync.schedule(reason: "ios grid task value")
    }

    override func taskView(_ taskView: UIView & OCKTaskDisplayable, didSelectOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        super.taskView(taskView, didSelectOutcomeValueAt: index, eventIndexPath: eventIndexPath, sender: sender)
        ScheduleTaskMutationSync.schedule(reason: "ios grid task value delete")
    }
}

final class SyncingChecklistTaskViewController: OCKTaskViewController<SyncingTaskController, OCKChecklistTaskViewSynchronizer> {
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        super.init(viewSynchronizer: .init(), task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
