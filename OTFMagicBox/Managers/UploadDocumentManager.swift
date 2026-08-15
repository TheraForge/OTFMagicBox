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
import Combine
import OTFUtilities
import Sodium

final class UploadDocumentManager {

    private let logger = OTFLogger.logger()
    private var disposables = Set<AnyCancellable>()
    private let cryptor = SecureAttachmentCryptor()

    func encryptDocument(document: Data, fileName: String) {
        do {
            let defaultStorageKey: Bytes = KeychainCloudManager.getDefaultStorageKey
            let envelope = try cryptor.encrypt(document, storageKey: defaultStorageKey)
            uploadFile(
                data: envelope.encryptedData,
                fileName: fileName,
                encryptedFileKey: envelope.encryptedFileKey,
                hashFileKey: envelope.hashFileKey
            )
        } catch {
            logger.error("encryptDocument failed: \(error.localizedDescription)")
        }
    }

    func decryptedFile(file: Data, encryptedFileKeyHex: String, hashFileKey: String) -> Data {
        do {
            return try cryptor.decrypt(
                file,
                encryptedFileKey: encryptedFileKeyHex,
                hashFileKey: hashFileKey,
                storageKey: KeychainCloudManager.getDefaultStorageKey
            )
        } catch {
            logger.error("decryptedFile failed: \(error.localizedDescription)")
            return Data()
        }
    }

    func uploadFile(data: Data, fileName: String, encryptedFileKey: String, hashFileKey: String) {
        OTFTheraforgeNetwork.shared
            .uploadFile(data: data, fileName: fileName, type: .consentForm, encryptedFileKey: encryptedFileKey, hashFileKey: hashFileKey)
            .receive(on: DispatchQueue.main)
            .sink { [self] res in
                if case .failure(let error) = res {
                    logger.error("uploadFile failed: \(error.localizedDescription)")
                }
            } receiveValue: { [self] response in
                let documentData = response.data
                do {
                    try FileManager.writeToDocuments(filename: response.metadata.attachmentID, data: documentData)
                } catch {
                    logger.warning("Failed to save encrypted file locally: \(error.localizedDescription)")
                }
                let decrypted = self.decryptedFile(file: documentData, encryptedFileKeyHex: encryptedFileKey, hashFileKey: hashFileKey)
                logger.info("Decrypted file size: \(decrypted.count) bytes")
            }
            .store(in: &disposables)
    }
}
