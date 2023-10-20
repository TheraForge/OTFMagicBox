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
    
    @Published var profileDetaiDataModel: ProfileDetaiDataModel = ProfileDetaiDataModel()
    private var disposables = Set<AnyCancellable>()
    var patientPublisher = PassthroughSubject<OCKPatient, Never>()
    var profileImageData = PassthroughSubject<Data, Never>()
    var hideLoader = PassthroughSubject<Bool, Never>()
    let swiftSodium = SwiftSodium()
    
    private var shouldDismissView = false {
        didSet {
            hideLoader.send(shouldDismissView)
        }
    }
    
    private var patient: OCKPatient? {
        didSet {
            patientPublisher.send(patient!)
        }
    }
    
    private var profileData: Data? {
        didSet {
            profileImageData.send(profileData!)
        }
    }
    
//  MARK:  Fetch OCKPatient
    func fetchPatient(userId: String) {
        
        CareKitManager.shared.cloudantStore?.fetchPatient(withID: userId, completion: { result in
            self.profileDataPublisher(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: {print ("Received completion: \($0).")},
                      receiveValue: {patient in
                    self.patient = patient
                })
                .store(in: &self.disposables)
        })
    }
    
    func profileDataPublisher(userId: String) -> AnyPublisher<OCKPatient, Error> {
         return Future<OCKPatient, Error> { promise in
             CareKitManager.shared.cloudantStore?.fetchPatient(withID: userId, completion: { result in
                 if case .success(let patient) = result {
                     return promise(.success(patient))
                 }
             })
         }
         .receive(on: RunLoop.main)
         .eraseToAnyPublisher()
     }
    
//  MARK:  update OCKPatient
    func updatePatient(user: OCKPatient) {
        CareKitManager.shared.cloudantStore?.updatePatient(user)
    }
    
//  MARK:  upload file request
    func uploadFile(data: Data, fileName: String, encryptedFileKey: String? = nil , hashFileKey: String) {
        OTFTheraforgeNetwork.shared.uploadFile(data: data, fileName: fileName, type: .profile, encryptedFileKey: encryptedFileKey, hashFileKey: hashFileKey)
            .receive(on: DispatchQueue.main)
            .sink { res in
                switch res {
                case .failure(let error):
                    print(error)
                default: break
                }
            } receiveValue: { data in
                self.synchronizeDatabase()
                let imageData = data.data
                imageData.saveFileToDocument(data: imageData, filename: (data.metadata.attachmentID))
                self.profileData = imageData
            }
            .store(in: &disposables)
    }
    
    func showProfileImage(user : OCKPatient, imageData: Data) -> UIImage {
        
        if let encryptedFileKey = user.attachments?.Profile?.encryptedFileKey, let hashFileKey = user.attachments?.Profile?.hashFileKey, !encryptedFileKey.isEmpty {
            let image = dataToImage(data: imageData, hashFileKey: hashFileKey)
           return image
        } else {
            let image = dataToImageWithoutDecryption(data: imageData, key: user.attachments?.Profile?.hashFileKey)
            return image
        }
    }
    
//MARK:  downlaod file request
    func downloadFile(attachmentID: String, isProfile : Bool = false) {
        OTFTheraforgeNetwork.shared.downloadFile(attachmentID: attachmentID, type: .profile)
            .receive(on: DispatchQueue.main)
            .sink { res in
                switch res {
                case .failure(let error):
                    print(error)
                default: break
                }
            } receiveValue: { data in
                let fileData = data.data
                fileData.saveFileToDocument(data: fileData, filename: data.metadata.attachmentID)
                if isProfile {
                    let dataDict:[String: Data] = ["imageData": fileData]
                    NotificationCenter.default.post(name: .imageDownloaded, object: dataDict)
                }
            }
            .store(in: &disposables)
    }
    
    //MARK:  decrypt encrypted data
    func decryptedFile(file: Data, hashFileKey: String) -> Data {
        let dataToBytes =  swiftSodium.getArrayOfBytesFromData(FileData: file as NSData)
        let fileKey = swiftSodium.generateDeriveKey(key: KeychainCloudManager.getDefaultStorageKey)
        
        let hashKey = swiftSodium.generateGenericHashWithKey(message: dataToBytes, fileKey: fileKey)
        let hashKeyHex = hashKey.bytesToHex(spacing: "").lowercased()
        
        if hashKeyHex.contains(hashFileKey) {
            let (header, encryptedFile) = dataToBytes.splitFile()
            let encryption = swiftSodium.decryptFile(secretKey: fileKey, header: header, encryptedFile: encryptedFile)
            guard let (file, _) = encryption else { return Data() }
            let decryptedFile = Data(file)
            return decryptedFile
        } else {

        }
        return Data()
        
    }
    
    
//MARK:  decrypt data and convert data to UIImage
    func dataToImage(data: Data, hashFileKey: String) -> UIImage {
        let decryptedData = decryptedFile(file: data, hashFileKey: hashFileKey)
        if let image = UIImage(data: decryptedData) {
            return image
        }
        return UIImage()
    }
    
    func dataToImageWithoutDecryption(data: Data, key: String?) -> UIImage {
        let imageToBytes = swiftSodium.getArrayOfBytesFromData(FileData: data as NSData)
        let hashFileKey = swiftSodium.generateGenericHashWithoutKey(message: imageToBytes)
        
        let hashFileKeyHex = hashFileKey.bytesToHex(spacing: "").lowercased()
        if let keyhex = key, hashFileKeyHex.contains(keyhex),
            let image = UIImage(data: data) {
            return image
        }
        return UIImage()
    }
    
//MARK:  Delete file request
    func deleteAttachment(attachmentID: String) {
        OTFTheraforgeNetwork.shared.deleteFile(attachmentID: attachmentID)
            .receive(on: DispatchQueue.main)
            .sink { res in
                switch res {
                case .failure:
                self.shouldDismissView = true
                default: break
                }
            } receiveValue: { data in
                self.synchronizeDatabase()
                self.shouldDismissView = true
            }
            .store(in: &disposables)
    }
    
//MARK:  delete file from document directory
    func deleteFileFromDocument(fileName: String) {
        deleteFile(filename: fileName)
    }
    
    public func synchronizeDatabase() {
        NotificationCenter.default.post(name: .databaseSuccessfllySynchronized, object: nil)
    }
}


 

