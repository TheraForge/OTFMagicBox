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
    let swiftSodium = SwiftSodium()

    func encryptDocument(document: Data, fileName: String) {
        do {
            let bytes: Bytes = Array(document)

            // 1) Master key for wrapping fileKey
            let defaultStorageKey: Bytes = KeychainCloudManager.getDefaultStorageKey
            guard !defaultStorageKey.isEmpty else {
                logger.error("encryptDocument: missing defaultStorageKey.")
                return
            }

            // 2) Derive per-file key from master key
            let fileKey: Bytes = try swiftSodium.deriveKey(from: defaultStorageKey)

            // 3) Encrypt fileKey with master key → encryptedFileKeyHex
            let fileKeyPush = try swiftSodium.makePushStream(secretKey: defaultStorageKey)
            let fileKeyCipher = try swiftSodium.pushChunk(fileKeyPush, message: fileKey)
            let encryptedFileKey: Bytes = fileKeyPush.header() + fileKeyCipher
            let encryptedFileKeyHex = encryptedFileKey.bytesToHex(spacing: "").lowercased()

            // 4) Encrypt the document with fileKey → newFile (ciphertext)
            let docPush = try swiftSodium.makePushStream(secretKey: fileKey)
            let fileCipher = try swiftSodium.pushChunk(docPush, message: bytes)
            let newFile: Bytes = docPush.header() + fileCipher

            // 5) Hash ciphertext with fileKey → hashFileKeyHex
            let hashBytes: Bytes = try swiftSodium.genericHash(message: newFile, key: fileKey)
            let hashFileKeyHex = hashBytes.bytesToHex(spacing: "").lowercased()

            // 6) Upload ciphertext and store keys
            let encryptedFileData = Data(newFile)
            uploadFile(data: encryptedFileData, fileName: fileName, encryptedFileKey: encryptedFileKeyHex, hashFileKey: hashFileKeyHex)
        } catch {
            logger.error("encryptDocument failed: \(error.localizedDescription)")
        }
    }

    func decryptedFile(file: Data, encryptedFileKeyHex: String, hashFileKey: String) -> Data {
        do {
            let ciphertextBytes: [UInt8] = Array(file)

            // 1) Master key
            let defaultStorageKey: [UInt8] = KeychainCloudManager.getDefaultStorageKey
            guard !defaultStorageKey.isEmpty else {
                logger.error("decryptedFile: missing defaultStorageKey.")
                return Data()
            }

            // 2) Decode & decrypt fileKey from encryptedFileKeyHex
            guard let encryptedFileKeyBytes = encryptedFileKeyHex.hexToBytes() else {
                logger.error("decryptedFile: invalid encryptedFileKey hex.")
                return Data()
            }

            let (fileKeyHeader, fileKeyCipher) = encryptedFileKeyBytes.splitFile()
            let (fileKey, _) = try swiftSodium.pullChunk(secretKey: defaultStorageKey, header: fileKeyHeader, ciphertext: fileKeyCipher)

            // 3) Verify hash of ciphertext
            let hashBytes: [UInt8] = try swiftSodium.genericHash(message: ciphertextBytes, key: fileKey)
            let hashHex = hashBytes.bytesToHex(spacing: "").lowercased()

            guard hashHex == hashFileKey.lowercased() else {
                logger.error("decryptedFile: hash mismatch. Expected: \(hashFileKey) - Got: \(hashHex)")
                return Data()
            }

            // 4) Decrypt ciphertext
            let (header, encryptedFile) = ciphertextBytes.splitFile()
            let (plaintext, _) = try swiftSodium.pullChunk(secretKey: fileKey, header: header, ciphertext: encryptedFile)
            return Data(plaintext)
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
