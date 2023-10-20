/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.
 
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
import Combine
import OTFUtilities
import Sodium

final class UploadDocumentManager {
    
    private var disposables = Set<AnyCancellable>()
    let swiftSodium = SwiftSodium()
    
    func encryptDocument(document: Data, fileName: String) {
        let bytesImage = swiftSodium.getArrayOfBytesFromData(FileData: document as NSData)
        let defaultStorageKey = KeychainCloudManager.getDefaultStorageKey
      
        let fileKeyPushStream = swiftSodium.getPushStream(secretKey: defaultStorageKey)!
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        let eFileKey = swiftSodium.encryptFile(pushStream: fileKeyPushStream, fileBytes: fileKey)
        let encryptedFileKey = [fileKeyPushStream.header(), eFileKey].flatMap({ (element: [UInt8]) -> [UInt8] in
            return element
        })
        let encryptedFileKeyHex = encryptedFileKey.bytesToHex(spacing: "").lowercased()
        
        let documentPushStream = swiftSodium.getPushStream(secretKey: fileKey)!
        let fileencryption = swiftSodium.encryptFile(pushStream: documentPushStream, fileBytes: bytesImage)
        let newFile = [documentPushStream.header(), fileencryption].flatMap({ (element: [UInt8]) -> [UInt8] in
            return element
        })
        
        let hashKeyFile = swiftSodium.generateGenericHashWithKey(message: newFile, fileKey: fileKey)
        let hashKeyFileHex = hashKeyFile.bytesToHex(spacing: "").lowercased()
        let encryptedFileData = Data(newFile)
        
        uploadFile(data: encryptedFileData, fileName: fileName, encryptedFileKey: encryptedFileKeyHex, hashFileKey: hashKeyFileHex)
    }
    
    
    func decryptedFile(file: Data, hashFileKey: String) -> Data {
        let dataToBytes =  swiftSodium.getArrayOfBytesFromData(FileData: file as NSData)
        let defaultStorageKey = KeychainCloudManager.getDefaultStorageKey
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        
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
    
    func uploadFile(data: Data, fileName: String, encryptedFileKey: String, hashFileKey: String) {
        OTFTheraforgeNetwork.shared.uploadFile(data: data, fileName: fileName, type: .consentForm, encryptedFileKey: encryptedFileKey, hashFileKey: hashFileKey)
            .receive(on: DispatchQueue.main)
            .sink { res in
                switch res {
                case .failure(let error):
                    print(error)
                default: break
                }
            } receiveValue: { data in
                let documentData = data.data
                documentData.saveFileToDocument(data: documentData, filename: (data.metadata.attachmentID))
                let decryptedFile = self.decryptedFile(file: data.data, hashFileKey: hashFileKey)
                print(decryptedFile)
            }
            .store(in: &disposables)
    }

}
