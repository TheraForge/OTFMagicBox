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

import Foundation
import OTFUtilities
import Sodium

struct SecureAttachmentEnvelope: Equatable {
    let encryptedData: Data
    let encryptedFileKey: String
    let hashFileKey: String
}

enum SecureAttachmentCryptoError: Error, Equatable {
    case missingStorageKey
    case invalidEncryptedFileKey
    case malformedEncryptedFileKey
    case malformedEncryptedData
    case integrityCheckFailed
}

struct SecureAttachmentCryptor {
    private let sodium: SwiftSodium
    private let fileKeyGenerator: () -> Bytes

    init(
        sodium: SwiftSodium = SwiftSodium(),
        fileKeyGenerator: (() -> Bytes)? = nil
    ) {
        self.sodium = sodium
        self.fileKeyGenerator = fileKeyGenerator ?? {
            sodium.sodium.secretStream.xchacha20poly1305.key()
        }
    }

    func encrypt(_ data: Data, storageKey: Bytes) throws -> SecureAttachmentEnvelope {
        guard !storageKey.isEmpty else {
            throw SecureAttachmentCryptoError.missingStorageKey
        }

        let fileKey = fileKeyGenerator()
        let fileKeyPushStream = try sodium.makePushStream(secretKey: storageKey)
        let encryptedFileKey = fileKeyPushStream.header() +
            (try sodium.pushChunk(fileKeyPushStream, message: fileKey))

        let filePushStream = try sodium.makePushStream(secretKey: fileKey)
        let encryptedFile = filePushStream.header() +
            (try sodium.pushChunk(filePushStream, message: Array(data)))
        let hash = try sodium.genericHash(message: encryptedFile, key: fileKey)

        return SecureAttachmentEnvelope(
            encryptedData: Data(encryptedFile),
            encryptedFileKey: encryptedFileKey.bytesToHex(spacing: "").lowercased(),
            hashFileKey: hash.bytesToHex(spacing: "").lowercased()
        )
    }

    func decrypt(
        _ encryptedData: Data,
        encryptedFileKey: String,
        hashFileKey: String,
        storageKey: Bytes
    ) throws -> Data {
        guard !storageKey.isEmpty else {
            throw SecureAttachmentCryptoError.missingStorageKey
        }
        guard let encryptedFileKeyBytes = encryptedFileKey.hexToBytes() else {
            throw SecureAttachmentCryptoError.invalidEncryptedFileKey
        }
        guard let (fileKeyHeader, fileKeyCiphertext) = splitEncryptedPayload(encryptedFileKeyBytes) else {
            throw SecureAttachmentCryptoError.malformedEncryptedFileKey
        }
        guard let (fileHeader, fileCiphertext) = splitEncryptedPayload(Array(encryptedData)) else {
            throw SecureAttachmentCryptoError.malformedEncryptedData
        }

        let (fileKey, _) = try sodium.pullChunk(
            secretKey: storageKey,
            header: fileKeyHeader,
            ciphertext: fileKeyCiphertext
        )

        let encryptedBytes = Array(encryptedData)
        let actualHash = try sodium.genericHash(message: encryptedBytes, key: fileKey)
            .bytesToHex(spacing: "")
            .lowercased()
        guard actualHash == hashFileKey.lowercased() else {
            throw SecureAttachmentCryptoError.integrityCheckFailed
        }

        let (plaintext, _) = try sodium.pullChunk(
            secretKey: fileKey,
            header: fileHeader,
            ciphertext: fileCiphertext
        )
        return Data(plaintext)
    }

    private func splitEncryptedPayload(_ bytes: Bytes) -> (header: Bytes, ciphertext: Bytes)? {
        let headerSize = SecretStream.XChaCha20Poly1305.HeaderBytes
        let authenticationSize = SecretStream.XChaCha20Poly1305.ABytes
        guard bytes.count >= headerSize + authenticationSize else { return nil }
        return (
            header: Array(bytes[..<headerSize]),
            ciphertext: Array(bytes[headerSize...])
        )
    }
}
