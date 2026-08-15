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
import Testing
@testable import OTFMagicBox

@Suite("Secure attachment cryptor")
struct SecureAttachmentCryptorTests {
    @Test("Encryption round trips and rejects tampering")
    func encryptionRoundTripsAndRejectsTampering() throws {
        let plaintext = Data("private report".utf8)
        let storageKey = Array(repeating: UInt8(0x42), count: 32)
        let cryptor = SecureAttachmentCryptor()
        let envelope = try cryptor.encrypt(plaintext, storageKey: storageKey)

        #expect(envelope.encryptedData != plaintext)
        #expect(try cryptor.decrypt(
            envelope.encryptedData,
            encryptedFileKey: envelope.encryptedFileKey,
            hashFileKey: envelope.hashFileKey,
            storageKey: storageKey
        ) == plaintext)

        var tamperedData = envelope.encryptedData
        tamperedData[tamperedData.startIndex] ^= 0x01
        #expect(throws: SecureAttachmentCryptoError.self) {
            try cryptor.decrypt(
                tamperedData,
                encryptedFileKey: envelope.encryptedFileKey,
                hashFileKey: envelope.hashFileKey,
                storageKey: storageKey
            )
        }
    }

    @Test("Malformed payloads are rejected without trapping")
    func malformedPayloadsAreRejected() throws {
        let storageKey = Array(repeating: UInt8(0x42), count: 32)
        let cryptor = SecureAttachmentCryptor()
        let envelope = try cryptor.encrypt(Data("report".utf8), storageKey: storageKey)
        let shortPayloads: [[UInt8]] = [
            [],
            [0x01],
            Array(
                repeating: 0x02,
                count: SecretStream.XChaCha20Poly1305.HeaderBytes +
                    SecretStream.XChaCha20Poly1305.ABytes - 1
            )
        ]

        for payload in shortPayloads {
            #expect(throws: SecureAttachmentCryptoError.malformedEncryptedFileKey) {
                try cryptor.decrypt(
                    envelope.encryptedData,
                    encryptedFileKey: payload.bytesToHex(spacing: ""),
                    hashFileKey: envelope.hashFileKey,
                    storageKey: storageKey
                )
            }
        }

        #expect(throws: SecureAttachmentCryptoError.malformedEncryptedData) {
            try cryptor.decrypt(
                Data([0x01]),
                encryptedFileKey: envelope.encryptedFileKey,
                hashFileKey: envelope.hashFileKey,
                storageKey: storageKey
            )
        }
    }

    @Test("Each attachment receives an independent file key")
    func eachAttachmentReceivesIndependentFileKey() throws {
        let storageKey = Array(repeating: UInt8(0x42), count: 32)
        var generatedKeys = [
            Array(repeating: UInt8(0x11), count: 32),
            Array(repeating: UInt8(0x22), count: 32)
        ]
        let cryptor = SecureAttachmentCryptor(
            fileKeyGenerator: { generatedKeys.removeFirst() }
        )

        let first = try cryptor.encrypt(Data("first".utf8), storageKey: storageKey)
        let second = try cryptor.encrypt(Data("second".utf8), storageKey: storageKey)

        #expect(first.encryptedFileKey != second.encryptedFileKey)
        #expect(first.hashFileKey != second.hashFileKey)
        #expect(try cryptor.decrypt(
            first.encryptedData,
            encryptedFileKey: first.encryptedFileKey,
            hashFileKey: first.hashFileKey,
            storageKey: storageKey
        ) == Data("first".utf8))
        #expect(try cryptor.decrypt(
            second.encryptedData,
            encryptedFileKey: second.encryptedFileKey,
            hashFileKey: second.hashFileKey,
            storageKey: storageKey
        ) == Data("second".utf8))
    }

    @Test("A different storage key cannot unwrap the file key")
    func differentStorageKeyIsRejected() throws {
        let cryptor = SecureAttachmentCryptor()
        let envelope = try cryptor.encrypt(
            Data("private report".utf8),
            storageKey: Array(repeating: UInt8(0x11), count: 32)
        )

        #expect(throws: SwiftSodium.SwiftSodiumError.self) {
            try cryptor.decrypt(
                envelope.encryptedData,
                encryptedFileKey: envelope.encryptedFileKey,
                hashFileKey: envelope.hashFileKey,
                storageKey: Array(repeating: UInt8(0x22), count: 32)
            )
        }
    }

    @Test("Previous derived-key consent attachments remain decryptable")
    func previousConsentAttachmentsRemainDecryptable() throws {
        let storageKey = Array(repeating: UInt8(0x42), count: 32)
        let plaintext = Data("signed consent".utf8)
        let legacyEnvelope = try makeDerivedKeyEnvelope(
            plaintext: plaintext,
            storageKey: storageKey
        )

        #expect(try SecureAttachmentCryptor().decrypt(
            legacyEnvelope.encryptedData,
            encryptedFileKey: legacyEnvelope.encryptedFileKey,
            hashFileKey: legacyEnvelope.hashFileKey,
            storageKey: storageKey
        ) == plaintext)
    }
}

private func makeDerivedKeyEnvelope(
    plaintext: Data,
    storageKey: [UInt8]
) throws -> SecureAttachmentEnvelope {
    let sodium = SwiftSodium()
    let fileKey = try sodium.deriveKey(from: storageKey)
    let keyStream = try sodium.makePushStream(secretKey: storageKey)
    let encryptedFileKey = keyStream.header() +
        (try sodium.pushChunk(keyStream, message: fileKey))
    let fileStream = try sodium.makePushStream(secretKey: fileKey)
    let encryptedData = fileStream.header() +
        (try sodium.pushChunk(fileStream, message: Array(plaintext)))
    let hash = try sodium.genericHash(message: encryptedData, key: fileKey)
    return SecureAttachmentEnvelope(
        encryptedData: Data(encryptedData),
        encryptedFileKey: encryptedFileKey.bytesToHex(spacing: "").lowercased(),
        hashFileKey: hash.bytesToHex(spacing: "").lowercased()
    )
}
