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
import OTFCareKitStore
import OTFTemplateBox
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("Update user view model")
struct UpdateUserViewModelTests {
    @Test("Upload profile file persists response and publishes completion")
    func uploadProfileFilePersistsResponseAndPublishesCompletion() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        let notificationCenter = NotificationCenter()
        var capturedUpload: (data: Data, fileName: String, encryptedFileKey: String?, hashFileKey: String)?
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            notificationCenter: notificationCenter,
            uploadFileRequest: { data, fileName, encryptedFileKey, hashFileKey in
                capturedUpload = (data, fileName, encryptedFileKey, hashFileKey)
                return Just(Response.FileResponse(
                    metadata: makeUpdateUserMetadata(attachmentID: "new-profile-id", hashFileKey: "server-hash"),
                    data: Data([1, 2, 3])
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            }
        )
        let databaseSyncTask = Task {
            try await firstNotification(named: .databaseSynchronized, center: notificationCenter)
        }
        let completionTask = Task {
            try await firstValue(from: model.profileUpdateComplete)
        }
        let imageDataTask = Task {
            try await firstValue(from: model.profileImageData)
        }

        model.uploadFile(data: Data([9, 8]), fileName: "profile.jpg", encryptedFileKey: "encrypted-file", hashFileKey: "local-hash")

        _ = try await completionTask.value
        _ = try await databaseSyncTask.value
        let imageData = try await imageDataTask.value
        #expect(capturedUpload?.data == Data([9, 8]))
        #expect(capturedUpload?.fileName == "profile.jpg")
        #expect(capturedUpload?.encryptedFileKey == "encrypted-file")
        #expect(capturedUpload?.hashFileKey == "local-hash")
        #expect(fileStore.writes["new-profile-id"] == Data([1, 2, 3]))
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) == "new-profile-id")
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileHashFileKey) == "local-hash")
        #expect(imageData == Data([1, 2, 3]))
        #expect(!model.isLoading)
    }

    @Test("Download non-profile file stores attachment keys")
    func downloadNonProfileFileStoresAttachmentKeys() async throws {
        let fileStore = UpdateUserFakeFileStore()
        let model = makeUpdateUserViewModel(
            fileStore: fileStore,
            downloadFileRequest: { attachmentID in
                #expect(attachmentID == "remote-id")
                return Just(Response.FileResponse(
                    metadata: makeUpdateUserMetadata(
                        attachmentID: "downloaded-id",
                        hashFileKey: "downloaded-hash",
                        encryptedFileKey: "downloaded-key"
                    ),
                    data: Data([4, 5, 6])
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            }
        )

        model.downloadFile(attachmentID: "remote-id", isProfile: false)

        try await waitUntil { model.attachmentKeys["downloaded-id"]?.hashFileKey == "downloaded-hash" && !model.isLoading }
        #expect(model.attachmentKeys["downloaded-id"]?.encryptedFileKey == "downloaded-key")
        #expect(fileStore.writes["downloaded-id"] == Data([4, 5, 6]))
    }

    @Test("Delete file synchronizes and completes even on success")
    func deleteFileSynchronizesAndCompletesEvenOnSuccess() async throws {
        let notificationCenter = NotificationCenter()
        var deletedAttachmentID: String?
        let model = makeUpdateUserViewModel(
            notificationCenter: notificationCenter,
            deleteFileRequest: { attachmentID in
                deletedAttachmentID = attachmentID
                return Just(Response.DeleteFile(error: false, message: "Deleted", statusCode: 200))
                    .setFailureType(to: ForgeError.self)
                    .eraseToAnyPublisher()
            }
        )
        let databaseSyncSpy = NotificationSpy(name: .databaseSynchronized, center: notificationCenter)
        var didComplete = false
        let completionCancellable = model.profileUpdateComplete.sink { didComplete = true }
        defer { completionCancellable.cancel() }

        model.deleteFile(attachmentID: "old-profile-id")

        try await waitUntil {
            didComplete && databaseSyncSpy.notifications.count == 1 && !model.isLoading
        }
        #expect(databaseSyncSpy.notifications.count == 1)
        #expect(deletedAttachmentID == "old-profile-id")
        #expect(model.profileImage == nil)
        #expect(!model.isLoading)
    }

    @Test("Profile image download skips duplicate request while same hash is in flight")
    func profileImageDownloadSkipsDuplicateRequestWhileSameHashIsInFlight() throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        let downloadSubject = PassthroughSubject<Response.FileResponse, ForgeError>()
        var requestedAttachmentIDs = [String]()
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            downloadFileRequest: { attachmentID in
                requestedAttachmentIDs.append(attachmentID)
                return downloadSubject.eraseToAnyPublisher()
            }
        )
        let patient = try makeUpdateUserPatient(attachmentID: "remote-profile", hashFileKey: "server-hash")

        model.ensureProfileImage(for: patient)
        model.ensureProfileImage(for: patient)

        #expect(requestedAttachmentIDs == ["remote-profile"])
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) == "remote-profile")
    }

    @Test("Profile image uses disk cache when server hash is unchanged")
    func profileImageUsesDiskCacheWhenServerHashIsUnchanged() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        isolatedDefaults.defaults.set("cached-profile", forKey: Constants.Storage.kLastProfileAttachmentID)
        isolatedDefaults.defaults.set("server-hash", forKey: Constants.Storage.kLastProfileHashFileKey)
        fileStore.reads["cached-profile"] = Data([1, 2, 3])
        var requestedAttachmentIDs = [String]()
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            downloadFileRequest: { attachmentID in
                requestedAttachmentIDs.append(attachmentID)
                return Empty().eraseToAnyPublisher()
            }
        )
        let patient = try makeUpdateUserPatient(attachmentID: "cached-profile", hashFileKey: "server-hash")

        model.ensureProfileImage(for: patient)

        try await waitUntil { model.profileImage != nil }
        #expect(requestedAttachmentIDs.isEmpty)
        #expect(fileStore.removals.isEmpty)
    }

    @Test("Profile image content change invalidates old cache and stores downloaded hash")
    func profileImageContentChangeInvalidatesOldCacheAndStoresDownloadedHash() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        let notificationCenter = NotificationCenter()
        isolatedDefaults.defaults.set("old-profile", forKey: Constants.Storage.kLastProfileAttachmentID)
        isolatedDefaults.defaults.set("old-hash", forKey: Constants.Storage.kLastProfileHashFileKey)
        fileStore.writes["old-profile"] = Data([0])
        var requestedAttachmentIDs = [String]()
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            notificationCenter: notificationCenter,
            downloadFileRequest: { attachmentID in
                requestedAttachmentIDs.append(attachmentID)
                return Just(Response.FileResponse(
                    metadata: makeUpdateUserMetadata(attachmentID: attachmentID, hashFileKey: "new-hash"),
                    data: Data([9, 9, 9])
                ))
                .setFailureType(to: ForgeError.self)
                .eraseToAnyPublisher()
            }
        )
        let downloadTask = Task {
            try await firstNotification(named: .imageDownloaded, center: notificationCenter)
        }
        let patient = try makeUpdateUserPatient(attachmentID: "new-profile", hashFileKey: "new-hash")

        model.ensureProfileImage(for: patient)

        _ = try await downloadTask.value
        try await waitUntil { !model.isLoading }
        #expect(requestedAttachmentIDs == ["new-profile"])
        #expect(fileStore.removals == ["old-profile"])
        #expect(fileStore.writes["new-profile"] == Data([9, 9, 9]))
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) == "new-profile")
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileHashFileKey) == "new-hash")
    }

    @Test("Profile image download failure clears in-flight guard for retry")
    func profileImageDownloadFailureClearsInFlightGuardForRetry() async throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        var requestedAttachmentIDs = [String]()
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            downloadFileRequest: { attachmentID in
                requestedAttachmentIDs.append(attachmentID)
                return Fail(error: makeUpdateUserForgeError(message: "Download failed"))
                    .eraseToAnyPublisher()
            }
        )
        let patient = try makeUpdateUserPatient(attachmentID: "remote-profile", hashFileKey: "server-hash")

        model.ensureProfileImage(for: patient)
        try await waitUntil { requestedAttachmentIDs.count == 1 && !model.isLoading }
        model.ensureProfileImage(for: patient)

        try await waitUntil { requestedAttachmentIDs.count == 2 && !model.isLoading }
        #expect(requestedAttachmentIDs == ["remote-profile", "remote-profile"])
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileHashFileKey) == nil)
    }

    @Test("Profile image removal clears local cache and server defaults")
    func profileImageRemovalClearsLocalCacheAndServerDefaults() throws {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        let fileStore = UpdateUserFakeFileStore()
        let thumbnailer = UpdateUserFakeThumbnailer()
        isolatedDefaults.defaults.set("old-profile", forKey: Constants.Storage.kLastProfileAttachmentID)
        isolatedDefaults.defaults.set("old-hash", forKey: Constants.Storage.kLastProfileHashFileKey)
        fileStore.writes["old-profile"] = Data([1])
        let model = makeUpdateUserViewModel(
            defaults: isolatedDefaults.defaults,
            fileStore: fileStore,
            thumbnailer: thumbnailer
        )
        let patient = OCKPatient(id: "patient", givenName: "Test", familyName: "Patient")

        model.ensureProfileImage(for: patient)

        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) == nil)
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileHashFileKey) == nil)
        #expect(fileStore.removals == ["old-profile"])
    }

    @Test("Profile image removal without cached file completes locally")
    func profileImageRemovalWithoutCachedFileCompletesLocally() async throws {
        var deleteCount = 0
        let model = makeUpdateUserViewModel(
            deleteFileRequest: { _ in
                deleteCount += 1
                return Empty().eraseToAnyPublisher()
            }
        )
        var didCompleteProfileUpdate = false
        let completionCancellable = model.profileUpdateComplete
            .sink { didCompleteProfileUpdate = true }
        defer { completionCancellable.cancel() }

        model.updatePatientImage(newImage: nil)

        try await waitUntil { didCompleteProfileUpdate }
        #expect(deleteCount == 0)
        #expect(!model.isLoading)
    }

    @Test("Profile image hash failure clears loading without upload")
    func profileImageHashFailureClearsLoadingWithoutUpload() async throws {
        let imageProcessor = UpdateUserFakeImageProcessor(
            jpegData: Data([1, 2, 3]),
            hashError: UpdateUserFakeImageProcessorError.hashFailed
        )
        var uploadCount = 0
        let model = makeUpdateUserViewModel(
            imageProcessor: imageProcessor,
            uploadFileRequest: { _, _, _, _ in
                uploadCount += 1
                return Empty().eraseToAnyPublisher()
            }
        )

        model.updatePatientImage(newImage: UIImage())

        try await waitUntil { !model.isLoading }
        #expect(uploadCount == 0)
        #expect(model.profileImage != nil)
    }

    @Test("Upload profile file failure clears loading without completion")
    func uploadProfileFileFailureClearsLoadingWithoutCompletion() async throws {
        let model = makeUpdateUserViewModel(
            uploadFileRequest: { _, _, _, _ in
                Fail(error: makeUpdateUserForgeError(message: "Upload failed"))
                    .eraseToAnyPublisher()
            }
        )
        var didComplete = false
        let cancellable = model.profileUpdateComplete.sink { didComplete = true }
        defer { cancellable.cancel() }
        model.isLoading = true

        model.uploadFile(data: Data([1]), fileName: "profile.jpg", hashFileKey: "hash")

        try await waitUntil { !model.isLoading }
        #expect(!didComplete)
    }

    @Test("Delete file failure still synchronizes and completes")
    func deleteFileFailureStillSynchronizesAndCompletes() async throws {
        let notificationCenter = NotificationCenter()
        var deletedAttachmentID: String?
        let model = makeUpdateUserViewModel(
            notificationCenter: notificationCenter,
            deleteFileRequest: { attachmentID in
                deletedAttachmentID = attachmentID
                return Fail(error: makeUpdateUserForgeError(message: "Delete failed"))
                    .eraseToAnyPublisher()
            }
        )
        let databaseSyncSpy = NotificationSpy(name: .databaseSynchronized, center: notificationCenter)
        var didComplete = false
        let completionCancellable = model.profileUpdateComplete.sink { didComplete = true }
        defer { completionCancellable.cancel() }

        model.deleteFile(attachmentID: "old-profile-id")

        try await waitUntil {
            didComplete && databaseSyncSpy.notifications.count == 1 && !model.isLoading
        }
        #expect(databaseSyncSpy.notifications.count == 1)
        #expect(deletedAttachmentID == "old-profile-id")
        #expect(!model.isLoading)
    }

    @Test("Update patient image uses injected processor for deterministic upload")
    func updatePatientImageUsesInjectedProcessorForDeterministicUpload() async throws {
        let imageProcessor = UpdateUserFakeImageProcessor(
            jpegData: Data([7, 7, 7]),
            hashHex: "hash-777",
            fileName: "deterministic.jpg"
        )
        var capturedUpload: (data: Data, fileName: String, hashFileKey: String)?
        let model = makeUpdateUserViewModel(
            imageProcessor: imageProcessor,
            uploadFileRequest: { data, fileName, _, hashFileKey in
                capturedUpload = (data, fileName, hashFileKey)
                return Empty().eraseToAnyPublisher()
            }
        )

        model.updatePatientImage(newImage: UIImage())

        try await waitUntil {
            capturedUpload?.data == Data([7, 7, 7])
        }
        #expect(capturedUpload?.fileName == "deterministic.jpg")
        #expect(capturedUpload?.hashFileKey == "hash-777")
        #expect(imageProcessor.jpegRequests.count == 1)
    }

    @Test("Update patient image clears loading when image processing fails")
    func updatePatientImageClearsLoadingWhenImageProcessingFails() async throws {
        let imageProcessor = UpdateUserFakeImageProcessor(jpegData: nil)
        let model = makeUpdateUserViewModel(imageProcessor: imageProcessor)

        model.updatePatientImage(newImage: UIImage())

        try await waitUntil { !model.isLoading }
        #expect(model.profileImage != nil)
    }
}

private final class UpdateUserFakeFileStore: ProfileImageFileStoring {
    var reads = [String: Data]()
    var writes = [String: Data]()
    var removals = [String]()

    func read(filename: String) throws -> Data {
        guard let data = reads[filename] else { throw UpdateUserFakeFileStoreError.missingFile }
        return data
    }

    func write(filename: String, data: Data) throws {
        writes[filename] = data
    }

    func remove(filename: String) {
        removals.append(filename)
        writes.removeValue(forKey: filename)
        reads.removeValue(forKey: filename)
    }
}

private enum UpdateUserFakeFileStoreError: Error {
    case missingFile
}

private final class UpdateUserFakeThumbnailer: ProfileThumbnailing {
    private(set) var removedKeys = [String]()

    func remove(forKey key: String) async {
        removedKeys.append(key)
    }

    func thumbnail(from data: Data, request: Thumbnailer.Request) async throws -> UIImage {
        UIImage()
    }
}

private final class UpdateUserFakeImageProcessor: ProfileImageProcessing {
    private let jpegDataResult: Data?
    private let hashHexResult: String
    private let fileNameResult: String
    private let hashError: Error?
    private(set) var jpegRequests = [(maxDimension: CGFloat, compressionQuality: CGFloat)]()

    init(
        jpegData: Data?,
        hashHex: String = "hash",
        fileName: String = "profile.jpg",
        hashError: Error? = nil
    ) {
        self.jpegDataResult = jpegData
        self.hashHexResult = hashHex
        self.fileNameResult = fileName
        self.hashError = hashError
    }

    func jpegData(from image: UIImage, maxDimension: CGFloat, compressionQuality: CGFloat) -> Data? {
        jpegRequests.append((maxDimension, compressionQuality))
        return jpegDataResult
    }

    func hashHex(for data: Data) throws -> String {
        if let hashError {
            throw hashError
        }
        return hashHexResult
    }

    func makeProfileImageFilename() -> String {
        fileNameResult
    }
}

private enum UpdateUserFakeImageProcessorError: Error {
    case hashFailed
}

private func makeUpdateUserViewModel(
    defaults: UserDefaults? = nil,
    fileStore: ProfileImageFileStoring = UpdateUserFakeFileStore(),
    thumbnailer: ProfileThumbnailing = UpdateUserFakeThumbnailer(),
    imageProcessor: ProfileImageProcessing = UpdateUserFakeImageProcessor(jpegData: Data([1])),
    notificationCenter: NotificationCenter = NotificationCenter(),
    uploadFileRequest: @escaping (Data, String, String?, String) -> AnyPublisher<Response.FileResponse, ForgeError> = { _, _, _, _ in
        Empty().eraseToAnyPublisher()
    },
    downloadFileRequest: @escaping (String) -> AnyPublisher<Response.FileResponse, ForgeError> = { _ in
        Empty().eraseToAnyPublisher()
    },
    deleteFileRequest: @escaping (String) -> AnyPublisher<Response.DeleteFile, ForgeError> = { _ in
        Empty().eraseToAnyPublisher()
    }
) -> UpdateUserViewModel {
    UpdateUserViewModel(
        decoder: UpdateUserFakeYAMLDecoder(),
        defaults: defaults ?? UserDefaults(suiteName: UUID().uuidString)!,
        fileStore: fileStore,
        thumbnailer: thumbnailer,
        imageProcessor: imageProcessor,
        notificationCenter: notificationCenter,
        uploadFileRequest: uploadFileRequest,
        downloadFileRequest: downloadFileRequest,
        deleteFileRequest: deleteFileRequest
    )
}

private struct UpdateUserFakeYAMLDecoder: OTFYAMLDecoding {
    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        guard file == "UpdateUserProfileConfiguration",
              let config = UpdateUserProfileConfiguration.fallback as? T
        else {
            throw UpdateUserFakeYAMLDecoderError.missingStub
        }
        return config
    }
}

private enum UpdateUserFakeYAMLDecoderError: Error {
    case missingStub
}

private func makeUpdateUserForgeError(message: String, statusCode: Int = 500) -> ForgeError {
    ForgeError(error: .init(statusCode: statusCode, name: "Test", message: message, code: nil))
}

private func makeUpdateUserMetadata(
    attachmentID: String,
    hashFileKey: String,
    encryptedFileKey: String = "encrypted-key"
) -> Response.Metadata {
    Response.Metadata(
        contentType: "image/jpeg",
        revpos: "1",
        hashFileKey: hashFileKey,
        encryptedFileKey: encryptedFileKey,
        location: "profile",
        fileName: "\(attachmentID).jpg",
        owner: "owner",
        attrev: 1,
        length: 3,
        stub: false,
        attachmentID: attachmentID
    )
}

private func makeUpdateUserPatient(attachmentID: String, hashFileKey: String) throws -> OCKPatient {
    var patient = OCKPatient(id: "patient-id", givenName: "Test", familyName: "Patient")
    let data = try JSONSerialization.data(withJSONObject: [
        "profile": [
            "contentType": "image/jpeg",
            "revpos": "1",
            "hashFileKey": hashFileKey,
            "encryptedFileKey": "encrypted",
            "location": "profile",
            "fileName": "\(attachmentID).jpg",
            "owner": "owner",
            "attrev": 1,
            "length": 3,
            "stub": false,
            "attachmentID": attachmentID
        ]
    ])
    let attachments = try #require(String(bytes: data, encoding: .utf8))
    patient.userInfo = ["attachments": attachments]
    return patient
}
