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
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("Thumbnailer and local user purge")
struct ThumbnailerAndLocalUserPurgeTests {
    @Test("Thumbnailer rejects invalid image data")
    func thumbnailerRejectsInvalidData() async throws {
        let thumbnailer = Thumbnailer(diskCacheURL: temporaryDirectory())

        await #expect(throws: Thumbnailer.ThumbnailError.self) {
            _ = try await thumbnailer.thumbnail(
                from: Data("not-an-image".utf8),
                request: Thumbnailer.Request(key: nil, maxPixelSize: 32, backend: .imageIO, cache: .none, scale: 1)
            )
        }
    }

    @Test("Thumbnailer reuses disk cache for stable key")
    func thumbnailerReusesDiskCacheForStableKey() async throws {
        let cacheURL = temporaryDirectory()
        let thumbnailer = Thumbnailer(diskCacheURL: cacheURL)
        let request = Thumbnailer.Request(key: "profile-image", maxPixelSize: 24, backend: .imageIO, cache: .memoryAndDisk, scale: 1)
        let data = try makePNGData(size: CGSize(width: 80, height: 60), color: .systemBlue)

        let first = try await thumbnailer.thumbnail(from: data, request: request)
        await thumbnailer.clearMemory()
        let second = try await thumbnailer.thumbnail(from: Data("corrupt".utf8), request: request)

        #expect(first.size == second.size)
        #expect((try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil).count) == 1)
    }

    @Test("Local user purge clears thumbnails, originals, and stored profile keys")
    func localUserPurgeClearsExpectedCollaborators() async {
        let isolatedDefaults = makeIsolatedUserDefaults()
        defer { isolatedDefaults.cleanup() }
        isolatedDefaults.defaults.set("profile-attachment", forKey: Constants.Storage.kLastProfileAttachmentID)
        isolatedDefaults.defaults.set("profile-hash", forKey: Constants.Storage.kLastProfileHashFileKey)
        final class Recorder {
            var thumbnailPurgeCount = 0
            var deletedFiles: [String] = []
        }
        let recorder = Recorder()
        let purger = LocalUserPurger(
            defaults: isolatedDefaults.defaults,
            thumbnailPurger: { recorder.thumbnailPurgeCount += 1 },
            deleteFile: { recorder.deletedFiles.append($0) }
        )

        await purger.purgeAll()

        #expect(recorder.thumbnailPurgeCount == 1)
        #expect(recorder.deletedFiles == ["profile-attachment"])
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileAttachmentID) == nil)
        #expect(isolatedDefaults.defaults.string(forKey: Constants.Storage.kLastProfileHashFileKey) == nil)
    }
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("magicbox-thumbnail-tests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makePNGData(size: CGSize, color: UIColor) throws -> Data {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    return try #require(image.pngData())
}
