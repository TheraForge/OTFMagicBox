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

import Combine
import Foundation
import HealthKit
import OTFCareKit
import OTFCareKitStore
import OTFCloudClientAPI
import Testing
@testable import OTFMagicBox

@Suite("ECG report attachment lifecycle")
struct ECGReportAttachmentLifecycleTests {
    private let date = Date(timeIntervalSinceReferenceDate: 789012)

    @Test("Deleting an outcome removes its referenced attachment")
    func deletingOutcomeRemovesReferencedAttachment() throws {
        let attachmentStore = LifecycleAttachmentStore()
        let coordinator = ECGReportAttachmentLifecycleCoordinator(
            attachmentStore: attachmentStore
        )
        let outcome = try makeOutcome(taskUUID: UUID())

        coordinator.deleteAttachment(referencedBy: outcome)

        #expect(attachmentStore.deletedAttachmentIDs == ["ecg-attachment"])
    }

    @Test("Deleting a task finds and removes its outcome attachments")
    func deletingTaskRemovesOutcomeAttachments() async throws {
        let attachmentStore = LifecycleAttachmentStore()
        let coordinator = ECGReportAttachmentLifecycleCoordinator(
            attachmentStore: attachmentStore
        )
        let task = makeTask(id: "ecg-lifecycle", start: date, end: nil)
        let outcome = try makeOutcome(taskUUID: task.uuid)
        let store = OCKStore(
            name: "ECGLifecycleTests-\(UUID().uuidString)",
            type: .inMemory
        )
        try await addLifecycleTask(task, to: store)
        try await addLifecycleOutcome(outcome, to: store)

        await withCheckedContinuation { continuation in
            attachmentStore.onDelete = { continuation.resume() }
            coordinator.deleteAttachments(for: task, from: store)
        }

        #expect(attachmentStore.deletedAttachmentIDs == ["ecg-attachment"])
    }

    @Test("Reconciliation passes every persisted report reference")
    func reconciliationPassesPersistedReferences() throws {
        let attachmentStore = LifecycleAttachmentStore()
        let coordinator = ECGReportAttachmentLifecycleCoordinator(
            attachmentStore: attachmentStore
        )
        let first = try makeOutcome(taskUUID: UUID(), attachmentID: "first")
        let second = try makeOutcome(taskUUID: UUID(), attachmentID: "second")

        coordinator.reconcile(outcomes: [first, second])

        #expect(attachmentStore.reconciledAttachmentIDs == [["first", "second"]])
        #expect(Set(attachmentStore.committedAttachments.map(\.attachmentID)) == ["first", "second"])
    }

    @Test("Task deletion unions registered and synced attachments without duplicates")
    func taskDeletionUnionsRegisteredAndSyncedAttachments() async throws {
        let attachmentStore = LifecycleAttachmentStore()
        attachmentStore.registeredAttachmentIDs = ["registered", "synced"]
        let coordinator = ECGReportAttachmentLifecycleCoordinator(
            attachmentStore: attachmentStore
        )
        let task = makeTask(id: "ecg-mixed-lifecycle", start: date, end: nil)
        let outcome = try makeOutcome(taskUUID: task.uuid, attachmentID: "synced")
        let store = OCKStore(
            name: "ECGMixedLifecycleTests-\(UUID().uuidString)",
            type: .inMemory
        )
        try await addLifecycleTask(task, to: store)
        try await addLifecycleOutcome(outcome, to: store)

        await withCheckedContinuation { continuation in
            var deletionCount = 0
            attachmentStore.onDelete = {
                deletionCount += 1
                if deletionCount == 2 {
                    continuation.resume()
                }
            }
            coordinator.deleteAttachments(
                for: task,
                from: store,
                including: attachmentStore.attachmentIDs(ownerID: task.uuid.uuidString)
            )
        }

        #expect(Set(attachmentStore.deletedAttachmentIDs) == ["registered", "synced"])
        #expect(attachmentStore.deletedAttachmentIDs.count == 2)
    }

    @MainActor
    @Test("Reconciliation repairs a CareKit outcome after deletion reaches the server")
    func reconciliationRepairsOutcomeAfterServerDeletion() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-lifecycle-recovery")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        let task = makeTask(id: "ecg-recovery", start: date, end: nil)
        let outcome = try makeOutcome(taskUUID: task.uuid)
        let careKitStore = OCKStore(
            name: "ECGRecoveryTests-\(UUID().uuidString)",
            type: .inMemory
        )
        try await addLifecycleTask(task, to: careKitStore)
        try await addLifecycleOutcome(outcome, to: careKitStore)
        let deletionResponse = PassthroughSubject<Response.DeleteFile, ForgeError>()
        var deletionStarted = false
        var deletionStartedContinuation: CheckedContinuation<Void, Never>?
        let attachmentStore = ECGReportAttachmentStore(
            uploadRequest: { data, fileName, _, encryptedKey, hash in
                Just(Response.FileResponse(
                    metadata: makeLifecycleMetadata(
                        attachmentID: "replacement",
                        fileName: fileName,
                        encryptedFileKey: encryptedKey,
                        hashFileKey: hash
                    ),
                    data: data
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            downloadRequest: { attachmentID, _ in
                Just(Response.FileResponse(
                    metadata: makeLifecycleMetadata(
                        attachmentID: attachmentID,
                        fileName: "MagicBox-ECG-Test.pdf",
                        encryptedFileKey: "encrypted-file-key",
                        hashFileKey: "file-key-hash"
                    ),
                    data: Data([0x01])
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            deleteRequest: { _ in
                deletionStarted = true
                deletionStartedContinuation?.resume()
                deletionStartedContinuation = nil
                return deletionResponse.eraseToAnyPublisher()
            },
            registry: registry
        )
        let coordinator = ECGReportAttachmentLifecycleCoordinator(
            attachmentStore: attachmentStore
        )

        var deletionResult: Result<Void, Error>?
        await confirmation("Server deletion finishes") { finished in
            attachmentStore.delete(attachmentID: "ecg-attachment") {
                deletionResult = $0
                finished()
            }
            if deletionStarted == false {
                await withCheckedContinuation { startedContinuation in
                    deletionStartedContinuation = startedContinuation
                }
            }
            deletionResponse.send(Response.DeleteFile(
                error: false,
                message: "Deleted",
                statusCode: 200
            ))
            deletionResponse.send(completion: .finished)
        }
        await withCheckedContinuation { continuation in
            coordinator.reconcile(
                outcomes: [outcome],
                store: careKitStore,
                completion: { continuation.resume() }
            )
        }

        let repairedOutcomes = try await fetchLifecycleOutcomes(from: careKitStore)
        let repairedOutcome = try #require(repairedOutcomes.first)
        let deletionResult = try #require(deletionResult)
        guard case .success = deletionResult else {
            Issue.record("Expected the server deletion to finish before reconciliation")
            return
        }
        #expect(
            SensorOutcomeCodec.ecgReportAttachmentID(in: repairedOutcome.values) ==
                "replacement"
        )
        #expect(registry.attachmentIDs(ownerID: task.uuid.uuidString) == ["replacement"])
    }

    private func makeOutcome(
        taskUUID: UUID,
        attachmentID: String = "ecg-attachment"
    ) throws -> OCKOutcome {
        let attachment = try #require(ECGReportAttachment(
            attachmentID: attachmentID,
            fileName: "MagicBox-ECG-Test.pdf",
            encryptedFileKey: "encrypted-file-key",
            hashFileKey: "file-key-hash",
            sourceSampleUUID: nil
        ))
        let payload = SensorOutcomePayload(
            metric: .ecg,
            reading: .ecg(
                classification: .sinusRhythm,
                averageBPM: 72,
                samplingHz: 512,
                duration: 30,
                date: date
            ),
            mode: .sensor,
            ecgReportAttachment: attachment
        )
        return OCKOutcome(
            taskUUID: taskUUID,
            taskOccurrenceIndex: 0,
            values: SensorOutcomeCodec.encode(payload)
        )
    }
}

private final class LifecycleAttachmentStore: ECGReportAttachmentStoring {
    private(set) var deletedAttachmentIDs = [String]()
    private(set) var reconciledAttachmentIDs = [Set<String>]()
    private(set) var committedAttachments = [(attachmentID: String, ownerID: String)]()
    var registeredAttachmentIDs = Set<String>()
    var onDelete: (() -> Void)?

    func upload(
        report: ECGReport,
        completion: @escaping (Result<ECGReportAttachment, Error>) -> Void
    ) {}

    func download(
        attachment: ECGReportAttachment,
        completion: @escaping (Result<ECGReport, Error>) -> Void
    ) {}

    func delete(
        attachmentID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        deletedAttachmentIDs.append(attachmentID)
        completion(.success(()))
        onDelete?()
    }

    func reconcile(referencedAttachmentIDs: Set<String>) {
        reconciledAttachmentIDs.append(referencedAttachmentIDs)
    }

    func markCommitted(attachmentID: String, ownerID: String) {
        committedAttachments.append((attachmentID, ownerID))
    }

    func attachmentIDs(ownerID: String) -> Set<String> {
        registeredAttachmentIDs
    }
}

private func addLifecycleTask(_ task: OCKTask, to store: OCKStore) async throws {
    let result = await withCheckedContinuation { continuation in
        store.addAnyTask(task, callbackQueue: .main) { continuation.resume(returning: $0) }
    }
    if case .failure(let error) = result {
        throw error
    }
}

private func addLifecycleOutcome(_ outcome: OCKOutcome, to store: OCKStore) async throws {
    let result = await withCheckedContinuation { continuation in
        store.addAnyOutcome(outcome, callbackQueue: .main) { continuation.resume(returning: $0) }
    }
    if case .failure(let error) = result {
        throw error
    }
}

private func fetchLifecycleOutcomes(from store: OCKStore) async throws -> [OCKAnyOutcome] {
    let result = await withCheckedContinuation { continuation in
        store.fetchAnyOutcomes(
            query: OCKOutcomeQuery(),
            callbackQueue: .main
        ) { continuation.resume(returning: $0) }
    }
    return try result.get()
}

private func makeLifecycleMetadata(
    attachmentID: String,
    fileName: String,
    encryptedFileKey: String,
    hashFileKey: String
) -> Response.Metadata {
    Response.Metadata(
        contentType: "application/octet-stream",
        revpos: "1",
        hashFileKey: hashFileKey,
        encryptedFileKey: encryptedFileKey,
        location: Request.AttachmentLocation.documents.rawValue,
        fileName: fileName,
        owner: "test-user",
        attrev: 1,
        length: 1,
        stub: false,
        attachmentID: attachmentID
    )
}
