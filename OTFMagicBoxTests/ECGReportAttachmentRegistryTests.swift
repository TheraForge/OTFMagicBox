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
import OTFCloudClientAPI
import Testing
@testable import OTFMagicBox

@Suite("ECG report attachment registry")
struct ECGReportAttachmentRegistryTests {
    @Test("Pending attachments are user-isolated, committed, and reconciled")
    func pendingAttachmentRegistryLifecycle() async {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient-a" }
        )
        let otherRegistry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient-b" }
        )
        registry.recordPending(attachmentID: "referenced")
        registry.recordPending(attachmentID: "orphan")
        registry.recordCommitted(attachmentID: "referenced", ownerID: "task-a")

        await confirmation("Deletes the unreferenced attachment") { deleted in
            let store = ECGReportAttachmentStore(
                downloadRequest: { attachmentID, _ in
                    makeRegistryDeletionBackup(attachmentID)
                },
                deleteRequest: { attachmentID in
                    #expect(attachmentID == "orphan")
                    deleted()
                    return Just(Response.DeleteFile(
                        error: false,
                        message: "Deleted",
                        statusCode: 200
                    ))
                    .setFailureType(to: ForgeError.self)
                    .eraseToAnyPublisher()
                },
                registry: registry
            )

            await withCheckedContinuation { continuation in
                store.reconcile(referencedAttachmentIDs: ["referenced"]) {
                    continuation.resume()
                }
            }
        }

        #expect(registry.pendingAttachmentIDs.isEmpty)
        #expect(registry.pendingDeletionAttachmentIDs.isEmpty)
        #expect(registry.attachmentIDs(ownerID: "task-a") == ["referenced"])
        #expect(otherRegistry.pendingAttachmentIDs.isEmpty)
        #expect(otherRegistry.pendingDeletionAttachmentIDs.isEmpty)
    }

    @MainActor
    @Test("Current-session upload survives reconciliation until outcome persistence")
    func currentSessionUploadSurvivesReconciliation() async throws {
        let report = try #require(makeRegistryReport())
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-active-upload")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        var deletionRequestCount = 0
        let store = ECGReportAttachmentStore(
            storageKey: { Array(repeating: UInt8(0x24), count: 32) },
            uploadRequest: { data, fileName, _, encryptedKey, hash in
                Just(Response.FileResponse(
                    metadata: makeRegistryMetadata(
                        attachmentID: "active-submission",
                        fileName: fileName,
                        encryptedFileKey: encryptedKey,
                        hashFileKey: hash
                    ),
                    data: data
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            deleteRequest: { _ in
                deletionRequestCount += 1
                return Just(Response.DeleteFile(
                    error: false,
                    message: "Deleted",
                    statusCode: 200
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            registry: registry
        )

        let attachment = try await withCheckedThrowingContinuation { continuation in
            store.upload(report: report) { continuation.resume(with: $0) }
        }
        #expect(registry.pendingAttachmentIDs == [attachment.attachmentID])

        await withCheckedContinuation { continuation in
            store.reconcile(referencedAttachmentIDs: []) {
                continuation.resume()
            }
        }

        #expect(deletionRequestCount == 0)
        #expect(registry.pendingAttachmentIDs == [attachment.attachmentID])

        store.markCommitted(
            attachmentID: attachment.attachmentID,
            ownerID: "task"
        )

        #expect(registry.pendingAttachmentIDs.isEmpty)
        #expect(registry.attachmentIDs(ownerID: "task") == [attachment.attachmentID])
    }

    @MainActor
    @Test("Restored reference cancels a failed deletion retry")
    func restoredReferenceCancelsFailedDeletionRetry() async {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-restored-reference")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        registry.recordPending(attachmentID: "restored")
        var deletionRequestCount = 0
        let store = ECGReportAttachmentStore(
            downloadRequest: { attachmentID, _ in
                makeRegistryDeletionBackup(attachmentID)
            },
            deleteRequest: { _ in
                deletionRequestCount += 1
                return Fail(error: makeForgeError(message: "Delete failed"))
                    .eraseToAnyPublisher()
            },
            registry: registry
        )

        let deletionResult: Result<Void, Error> = await withCheckedContinuation { continuation in
            store.delete(attachmentID: "restored") {
                continuation.resume(returning: $0)
            }
        }
        #expect(deletionResult.failure != nil)
        #expect(registry.pendingDeletionAttachmentIDs == ["restored"])

        await withCheckedContinuation { continuation in
            store.reconcile(referencedAttachmentIDs: ["restored"]) {
                continuation.resume()
            }
        }

        #expect(deletionRequestCount == 1)
        #expect(registry.pendingAttachmentIDs.isEmpty)
        #expect(registry.pendingDeletionAttachmentIDs.isEmpty)
    }

    @MainActor
    @Test("A reference restored after server deletion is repaired with a replacement attachment")
    func restoredReferenceAfterServerDeletionIsRecovered() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-cancel-delete")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        registry.recordPending(attachmentID: "restored")
        let response = PassthroughSubject<Response.DeleteFile, ForgeError>()
        var cancellationCount = 0
        var deletionResult: Result<Void, Error>?
        var deletionStarted = false
        var deletionStartedContinuation: CheckedContinuation<Void, Never>?
        var recoveredPair: (deletedID: String, replacement: ECGReportAttachment)?
        let restoredAttachment = try #require(ECGReportAttachment(
            attachmentID: "restored",
            fileName: "MagicBox-ECG-Test.pdf",
            encryptedFileKey: "encrypted-file-key",
            hashFileKey: "file-key-hash",
            sourceSampleUUID: nil
        ))
        let store = ECGReportAttachmentStore(
            uploadRequest: { data, fileName, _, encryptedKey, hash in
                #expect(data == Data([0x01]))
                return Just(Response.FileResponse(
                    metadata: makeRegistryMetadata(
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
                makeRegistryDeletionBackup(attachmentID)
            },
            deleteRequest: { _ in
                deletionStarted = true
                deletionStartedContinuation?.resume()
                deletionStartedContinuation = nil
                response
                    .handleEvents(receiveCancel: { cancellationCount += 1 })
                    .eraseToAnyPublisher()
            },
            registry: registry
        )

        await confirmation("Server deletion finishes") { finished in
            store.delete(attachmentID: "restored") {
                deletionResult = $0
                finished()
            }
            if deletionStarted == false {
                await withCheckedContinuation { continuation in
                    deletionStartedContinuation = continuation
                }
            }
            #expect(registry.pendingDeletionAttachmentIDs == ["restored"])
            response.send(Response.DeleteFile(
                error: false,
                message: "Deleted",
                statusCode: 200
            ))
            response.send(completion: .finished)
        }

        await withCheckedContinuation { continuation in
            store.reconcile(
                references: [ECGReportAttachmentReference(
                    attachment: restoredAttachment,
                    ownerID: "task"
                )],
                recover: { deletedID, replacement, completion in
                    recoveredPair = (deletedID, replacement)
                    completion(.success(()))
                },
                completion: { continuation.resume() }
            )
        }

        #expect(cancellationCount == 0)
        let completedDeletion = try #require(deletionResult)
        guard case .success = completedDeletion else {
            Issue.record("Expected the server deletion to finish before recovery")
            return
        }
        #expect(recoveredPair?.deletedID == "restored")
        #expect(recoveredPair?.replacement.attachmentID == "replacement")
        #expect(registry.pendingAttachmentIDs.isEmpty)
        #expect(registry.pendingDeletionAttachmentIDs.isEmpty)
        #expect(registry.attachmentIDs(ownerID: "task") == ["replacement"])
    }

    @Test("Deleting an owner removes its committed attachments")
    func deletingOwnerRemovesCommittedAttachments() async {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-owner")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        registry.recordCommitted(attachmentID: "first", ownerID: "task")
        registry.recordCommitted(attachmentID: "second", ownerID: "task")

        let store = ECGReportAttachmentStore(
            downloadRequest: { attachmentID, _ in
                makeRegistryDeletionBackup(attachmentID)
            },
            deleteRequest: { _ in
                Just(Response.DeleteFile(
                    error: false,
                    message: "Deleted",
                    statusCode: 200
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            registry: registry
        )

        await withCheckedContinuation { continuation in
            store.deleteAttachments(ownerID: "task") {
                continuation.resume()
            }
        }

        #expect(registry.attachmentIDs(ownerID: "task").isEmpty)
    }

    @Test("Failed orphan deletion remains registered for a later retry")
    func failedOrphanDeletionRemainsRegistered() async {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-failure")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        registry.recordPending(attachmentID: "orphan")
        let store = ECGReportAttachmentStore(
            downloadRequest: { attachmentID, _ in
                makeRegistryDeletionBackup(attachmentID)
            },
            deleteRequest: { _ in
                Fail(error: makeForgeError(message: "Delete failed"))
                    .eraseToAnyPublisher()
            },
            registry: registry
        )

        await withCheckedContinuation { continuation in
            store.reconcile(referencedAttachmentIDs: []) {
                continuation.resume()
            }
        }

        #expect(registry.pendingAttachmentIDs == ["orphan"])
        #expect(registry.pendingDeletionAttachmentIDs == ["orphan"])
    }

    @Test("Rejected deletion remains registered for a later retry")
    func rejectedDeletionRemainsRegistered() async {
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-rejected")
        defer { isolatedDefaults.cleanup() }
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient" }
        )
        registry.recordPending(attachmentID: "orphan")
        let store = ECGReportAttachmentStore(
            downloadRequest: { attachmentID, _ in
                makeRegistryDeletionBackup(attachmentID)
            },
            deleteRequest: { _ in
                Just(Response.DeleteFile(
                    error: true,
                    message: "Not deleted",
                    statusCode: 500
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            },
            registry: registry
        )

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            store.delete(attachmentID: "orphan") {
                continuation.resume(returning: $0)
            }
        }

        #expect(result.failure as? ECGReportAttachmentStoreError == .deletionRejected)
        #expect(registry.pendingAttachmentIDs == ["orphan"])
        #expect(registry.pendingDeletionAttachmentIDs == ["orphan"])
    }

    @MainActor
    @Test("Upload completion stays bound to its initiating account")
    func uploadCompletionUsesInitiatingAccount() async throws {
        let report = try #require(makeRegistryReport())
        let isolatedDefaults = makeIsolatedUserDefaults(prefix: "ecg-registry-account-switch")
        defer { isolatedDefaults.cleanup() }
        var activeNamespace = "patient-a"
        let registry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { activeNamespace }
        )
        let patientARegistry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient-a" }
        )
        let patientBRegistry = ECGReportAttachmentRegistry(
            defaults: isolatedDefaults.defaults,
            namespace: { "patient-b" }
        )
        let response = PassthroughSubject<Response.FileResponse, ForgeError>()
        var responseMetadata: Response.Metadata?
        let store = ECGReportAttachmentStore(
            storageKey: { Array(repeating: UInt8(0x24), count: 32) },
            uploadRequest: { _, fileName, _, encryptedKey, hash in
                responseMetadata = makeRegistryMetadata(
                    attachmentID: "account-bound-attachment",
                    fileName: fileName,
                    encryptedFileKey: encryptedKey,
                    hashFileKey: hash
                )
                return response.eraseToAnyPublisher()
            },
            registry: registry
        )

        let uploadResult: Result<ECGReportAttachment, Error> = await withCheckedContinuation { continuation in
            store.upload(report: report) {
                continuation.resume(returning: $0)
            }
            activeNamespace = "patient-b"
            if let responseMetadata {
                response.send(Response.FileResponse(
                    metadata: responseMetadata,
                    data: Data()
                ))
                response.send(completion: .finished)
            } else {
                Issue.record("Upload request did not provide response metadata")
                response.send(completion: .failure(makeForgeError(
                    message: "Missing upload metadata"
                )))
            }
        }
        let attachment = try uploadResult.get()
        store.markCommitted(attachmentID: attachment.attachmentID, ownerID: "task-a")

        #expect(patientARegistry.pendingAttachmentIDs.isEmpty)
        #expect(patientARegistry.attachmentIDs(ownerID: "task-a") == [attachment.attachmentID])
        #expect(patientBRegistry.pendingAttachmentIDs.isEmpty)
        #expect(patientBRegistry.attachmentIDs(ownerID: "task-a").isEmpty)
    }

    private func makeForgeError(message: String) -> ForgeError {
        ForgeError(error: .init(
            statusCode: 500,
            name: "ECGReportAttachmentRegistryTests",
            message: message,
            code: nil
        ))
    }
}

private extension Result {
    var failure: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}

private func makeRegistryReport() -> ECGReport? {
    ECGReport(
        pdfData: Data("%PDF-1.7 registry test".utf8),
        sourceSampleUUID: nil
    )
}

private func makeRegistryMetadata(
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

private func makeRegistryDeletionBackup(
    _ attachmentID: String
) -> AnyPublisher<Response.FileResponse, ForgeError> {
    Just(Response.FileResponse(
        metadata: makeRegistryMetadata(
            attachmentID: attachmentID,
            fileName: "MagicBox-ECG-Test.pdf",
            encryptedFileKey: "encrypted-file-key",
            hashFileKey: "file-key-hash"
        ),
        data: Data([0x01])
    ))
    .setFailureType(to: ForgeError.self)
    .eraseToAnyPublisher()
}
