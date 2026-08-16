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
import OTFCareKit
import OTFCareKitStore

final class ECGReportAttachmentLifecycleCoordinator {
    private let attachmentStore: ECGReportAttachmentStoring

    init(attachmentStore: ECGReportAttachmentStoring = ECGReportAttachmentStore.shared) {
        self.attachmentStore = attachmentStore
    }

    func handle(_ notification: OCKStoreNotification) {
        if let outcomeNotification = notification as? OCKOutcomeNotification,
            outcomeNotification.category == .delete {
            deleteAttachment(referencedBy: outcomeNotification.outcome)
            return
        }

        guard
            let taskNotification = notification as? OCKTaskNotification,
            taskNotification.category == .delete
        else {
            return
        }
        deleteAttachments(
            for: taskNotification.task,
            from: taskNotification.storeManager.store,
            including: attachmentStore.attachmentIDs(
                ownerID: taskNotification.task.uuid.uuidString
            )
        )
    }

    func deleteAttachment(referencedBy outcome: OCKAnyOutcome) {
        guard let attachmentID = SensorOutcomeCodec.ecgReportAttachmentID(
            in: outcome.values
        ) else {
            return
        }
        attachmentStore.delete(attachmentID: attachmentID)
    }

    func deleteAttachments(
        for task: OCKAnyTask,
        from store: OCKAnyOutcomeStore,
        including registeredAttachmentIDs: Set<String> = []
    ) {
        var query = OCKOutcomeQuery()
        query.taskUUIDs = [task.uuid]
        store.fetchAnyOutcomes(query: query, callbackQueue: .main) { [weak self] result in
            guard let self else { return }
            let persistedAttachmentIDs: Set<String>
            switch result {
            case .success(let outcomes):
                persistedAttachmentIDs = Set(outcomes.compactMap {
                    SensorOutcomeCodec.ecgReportAttachmentID(in: $0.values)
                })
            case .failure:
                persistedAttachmentIDs = []
            }
            registeredAttachmentIDs
                .union(persistedAttachmentIDs)
                .forEach(attachmentStore.delete(attachmentID:))
        }
    }

    func reconcile(
        outcomes: [OCKAnyOutcome],
        store: OCKAnyOutcomeStore? = nil,
        completion: @escaping () -> Void = {}
    ) {
        let references = outcomes.compactMap { outcome -> ECGReportAttachmentReference? in
            guard let attachment = SensorOutcomeCodec.ecgReportAttachment(in: outcome.values) else {
                return nil
            }
            guard let storedOutcome = outcome as? OCKOutcome else { return nil }
            return ECGReportAttachmentReference(
                attachment: attachment,
                ownerID: storedOutcome.taskUUID.uuidString
            )
        }
        references.forEach { reference in
            attachmentStore.markCommitted(
                attachmentID: reference.attachment.attachmentID,
                ownerID: reference.ownerID
            )
        }
        attachmentStore.reconcile(
            references: references,
            recover: { deletedAttachmentID, replacement, completion in
                guard let store else {
                    completion(.failure(ECGReportAttachmentStoreError.deletionRecoveryFailed))
                    return
                }
                let repairedOutcomes = outcomes.compactMap { outcome -> OCKOutcome? in
                    guard
                        SensorOutcomeCodec.ecgReportAttachmentID(in: outcome.values) ==
                            deletedAttachmentID,
                        var storedOutcome = outcome as? OCKOutcome,
                        let values = SensorOutcomeCodec.replacingECGReportAttachment(
                            in: outcome.values,
                            with: replacement
                        )
                    else {
                        return nil
                    }
                    storedOutcome.values = values
                    return storedOutcome
                }
                guard repairedOutcomes.isEmpty == false else {
                    completion(.failure(ECGReportAttachmentStoreError.deletionRecoveryFailed))
                    return
                }
                store.updateAnyOutcomes(
                    repairedOutcomes,
                    callbackQueue: .main
                ) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            },
            completion: completion
        )
    }
}
