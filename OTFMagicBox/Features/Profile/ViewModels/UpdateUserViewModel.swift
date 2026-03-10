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

import Foundation
import OTFCareKitStore
import Combine
import OTFUtilities
import OTFCloudantStore
import Sodium
import OTFTemplateBox

final class UpdateUserViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName = "UpdateUserProfileConfiguration"
        static let maxDimension: CGFloat = 512
        static let compressionQuality: CGFloat = 0.85
    }

    struct AttachmentKeys {
        let hashFileKey: String
        let encryptedFileKey: String
    }

    // MARK: Publishers

    @Published private(set) var config: UpdateUserProfileConfiguration = .fallback
    @Published private(set) var attachmentKeys: [String: AttachmentKeys] = [:]
    @Published var profileImage: UIImage?
    @Published var isLoading = false

    // MARK: - Properties

    var disposables = Set<AnyCancellable>()
    var patientPublisher = PassthroughSubject<OCKPatient, Never>()
    var profileImageData = PassthroughSubject<Data, Never>()
    var hideLoader = PassthroughSubject<Bool, Never>()
    var profileUpdateComplete = PassthroughSubject<Void, Never>()

    let swiftSodium = SwiftSodium()

    private let attachmentIDKey = Constants.Storage.kLastProfileAttachmentID
    private let hashFileKeyKey = Constants.Storage.kLastProfileHashFileKey
    private let logger = OTFLogger.logger()
    private let decoder: OTFYAMLDecoding

    /// Guards against concurrent profile downloads
    private var isDownloadingProfile = false
    /// Hash key of the image currently being downloaded (set when download starts, cleared when it completes)
    private var pendingProfileHashKey: String?

    private var shouldDismissView = false {
        didSet {
            hideLoader.send(shouldDismissView)
        }
    }

    private var patient: OCKPatient? {
        didSet {
            if let patient = patient {
                patientPublisher.send(patient)
            }
        }
    }

    // MARK: - Init

    init(decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine()) {
        self.decoder = decoder
        loadConfiguration()
    }

    // MARK: - Methods

    private func loadConfiguration() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: UpdateUserProfileConfiguration.self)
        } catch {
            OTFLogger.logger().error("Update Profile config load error: \(error)")
            config = .fallback
        }
    }

    /// Fetches updated patient data from the database
    func fetchUserFromDB() {
        CareKitStoreManager.shared.cloudantStore?.getThisPatient({ [weak self] result in
            guard let self else { return }
            if case .success(let patient) = result {
                self.patient = patient
            }
        })
    }

    /// Best-effort load of the profile image from disk.
    func loadProfileImageFromDiskIfAvailable() {
        guard profileImage == nil else { return }
        guard let id = UserDefaults.standard.string(forKey: attachmentIDKey),
              let data = try? FileManager.readFromDocuments(filename: id)
        else { return }
        setProfileThumbnail(from: data, key: id)
    }

    /// Ensures we have the correct profile image for the given user.
    /// Uses hashFileKey to detect content changes (since attachmentID stays the same on updates).
    /// Offline-first: Loads from disk cache first, then downloads if needed.
    func ensureProfileImage(for user: OCKPatient) {
        let defaults = UserDefaults.standard
        let cachedHashKey = defaults.string(forKey: hashFileKeyKey)
        
        guard let profileAttachment = user.attachments?.profile else {
            // No profile attachment - clear any cached image
            if defaults.string(forKey: attachmentIDKey) != nil {
                invalidateProfileCache(attachmentID: defaults.string(forKey: attachmentIDKey))
                defaults.removeObject(forKey: attachmentIDKey)
                defaults.removeObject(forKey: hashFileKeyKey)
            }
            return
        }
        
        let serverAttachmentID = profileAttachment.attachmentID
        let serverHashKey = profileAttachment.hashFileKey
        
        // Case 1: Already downloading this exact version
        if isDownloadingProfile && pendingProfileHashKey == serverHashKey {
            logger.info("Already downloading profile image with hash \(serverHashKey), skipping duplicate request.")
            return
        }
        
        // Case 2: Content has changed (comparing hash)
        let contentChanged = (serverHashKey != cachedHashKey)
        
        if contentChanged {
            logger.info("Profile content changed (hash: \(cachedHashKey ?? "nil") -> \(serverHashKey)). Downloading new image.")
            
            // Invalidate old cache and clear memory
            invalidateProfileCache(attachmentID: defaults.string(forKey: attachmentIDKey))
            
            // Update attachment ID now (for file storage), but NOT hashKey yet
            // hashKey will be updated after successful download
            defaults.set(serverAttachmentID, forKey: attachmentIDKey)
            
            // Start download
            startProfileDownload(attachmentID: serverAttachmentID, hashKey: serverHashKey)
        } else {
            // Case 3: Content unchanged - use memory or disk
            if profileImage != nil {
                return // Already in memory
            }
            
            // Try loading from disk
            if let id = defaults.string(forKey: attachmentIDKey),
               (try? FileManager.readFromDocuments(filename: id)) != nil {
                loadProfileImageFromDiskIfAvailable()
            } else if !isDownloadingProfile {
                // File not on disk and not downloading, initiate download
                startProfileDownload(attachmentID: serverAttachmentID, hashKey: serverHashKey)
            }
        }
    }

    /// Starts a profile image download with proper guards
    private func startProfileDownload(attachmentID: String, hashKey: String) {
        isDownloadingProfile = true
        pendingProfileHashKey = hashKey
        downloadFile(attachmentID: attachmentID, isProfile: true)
    }

    /// Clears old profile image from memory, disk, and thumbnail cache.
    private func invalidateProfileCache(attachmentID: String?) {
        profileImage = nil

        if let attachmentID {
            // Remove from Thumbnailer cache
            Task {
                await Thumbnailer.shared.remove(forKey: attachmentID)
            }
            // Remove from Documents directory
            if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docsURL.appendingPathComponent(attachmentID)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Updates a patient's information in the database
    /// - Parameters:
    ///   - user: The patient object with updated information
    ///   - imageUpdated: Boolean flag indicating if the profile image was updated
    ///   - newImage: Optional new image to be used as profile picture
    func updatePatient(user: OCKPatient, imageUpdated: Bool, newImage: UIImage?) {
        CareKitStoreManager.shared.cloudantStore?.updatePatient(user) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let updatedPatient):
                self.patient = updatedPatient
                if imageUpdated {
                    self.updatePatientImage(newImage: newImage)
                } else {
                    self.isLoading = false
                    self.synchronizeDatabase()
                    self.profileUpdateComplete.send()
                }
            case .failure(let error):
                self.isLoading = false
                logger.error("Failed to update patient: \(error)")
            }
        }
    }

    /// Updates only the patient's profile image
    /// - Parameter newImage: Optional new image to be used as profile picture
    func updatePatientImage(newImage: UIImage?) {
        // Case 1: Image deleted (nil)
        guard let img = newImage else {
            // User removed the profile picture: clear local cache and files
            if let oldID = UserDefaults.standard.string(forKey: attachmentIDKey) {
                invalidateProfileCache(attachmentID: oldID)
                UserDefaults.standard.removeObject(forKey: attachmentIDKey)
                UserDefaults.standard.removeObject(forKey: hashFileKeyKey)
                
                // Call server API to delete the file
                deleteFile(attachmentID: oldID)
            } else {
                // No ID to delete, just finish
                isLoading = false
                profileUpdateComplete.send()
            }
            return
        }

        // Case 2: New image provided (update)
        // Immediately update the UI with the selected image
        // Set loading state to ensure View Update triggers when we finish
        profileImage = img
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            // Resize image and convert to JPEG for smaller upload
            let resizedImage = img.resizedToFit(maxDimension: FileConstants.maxDimension)
            guard let imageData = resizedImage.jpegData(compressionQuality: FileConstants.compressionQuality) else {
                self.logger.error("updatePatientImage: failed to create JPEG data")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            do {
                let bytesImage: Bytes = Array(imageData)
                let hashKeyFile: Bytes = try swiftSodium.genericHash(message: bytesImage)
                let hashKeyFileHex = hashKeyFile.bytesToHex(spacing: "").lowercased()
                let uuid = UUID().uuidString + ".jpg"

                DispatchQueue.main.async {
                    self.uploadFile(data: imageData, fileName: uuid, encryptedFileKey: nil, hashFileKey: hashKeyFileHex)
                }
            } catch {
                logger.error("updatePatientImage: hashing failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - File Management Methods

    /// Uploads a file to the server
    /// - Parameters:
    ///   - data: The data to be uploaded
    ///   - fileName: Name to assign to the file
    ///   - encryptedFileKey: Optional encrypted key for the file
    ///   - hashFileKey: Hash key generated for the file
    func uploadFile(data: Data, fileName: String, encryptedFileKey: String? = nil, hashFileKey: String) {
        OTFTheraforgeNetwork.shared
            .uploadFile(data: data, fileName: fileName, type: .profile, encryptedFileKey: encryptedFileKey, hashFileKey: hashFileKey)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] res in
                guard let self = self else { return }
                if case .failure(let error) = res {
                    Task { @MainActor in
                        self.isLoading = false
                        self.logger.error("uploadFile (profile) failed: \(error.localizedDescription)")
                    }
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }

                let imageData = response.data
                let attachmentID = response.metadata.attachmentID

                // 1) Persist full image on disk (background)
                do {
                    try FileManager.writeToDocuments(filename: attachmentID, data: imageData)
                } catch {
                    self.logger.warning("uploadFile: failed to save to Documents: \(error.localizedDescription)")
                }

                // 2) Generate + publish thumbnail (background decoding via Thumbnailer)
                self.setProfileThumbnail(from: imageData, key: attachmentID)

                // 3) Publish side-effects & UI (main)
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let defaults = UserDefaults.standard
                    
                    // Capture old ID for cleanup *after* we successfully secure the new one
                    let oldID = defaults.string(forKey: self.attachmentIDKey)
                    
                    defaults.set(attachmentID, forKey: self.attachmentIDKey)
                    defaults.set(hashFileKey, forKey: self.hashFileKeyKey)
                    
                    // Safe post-upload cleanup:
                    // Only delete the old file if it's different from the new one
                    if let oldID, oldID != attachmentID {
                        self.invalidateProfileCache(attachmentID: oldID)
                    }
                    
                    // broadcasting original bytes if others need them
                    self.profileImageData.send(imageData)
                    self.synchronizeDatabase()
                    self.profileUpdateComplete.send()
                    self.isLoading = false
                }
            }
            .store(in: &disposables)
    }

    /// Downloads a file from the server and save it to the doccument   direcctory
    /// - Parameters:
    ///   - attachmentID: The unique identifier for the attachment
    ///   - isProfile: Flag indicating if the download is for a profile image
    func downloadFile(attachmentID: String, isProfile: Bool = false) {
        isLoading = true

        OTFTheraforgeNetwork.shared
            .downloadFile(attachmentID: attachmentID, type: .profile)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] completion in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isLoading = false
                    if isProfile {
                        // Clear download guards on completion (success or failure)
                        self.isDownloadingProfile = false
                    }
                    if case .failure(let error) = completion {
                        self.logger.error("downloadFile failed: \(error.localizedDescription)")
                        if isProfile {
                            self.pendingProfileHashKey = nil
                        }
                    }
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }

                let fileData = response.data
                let meta = response.metadata
                let downloadedAttachmentID = meta.attachmentID

                do {
                    try FileManager.writeToDocuments(filename: downloadedAttachmentID, data: fileData)
                } catch {
                    self.logger.warning("downloadFile: failed to save to Documents: \(error.localizedDescription)")
                }

                if isProfile {
                    self.setProfileThumbnail(from: fileData, key: downloadedAttachmentID)

                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        // save the hashKey after successful download
                        if let pendingHash = self.pendingProfileHashKey {
                            UserDefaults.standard.set(pendingHash, forKey: self.hashFileKeyKey)
                        }
                        self.pendingProfileHashKey = nil
                        NotificationCenter.default.post(name: .imageDownloaded, object: ["imageData": fileData])
                    }
                } else {
                    DispatchQueue.main.async {
                        self.attachmentKeys[downloadedAttachmentID] = AttachmentKeys(
                            hashFileKey: meta.hashFileKey,
                            encryptedFileKey: meta.encryptedFileKey
                        )
                    }
                }
            }
            .store(in: &disposables)
    }

    /// Deletes an attachment from the server
    /// - Parameter attachmentID: The unique identifier for the attachment to delete
    func deleteFile(attachmentID: String) {
        isLoading = true
        
        OTFTheraforgeNetwork.shared.deleteFile(attachmentID: attachmentID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.logger.error("Failed to delete file: \(error.localizedDescription)")
                    // Even on failure, we proceed to finish the flow as local cleanup is done
                    self.synchronizeDatabase()
                    self.profileUpdateComplete.send()
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.synchronizeDatabase()
                self.profileImage = nil
                self.profileUpdateComplete.send()
            }
            .store(in: &disposables)
    }

    /// Notifies observers that the database has been synchronized
    func synchronizeDatabase() {
        NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
    }

    // MARK: - Thumbnails

    private func setProfileThumbnail(from data: Data, key: String, maxPixel: Int = 192) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let request = Thumbnailer.profileDefault(key: key, maxPixelSize: maxPixel)
            let thumb = try? await Thumbnailer.shared.thumbnail(from: data, request: request)
            await MainActor.run {
                if let thumb {
                    self.profileImage = thumb
                } else if let fallback = UIImage(data: data) {
                    // Fallback if thumbnailing fails
                    self.profileImage = fallback
                }
            }
        }
    }
}
