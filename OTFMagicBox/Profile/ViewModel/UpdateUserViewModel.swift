//
//  UpdateUserViewModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 12/09/2022.
//

import Foundation
import OTFCareKitStore
import Combine
import OTFUtilities
import OTFCloudantStore
import Sodium

struct ProfileDetaiDataModel {
    var showGenderPicker = false
    var showDatePicker = false
}

final class UpdateUserViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    
    // MARK: - Publishers
    var disposables = Set<AnyCancellable>()
    var patientPublisher = PassthroughSubject<OCKPatient, Never>()
    var profileImageData = PassthroughSubject<Data, Never>()
    var hideLoader = PassthroughSubject<Bool, Never>()
    var profileUpdateComplete = PassthroughSubject<Void, Never>()
    
    enum ProfileUpdateError: LocalizedError {
        case timeout
        case uploadFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .timeout:
                return "Profile update timed out. Please try again."
            case .uploadFailed(let error):
                return "Failed to update profile: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Properties
    let swiftSodium = SwiftSodium()
    var encryptedImage = UIImage()
    private let attachmentIDKey = "LastKnownProfileAttachmentID"
    
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
    
    // MARK: - Combined Update Methods
    func updatePatientWithImage(user: OCKPatient, newImage: UIImage?) {
        isLoading = true
        
        CareKitStoreManager.shared.cloudantStore?.updatePatient(user) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let updatedPatient):
                self.patient = updatedPatient
                
                if let newImage = newImage, let imageData = newImage.pngData() {
                    let bytesImage = self.swiftSodium.getArrayOfBytesFromData(fileData: imageData as NSData)
                    let hashKeyFile = self.swiftSodium.generateGenericHashWithoutKey(message: bytesImage)
                    let hashKeyFileHex = hashKeyFile.bytesToHex(spacing: "").lowercased()
                    let uuid = UUID().uuidString + ".png"
                    
                    self.uploadFile(data: imageData, fileName: uuid, hashFileKey: hashKeyFileHex)
                } else {
                    self.isLoading = false
                    self.synchronizeDatabase()
                    self.profileUpdateComplete.send()
                }
                
            case .failure(let error):
                self.isLoading = false
                print("Failed to update patient: \(error)")
            }
        }
    }
    
    // MARK: - Patient Fetch Methods
    func fetchPatient(userId: String) {
        CareKitStoreManager.shared.cloudantStore?.fetchPatient(withID: userId) { [weak self] _ in
            guard let self = self else { return }
            
            self.profileDataPublisher(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to fetch patient: \(error)")
                        }
                    },
                    receiveValue: { [weak self] patient in
                        self?.patient = patient
                    }
                )
                .store(in: &self.disposables)
        }
    }
    
    func profileDataPublisher(userId: String) -> AnyPublisher<OCKPatient, Error> {
        Future<OCKPatient, Error> { promise in
            CareKitStoreManager.shared.cloudantStore?.fetchPatient(withID: userId) { result in
                switch result {
                case .success(let patient):
                    promise(.success(patient))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Contact Methods
    func fetchContactsCount(completion: @escaping (Result<Int, Error>) -> Void) {
        contactsPublisher()
            .collect()
            .sink(
                receiveCompletion: { completionStatus in
                    if case .failure(let error) = completionStatus {
                        completion(.failure(error))
                    }
                },
                receiveValue: { contacts in
                    completion(.success(contacts.count))
                }
            )
            .store(in: &disposables)
    }
    
    func contactsPublisher() -> AnyPublisher<OCKContact, Error> {
        Future<[OCKContact], Error> { promise in
            CareKitStoreManager.shared.cloudantStore?.fetchContacts { result in
                switch result {
                case .success(let contacts):
                    promise(.success(contacts))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .flatMap { contacts in
            Publishers.MergeMany(contacts.map { Just($0).setFailureType(to: Error.self) })
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - File Management Methods
    func uploadFile(data: Data, fileName: String, encryptedFileKey: String? = nil, hashFileKey: String) {
        // Remove isLoading = true here since it's already set in updatePatientWithImage
        OTFTheraforgeNetwork.shared.uploadFile(data: data, fileName: fileName, type: .profile, encryptedFileKey: encryptedFileKey, hashFileKey: hashFileKey)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                // Only set isLoading to false after upload completes
                self?.isLoading = false
                switch res {
                case .failure(let error):
                    print(error)
                default: break
                }
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.synchronizeDatabase()
                let imageData = data.data
                imageData.saveFileToDocument(data: imageData, filename: (data.metadata.attachmentID))
                UserDefaults.standard.set(data.metadata.attachmentID, forKey: self.attachmentIDKey)
                self.profileImageData.send(imageData)
                if let image = UIImage(data: imageData) {
                    self.profileImage = image
                }
                
                // Move isLoading = false here after everything is complete
                self.isLoading = false
                self.profileUpdateComplete.send()
            }
            .store(in: &disposables)
    }
    
    func downloadFile(attachmentID: String, isProfile: Bool = false) {
        isLoading = true
        
        OTFTheraforgeNetwork.shared.downloadFile(attachmentID: attachmentID, type: .profile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Failed to download file: \(error)")
                }
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                
                let fileData = data.data
                fileData.saveFileToDocument(data: fileData, filename: data.metadata.attachmentID)
                
                if isProfile {
                    if let image = UIImage(data: fileData) {
                        self.profileImage = image
                    }
                    let dataDict: [String: Data] = ["imageData": fileData]
                    NotificationCenter.default.post(name: .imageDownloaded, object: dataDict)
                }
            }
            .store(in: &disposables)
    }
    
    func deleteAttachment(attachmentID: String) {
        isLoading = true
        
        OTFTheraforgeNetwork.shared.deleteFile(attachmentID: attachmentID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure = completion {
                    self?.shouldDismissView = true
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.synchronizeDatabase()
                self.shouldDismissView = true
                self.profileImage = nil
                self.profileUpdateComplete.send()
            }
            .store(in: &disposables)
    }
    
    func deleteFileFromDocument(fileName: String) {
        try? FileManager.deleteFile(filename: fileName)
    }
    
    func synchronizeDatabase() {
        NotificationCenter.default.post(name: .databaseSuccessfllySynchronized, object: nil)
    }
}
