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
import OTFCloudClientAPI
import OTFUtilities
import Sodium

struct ECGReportAttachmentReference: Equatable {
    let attachment: ECGReportAttachment
    let ownerID: String
}

protocol ECGReportAttachmentStoring: AnyObject {
    func upload(
        report: ECGReport,
        completion: @escaping (Result<ECGReportAttachment, Error>) -> Void
    )

    func download(
        attachment: ECGReportAttachment,
        completion: @escaping (Result<ECGReport, Error>) -> Void
    )

    func delete(
        attachmentID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func markCommitted(attachmentID: String, ownerID: String)
    func attachmentIDs(ownerID: String) -> Set<String>
    @discardableResult
    func deleteAttachments(ownerID: String) -> Bool
    func reconcile(referencedAttachmentIDs: Set<String>)
    func reconcile(
        referencedAttachmentIDs: Set<String>,
        completion: @escaping () -> Void
    )
    func reconcile(
        references: [ECGReportAttachmentReference],
        recover: @escaping (
            _ deletedAttachmentID: String,
            _ replacement: ECGReportAttachment,
            _ completion: @escaping (Result<Void, Error>) -> Void
        ) -> Void,
        completion: @escaping () -> Void
    )
}

extension ECGReportAttachmentStoring {
    func delete(attachmentID: String) {
        delete(attachmentID: attachmentID) { _ in }
    }

    func markCommitted(attachmentID: String, ownerID: String) {}
    func attachmentIDs(ownerID: String) -> Set<String> { [] }
    func deleteAttachments(ownerID: String) -> Bool { false }
    func reconcile(referencedAttachmentIDs: Set<String>) {}
    func reconcile(
        referencedAttachmentIDs: Set<String>,
        completion: @escaping () -> Void
    ) {
        reconcile(referencedAttachmentIDs: referencedAttachmentIDs)
        completion()
    }

    func reconcile(
        references: [ECGReportAttachmentReference],
        recover: @escaping (
            _ deletedAttachmentID: String,
            _ replacement: ECGReportAttachment,
            _ completion: @escaping (Result<Void, Error>) -> Void
        ) -> Void,
        completion: @escaping () -> Void
    ) {
        reconcile(
            referencedAttachmentIDs: Set(references.map { $0.attachment.attachmentID }),
            completion: completion
        )
    }
}

enum ECGReportAttachmentStoreError: Error, Equatable {
    case invalidAttachmentMetadata
    case invalidReportData
    case deletionBackupUnavailable
    case deletionRejected
    case deletionCancelled
    case deletionRecoveryFailed
}

final class ECGReportAttachmentStore: ECGReportAttachmentStoring {
    typealias UploadRequest = (
        Data,
        String,
        Request.AttachmentLocation,
        String,
        String
    ) -> AnyPublisher<Response.FileResponse, ForgeError>
    typealias DownloadRequest = (
        String,
        Request.AttachmentLocation
    ) -> AnyPublisher<Response.FileResponse, ForgeError>
    typealias DeleteRequest = (String) -> AnyPublisher<Response.DeleteFile, ForgeError>

    private final class DeletionOperation {
        enum Phase: Equatable {
            case backingUp
            case deleting
            case recovering
        }

        let namespace: String
        var phase = Phase.backingUp
        var cancellable: AnyCancellable?
        var completions: [(Result<Void, Error>) -> Void]
        var backup: Response.FileResponse?
        var restoredReference: ECGReportAttachmentReference?
        var recovery: ((String, ECGReportAttachment, @escaping (Result<Void, Error>) -> Void) -> Void)?

        init(
            namespace: String,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            self.namespace = namespace
            completions = [completion]
        }
    }

    private struct RecoverableDeletion {
        let namespace: String
        let backup: Response.FileResponse
    }

    static let shared = ECGReportAttachmentStore()

    private let cryptor: SecureAttachmentCryptor
    private let storageKey: () -> Bytes
    private let uploadRequest: UploadRequest
    private let downloadRequest: DownloadRequest
    private let deleteRequest: DeleteRequest
    private let registry: ECGReportAttachmentRegistry
    private let logger = OTFLogger.logger()
    private let requestLock = NSLock()
    private var activeRequests = [UUID: AnyCancellable]()
    private var attachmentNamespaces = [String: String]()
    private var currentSessionPendingNamespaces = [String: String]()
    private var deletionOperations = [String: DeletionOperation]()
    private var recoverableDeletions = [String: RecoverableDeletion]()

    init(
        cryptor: SecureAttachmentCryptor = SecureAttachmentCryptor(),
        storageKey: @escaping () -> Bytes = { KeychainCloudManager.getDefaultStorageKey },
        uploadRequest: @escaping UploadRequest = { data, fileName, location, encryptedKey, hash in
            OTFTheraforgeNetwork.shared.uploadFile(
                data: data,
                fileName: fileName,
                type: location,
                encryptedFileKey: encryptedKey,
                hashFileKey: hash
            )
        },
        downloadRequest: @escaping DownloadRequest = { attachmentID, location in
            OTFTheraforgeNetwork.shared.downloadFile(
                attachmentID: attachmentID,
                type: location
            )
        },
        deleteRequest: @escaping DeleteRequest = { attachmentID in
            OTFTheraforgeNetwork.shared.deleteFile(attachmentID: attachmentID)
        },
        registry: ECGReportAttachmentRegistry = ECGReportAttachmentRegistry()
    ) {
        self.cryptor = cryptor
        self.storageKey = storageKey
        self.uploadRequest = uploadRequest
        self.downloadRequest = downloadRequest
        self.deleteRequest = deleteRequest
        self.registry = registry
    }

    func upload(
        report: ECGReport,
        completion: @escaping (Result<ECGReportAttachment, Error>) -> Void
    ) {
        let registryNamespace = registry.currentNamespace
        let envelope: SecureAttachmentEnvelope
        do {
            envelope = try cryptor.encrypt(report.pdfData, storageKey: storageKey())
        } catch {
            completion(.failure(error))
            return
        }

        let fileName = makeFileName(sourceSampleUUID: report.sourceSampleUUID)
        let requestID = UUID()
        let request = uploadRequest(
            envelope.encryptedData,
            fileName,
            .documents,
            envelope.encryptedFileKey,
            envelope.hashFileKey
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            self?.finishRequest(requestID)
            if case .failure(let error) = result {
                completion(.failure(error))
            }
        } receiveValue: { [weak self] response in
            guard let self else { return }
            guard
                response.metadata.attachmentID.isEmpty == false,
                response.metadata.location == Request.AttachmentLocation.documents.rawValue,
                response.metadata.fileName.isEmpty || response.metadata.fileName == fileName,
                response.metadata.encryptedFileKey.caseInsensitiveCompare(
                    envelope.encryptedFileKey
                ) == .orderedSame,
                response.metadata.hashFileKey.caseInsensitiveCompare(envelope.hashFileKey) == .orderedSame,
                let attachment = ECGReportAttachment(
                    attachmentID: response.metadata.attachmentID,
                    fileName: fileName,
                    encryptedFileKey: envelope.encryptedFileKey,
                    hashFileKey: envelope.hashFileKey,
                    sourceSampleUUID: report.sourceSampleUUID,
                    lead: report.lead,
                    format: report.format,
                    mimeType: report.mimeType
                )
            else {
                completion(.failure(ECGReportAttachmentStoreError.invalidAttachmentMetadata))
                return
            }
            registerPendingUpload(
                attachmentID: attachment.attachmentID,
                namespace: registryNamespace
            )
            completion(.success(attachment))
        }
        retain(request, requestID: requestID)
    }

    func download(
        attachment: ECGReportAttachment,
        completion: @escaping (Result<ECGReport, Error>) -> Void
    ) {
        let requestID = UUID()
        let request = downloadRequest(attachment.attachmentID, .documents)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.finishRequest(requestID)
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                do {
                    guard
                        response.metadata.attachmentID == attachment.attachmentID,
                        response.metadata.location == Request.AttachmentLocation.documents.rawValue,
                        response.metadata.fileName.isEmpty ||
                            response.metadata.fileName == attachment.fileName,
                        response.metadata.encryptedFileKey.caseInsensitiveCompare(
                            attachment.encryptedFileKey
                        ) == .orderedSame,
                        response.metadata.hashFileKey.caseInsensitiveCompare(
                            attachment.hashFileKey
                        ) == .orderedSame
                    else {
                        throw ECGReportAttachmentStoreError.invalidAttachmentMetadata
                    }
                    let reportData = try cryptor.decrypt(
                        response.data,
                        encryptedFileKey: attachment.encryptedFileKey,
                        hashFileKey: attachment.hashFileKey,
                        storageKey: storageKey()
                    )
                    guard let report = ECGReport(
                        pdfData: reportData,
                        sourceSampleUUID: attachment.sourceSampleUUID,
                        lead: attachment.lead,
                        format: attachment.format,
                        mimeType: attachment.mimeType
                    ) else {
                        throw ECGReportAttachmentStoreError.invalidReportData
                    }
                    completion(.success(report))
                } catch {
                    completion(.failure(error))
                }
            }
        retain(request, requestID: requestID)
    }

    func delete(
        attachmentID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let operation: DeletionOperation
        requestLock.lock()
        let registryNamespace = attachmentNamespaces[attachmentID] ?? registry.currentNamespace
        currentSessionPendingNamespaces[attachmentID] = nil
        registry.recordPendingDeletion(attachmentID: attachmentID, namespace: registryNamespace)
        if let activeOperation = deletionOperations[attachmentID] {
            activeOperation.completions.append(completion)
            requestLock.unlock()
            return
        }
        operation = DeletionOperation(
            namespace: registryNamespace,
            completion: completion
        )
        deletionOperations[attachmentID] = operation
        requestLock.unlock()

        backUpAttachmentForDeletion(
            attachmentID: attachmentID,
            operation: operation
        )
    }
}

extension ECGReportAttachmentStore {
    private func backUpAttachmentForDeletion(
        attachmentID: String,
        operation: DeletionOperation
    ) {
        let request = downloadRequest(attachmentID, .documents)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard case .failure(let error) = result else { return }
                self?.logger.error(
                    "ECG attachment deletion was stopped because its recovery backup failed: \(error.localizedDescription)"
                )
                self?.finishDeletion(
                    attachmentID: attachmentID,
                    operation: operation,
                    result: .failure(ECGReportAttachmentStoreError.deletionBackupUnavailable)
                )
            } receiveValue: { [weak self] response in
                self?.finishDeletionBackup(
                    response,
                    attachmentID: attachmentID,
                    operation: operation
                )
            }
        retainDeletion(request, attachmentID: attachmentID, operation: operation)
    }

    private func finishDeletionBackup(
        _ response: Response.FileResponse,
        attachmentID: String,
        operation: DeletionOperation
    ) {
        guard
            response.metadata.attachmentID == attachmentID,
            response.metadata.location == Request.AttachmentLocation.documents.rawValue,
            response.metadata.encryptedFileKey.isEmpty == false,
            response.metadata.hashFileKey.isEmpty == false,
            response.data.isEmpty == false
        else {
            finishDeletion(
                attachmentID: attachmentID,
                operation: operation,
                result: .failure(ECGReportAttachmentStoreError.deletionBackupUnavailable)
            )
            return
        }

        requestLock.lock()
        guard deletionOperations[attachmentID] === operation else {
            requestLock.unlock()
            return
        }
        operation.backup = response
        if operation.restoredReference != nil {
            requestLock.unlock()
            finishDeletion(
                attachmentID: attachmentID,
                operation: operation,
                result: .failure(ECGReportAttachmentStoreError.deletionCancelled)
            )
            return
        }
        operation.phase = .deleting
        requestLock.unlock()

        startDeletionRequest(
            attachmentID: attachmentID,
            operation: operation
        )
    }

    private func startDeletionRequest(
        attachmentID: String,
        operation: DeletionOperation
    ) {
        let request = deleteRequest(attachmentID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, logger] result in
                if case .failure(let error) = result {
                    logger.error("Failed to delete orphaned ECG attachment: \(error.localizedDescription)")
                    self?.finishDeletion(
                        attachmentID: attachmentID,
                        operation: operation,
                        result: .failure(error)
                    )
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                guard
                    response.error == false,
                    (200..<300).contains(response.statusCode)
                else {
                    self.logger.error("ECG attachment deletion was rejected by the server.")
                    self.finishDeletion(
                        attachmentID: attachmentID,
                        operation: operation,
                        result: .failure(ECGReportAttachmentStoreError.deletionRejected)
                    )
                    return
                }
                self.finishAcceptedDeletion(
                    attachmentID: attachmentID,
                    operation: operation
                )
            }
        retainDeletion(request, attachmentID: attachmentID, operation: operation)
    }

    func markCommitted(attachmentID: String, ownerID: String) {
        let cancelledOperation: DeletionOperation?
        requestLock.lock()
        let registryNamespace = attachmentNamespaces[attachmentID] ?? registry.currentNamespace
        if let operation = deletionOperations[attachmentID], operation.phase == .backingUp {
            cancelledOperation = deletionOperations.removeValue(forKey: attachmentID)
        } else {
            cancelledOperation = nil
        }
        currentSessionPendingNamespaces[attachmentID] = nil
        if deletionOperations[attachmentID] == nil {
            registry.cancelPendingDeletion(
                attachmentID: attachmentID,
                namespace: registryNamespace
            )
        }
        registry.recordCommitted(
            attachmentID: attachmentID,
            ownerID: ownerID,
            namespace: registryNamespace
        )
        registry.markCommitted(
            attachmentID: attachmentID,
            namespace: registryNamespace
        )
        attachmentNamespaces[attachmentID] = nil
        requestLock.unlock()
        cancelDeletion(cancelledOperation)
    }

    func attachmentIDs(ownerID: String) -> Set<String> {
        let registryNamespace = registry.currentNamespace
        let attachmentIDs = registry.attachmentIDs(ownerID: ownerID)
        attachmentIDs.forEach {
            rememberNamespace(registryNamespace, attachmentID: $0)
        }
        return attachmentIDs
    }

    @discardableResult
    func deleteAttachments(ownerID: String) -> Bool {
        deleteAttachments(ownerID: ownerID) {}
    }

    @discardableResult
    func deleteAttachments(
        ownerID: String,
        completion: @escaping () -> Void
    ) -> Bool {
        let attachmentIDs = attachmentIDs(ownerID: ownerID)
        let group = DispatchGroup()
        attachmentIDs.forEach { attachmentID in
            group.enter()
            delete(attachmentID: attachmentID) { _ in group.leave() }
        }
        group.notify(queue: .main, execute: completion)
        return attachmentIDs.isEmpty == false
    }

    func reconcile(referencedAttachmentIDs: Set<String>) {
        reconcile(referencedAttachmentIDs: referencedAttachmentIDs) {}
    }

    func reconcile(
        referencedAttachmentIDs: Set<String>,
        completion: @escaping () -> Void
    ) {
        reconcile(
            referencedAttachmentIDs: referencedAttachmentIDs,
            referencesByID: [:],
            recover: { _, _, completion in
                completion(.failure(ECGReportAttachmentStoreError.deletionRecoveryFailed))
            },
            completion: completion
        )
    }

    func reconcile(
        references: [ECGReportAttachmentReference],
        recover: @escaping (
            _ deletedAttachmentID: String,
            _ replacement: ECGReportAttachment,
            _ completion: @escaping (Result<Void, Error>) -> Void
        ) -> Void,
        completion: @escaping () -> Void
    ) {
        let referencesByID = Dictionary(
            references.map { ($0.attachment.attachmentID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        reconcile(
            referencedAttachmentIDs: Set(referencesByID.keys),
            referencesByID: referencesByID,
            recover: recover,
            completion: completion
        )
    }

    private func reconcile(
        referencedAttachmentIDs: Set<String>,
        referencesByID: [String: ECGReportAttachmentReference],
        recover: @escaping (
            _ deletedAttachmentID: String,
            _ replacement: ECGReportAttachment,
            _ completion: @escaping (Result<Void, Error>) -> Void
        ) -> Void,
        completion: @escaping () -> Void
    ) {
        let registryNamespace = registry.currentNamespace
        var cancelledOperations = [DeletionOperation]()
        var recoveryOperations = [(attachmentID: String, operation: DeletionOperation)]()
        let group = DispatchGroup()
        requestLock.lock()
        for attachmentID in referencedAttachmentIDs {
            if let reference = referencesByID[attachmentID] {
                registry.recordCommitted(
                    attachmentID: attachmentID,
                    ownerID: reference.ownerID,
                    namespace: registryNamespace
                )
            }
            if let operation = deletionOperations[attachmentID] {
                if operation.phase == .backingUp {
                    deletionOperations[attachmentID] = nil
                    cancelledOperations.append(operation)
                    registry.cancelPendingDeletion(
                        attachmentID: attachmentID,
                        namespace: registryNamespace
                    )
                } else if let reference = referencesByID[attachmentID] {
                    operation.restoredReference = reference
                    operation.recovery = recover
                    group.enter()
                    operation.completions.append { _ in group.leave() }
                }
            } else if
                let reference = referencesByID[attachmentID],
                let recoverableDeletion = recoverableDeletions.removeValue(
                    forKey: attachmentID
                ) {
                group.enter()
                let operation = DeletionOperation(
                    namespace: recoverableDeletion.namespace,
                    completion: { _ in group.leave() }
                )
                operation.phase = .recovering
                operation.backup = recoverableDeletion.backup
                operation.restoredReference = reference
                operation.recovery = recover
                deletionOperations[attachmentID] = operation
                registry.recordPendingDeletion(
                    attachmentID: attachmentID,
                    namespace: recoverableDeletion.namespace
                )
                recoveryOperations.append((attachmentID, operation))
            } else {
                registry.cancelPendingDeletion(
                    attachmentID: attachmentID,
                    namespace: registryNamespace
                )
            }
        }
        let pendingAttachmentIDs = registry.pendingAttachmentIDs(in: registryNamespace)
        let currentSessionPendingAttachmentIDs = Set(
            currentSessionPendingNamespaces.compactMap { attachmentID, namespace in
                namespace == registryNamespace ? attachmentID : nil
            }
        )
        let orphanedAttachmentIDs = pendingAttachmentIDs
            .subtracting(referencedAttachmentIDs)
            .subtracting(currentSessionPendingAttachmentIDs)
        pendingAttachmentIDs.intersection(referencedAttachmentIDs).forEach {
            registry.markCommitted(attachmentID: $0, namespace: registryNamespace)
            currentSessionPendingNamespaces[$0] = nil
        }
        let attachmentIDsToDelete = orphanedAttachmentIDs.union(
            registry.pendingDeletionAttachmentIDs(in: registryNamespace)
                .subtracting(referencedAttachmentIDs)
        )
        requestLock.unlock()

        cancelledOperations.forEach(cancelDeletion)
        recoveryOperations.forEach {
            finishAcceptedDeletion(
                attachmentID: $0.attachmentID,
                operation: $0.operation
            )
        }

        for attachmentID in attachmentIDsToDelete {
            group.enter()
            delete(attachmentID: attachmentID) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main, execute: completion)
    }

    private func registerPendingUpload(attachmentID: String, namespace: String) {
        requestLock.lock()
        currentSessionPendingNamespaces[attachmentID] = namespace
        attachmentNamespaces[attachmentID] = namespace
        registry.recordPending(attachmentID: attachmentID, namespace: namespace)
        requestLock.unlock()
    }

    private func retainDeletion(
        _ request: AnyCancellable,
        attachmentID: String,
        operation: DeletionOperation
    ) {
        requestLock.lock()
        guard deletionOperations[attachmentID] === operation else {
            requestLock.unlock()
            request.cancel()
            return
        }
        operation.cancellable = request
        requestLock.unlock()
    }

    private func finishAcceptedDeletion(
        attachmentID: String,
        operation: DeletionOperation
    ) {
        let backup: Response.FileResponse
        let reference: ECGReportAttachmentReference
        let recovery: (String, ECGReportAttachment, @escaping (Result<Void, Error>) -> Void) -> Void
        requestLock.lock()
        guard deletionOperations[attachmentID] === operation else {
            requestLock.unlock()
            return
        }
        guard
            let storedBackup = operation.backup,
            let restoredReference = operation.restoredReference,
            let storedRecovery = operation.recovery
        else {
            requestLock.unlock()
            finishDeletion(
                attachmentID: attachmentID,
                operation: operation,
                result: .success(())
            )
            return
        }
        backup = storedBackup
        reference = restoredReference
        recovery = storedRecovery
        operation.phase = .recovering
        requestLock.unlock()

        let request = uploadRequest(
            backup.data,
            reference.attachment.fileName,
            .documents,
            backup.metadata.encryptedFileKey,
            backup.metadata.hashFileKey
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            guard case .failure = result else { return }
            self?.finishFailedRecovery(
                attachmentID: attachmentID,
                operation: operation
            )
        } receiveValue: { [weak self] response in
            guard let self else { return }
            guard
                response.metadata.attachmentID.isEmpty == false,
                response.metadata.location == Request.AttachmentLocation.documents.rawValue,
                response.metadata.fileName.isEmpty ||
                    response.metadata.fileName == reference.attachment.fileName,
                response.metadata.encryptedFileKey.caseInsensitiveCompare(
                    backup.metadata.encryptedFileKey
                ) == .orderedSame,
                response.metadata.hashFileKey.caseInsensitiveCompare(
                    backup.metadata.hashFileKey
                ) == .orderedSame,
                let replacement = ECGReportAttachment(
                    attachmentID: response.metadata.attachmentID,
                    fileName: reference.attachment.fileName,
                    encryptedFileKey: backup.metadata.encryptedFileKey,
                    hashFileKey: backup.metadata.hashFileKey,
                    sourceSampleUUID: reference.attachment.sourceSampleUUID,
                    lead: reference.attachment.lead,
                    format: reference.attachment.format,
                    mimeType: reference.attachment.mimeType
                )
            else {
                self.finishFailedRecovery(
                    attachmentID: attachmentID,
                    operation: operation
                )
                return
            }
            recovery(attachmentID, replacement) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.finishRecoveredDeletion(
                        attachmentID: attachmentID,
                        replacement: replacement,
                        reference: reference,
                        operation: operation
                    )
                case .failure:
                    self.registry.recordPending(
                        attachmentID: replacement.attachmentID,
                        namespace: operation.namespace
                    )
                    self.finishFailedRecovery(
                        attachmentID: attachmentID,
                        operation: operation
                    )
                }
            }
        }
        retainDeletion(request, attachmentID: attachmentID, operation: operation)
    }

    private func finishRecoveredDeletion(
        attachmentID: String,
        replacement: ECGReportAttachment,
        reference: ECGReportAttachmentReference,
        operation: DeletionOperation
    ) {
        let completions: [(Result<Void, Error>) -> Void]
        requestLock.lock()
        guard deletionOperations[attachmentID] === operation else {
            requestLock.unlock()
            return
        }
        deletionOperations[attachmentID] = nil
        recoverableDeletions[attachmentID] = nil
        registry.remove(
            attachmentID: attachmentID,
            namespace: operation.namespace
        )
        registry.recordCommitted(
            attachmentID: replacement.attachmentID,
            ownerID: reference.ownerID,
            namespace: operation.namespace
        )
        attachmentNamespaces[attachmentID] = nil
        attachmentNamespaces[replacement.attachmentID] = operation.namespace
        completions = operation.completions
        requestLock.unlock()
        completions.forEach {
            $0(.failure(ECGReportAttachmentStoreError.deletionCancelled))
        }
    }

    private func finishFailedRecovery(
        attachmentID: String,
        operation: DeletionOperation
    ) {
        requestLock.lock()
        if
            deletionOperations[attachmentID] === operation,
            let backup = operation.backup {
            recoverableDeletions[attachmentID] = RecoverableDeletion(
                namespace: operation.namespace,
                backup: backup
            )
        }
        requestLock.unlock()
        finishDeletion(
            attachmentID: attachmentID,
            operation: operation,
            result: .failure(ECGReportAttachmentStoreError.deletionRecoveryFailed)
        )
    }

    private func finishDeletion(
        attachmentID: String,
        operation: DeletionOperation,
        result: Result<Void, Error>
    ) {
        let completions: [(Result<Void, Error>) -> Void]
        requestLock.lock()
        guard deletionOperations[attachmentID] === operation else {
            requestLock.unlock()
            return
        }
        deletionOperations[attachmentID] = nil
        if case .success = result {
            if let backup = operation.backup {
                recoverableDeletions[attachmentID] = RecoverableDeletion(
                    namespace: operation.namespace,
                    backup: backup
                )
            }
            registry.remove(
                attachmentID: attachmentID,
                namespace: operation.namespace
            )
            attachmentNamespaces[attachmentID] = nil
        }
        completions = operation.completions
        requestLock.unlock()
        completions.forEach { $0(result) }
    }

    private func cancelDeletion(_ operation: DeletionOperation?) {
        guard let operation else { return }
        operation.cancellable?.cancel()
        operation.completions.forEach {
            $0(.failure(ECGReportAttachmentStoreError.deletionCancelled))
        }
    }

    private func makeFileName(sourceSampleUUID: UUID?) -> String {
        let identifier = sourceSampleUUID?.uuidString ?? UUID().uuidString
        return "MagicBox-ECG-\(identifier).pdf"
    }

    private func finishRequest(_ requestID: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.requestLock.lock()
            self.activeRequests[requestID] = nil
            self.requestLock.unlock()
        }
    }

    private func retain(_ request: AnyCancellable, requestID: UUID) {
        requestLock.lock()
        activeRequests[requestID] = request
        requestLock.unlock()
    }

    private func rememberNamespace(_ namespace: String, attachmentID: String) {
        requestLock.lock()
        attachmentNamespaces[attachmentID] = namespace
        requestLock.unlock()
    }
}
