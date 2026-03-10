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

import UIKit
import ImageIO
import CryptoKit

/// A lightweight, centralized thumbnail service with pluggable decoding backends,
/// background processing, and memory+disk caching. iOS 16+.
///
/// `Thumbnailer` is an `actor`, so its public API is concurrency-safe and can be
/// called from any thread. Heavy work (I/O and decoding) runs off the main thread.
///
/// ### Why use this?
/// - **Downsamples from original bytes** to the exact UI size (no full decode first)
/// - **Async/await** interface; safe to update UI on `MainActor` afterward
/// - **Cache layers**: in-memory (NSCache) and on-disk (`Library/Caches/Thumbnails`)
/// - **Backend choice**: ImageIO or UIKit thumbnail APIs
///
/// ### Example: create a thumbnail from raw bytes
/// ```swift
/// let req = Thumbnailer.profileDefault(key: attachmentID, maxPixelSize: 192)
/// let image = try await Thumbnailer.shared.thumbnail(from: data, request: req)
/// await MainActor.run { avatarView.image = image }
/// ```
///
/// ### Example: load from file URL
/// ```swift
/// let req = Thumbnailer.Request(key: "my-key", maxPixelSize: 256)
/// let image = try await Thumbnailer.shared.thumbnail(fromFile: fileURL, request: req)
/// ```
///
/// ### Cache management
/// ```swift
/// await Thumbnailer.shared.clearMemory()
/// await Thumbnailer.shared.clearDisk()
/// await Thumbnailer.shared.remove(forKey: "my-key")
/// ```
public actor Thumbnailer {

    // MARK: - Types

    /// Decoding backends for generating thumbnails.
    public enum Backend {
        /// Downsamples directly from bytes using `CGImageSourceCreateThumbnailAtIndex`.
        case imageIO
        /// Uses UIKit’s `prepareThumbnail(of:)` API (async completion under the hood).
        case uiKit
        /// Tries `imageIO` first and falls back to `uiKit` if needed.
        case auto
    }

    /// Caching strategy for generated thumbnails.
    public enum CachePolicy {
        /// Do not cache the resulting thumbnail.
        case none
        /// Cache in memory only (fastest reuse within session).
        case memoryOnly
        /// Cache in memory **and** on disk under `/Library/Caches/Thumbnails`.
        case memoryAndDisk
    }

    /// Describes a thumbnail request.
    public struct Request {
        /// Optional cache key. Provide a stable identifier (e.g., attachmentID) to enable caching.
        public var key: String?
        /// Maximum dimension (width or height) in **pixels** of the resulting thumbnail.
        public var maxPixelSize: Int
        /// Decoding backend to be used. `.auto` defaults to ImageIO, then falls back to UIKit.
        public var backend: Backend
        /// Cache policy for this request.
        public var cache: CachePolicy
        /// Target screen scale used when constructing the `UIImage`.
        /// Pass `0` (default) to use the current screen scale resolved on the main actor.
        public var scale: CGFloat

        /// Creates a new request.
        /// - Parameters:
        ///   - key: Stable cache key; omit or pass `nil` to disable caching.
        ///   - maxPixelSize: Max width/height in **pixels**.
        ///   - backend: Decoding backend. `.auto` tries ImageIO, then UIKit.
        ///   - cache: Caching strategy (default: `.memoryAndDisk`).
        ///   - scale: Target image scale (default: `0` uses main actor resolved scale).
        public init(
            key: String? = nil,
            maxPixelSize: Int,
            backend: Backend = .auto,
            cache: CachePolicy = .memoryAndDisk,
            scale: CGFloat = 0
        ) {
            self.key = key
            self.maxPixelSize = max(1, maxPixelSize)
            self.backend = backend
            self.cache = cache
            self.scale = scale > 0 ? max(1, scale) : 0
        }
    }

    /// Errors that can occur during thumbnail creation or persistence.
    public enum ThumbnailError: Error {
        case cannotCreateImageSource
        case cannotCreateThumbnail
        case invalidImageData
        case failedToWriteDisk
    }

    // MARK: - Presets

    /// Reasonable defaults for small avatars (e.g., profile pictures in lists).
    ///
    /// - Parameters:
    ///   - key: Stable cache key (e.g., attachment ID).
    ///   - maxPixelSize: Max dimension in pixels (default: 192).
    /// - Returns: A configured `Request` with `.auto` backend and `.memoryAndDisk` caching.
    public static func profileDefault(key: String?, maxPixelSize: Int = 192) -> Request {
        .init(key: key, maxPixelSize: maxPixelSize, backend: .auto, cache: .memoryAndDisk)
    }

    // MARK: - Singleton

    /// Shared instance for common use-cases.
    public static let shared = Thumbnailer()

    // MARK: - Caching

    private let memoryCache = NSCache<NSString, UIImage>()
    private lazy var diskCacheURL: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Public API

    /// Creates (or loads from cache) a thumbnail for the given image bytes.
    ///
    /// - Important: This method performs decoding off the main thread. Assign the returned image to
    ///   views on the `MainActor`.
    ///
    /// - Parameters:
    ///   - data: Original image data (any common format).
    ///   - request: Thumbnail configuration.
    /// - Returns: A `UIImage` scaled and downsampled for the requested size.
    public func thumbnail(from data: Data, request: Request) async throws -> UIImage {
        let resolvedScale: CGFloat = request.scale > 0 ? request.scale : await MainActor.run { UIScreen.main.scale }

        // 1) Memory cache
        if let key = request.key, request.cache != .none,
           let cached = memoryCache.object(forKey: key.ns as NSString) {
            return cached
        }

        // 2) Disk cache
        if let key = request.key, request.cache == .memoryAndDisk,
           let diskImage = try? loadFromDisk(forKey: key, scale: resolvedScale) {
            memoryCache.setObject(diskImage, forKey: key.ns as NSString)
            return diskImage
        }

        // 3) Generate
        let image: UIImage
        switch request.backend {
        case .imageIO:
            image = try await generateWithImageIO(from: data, maxPixelSize: request.maxPixelSize, scale: resolvedScale)
        case .uiKit:
            image = try await generateWithUIKit(from: data, maxPixelSize: request.maxPixelSize, scale: resolvedScale)
        case .auto:
            if let img = try? await generateWithImageIO(from: data, maxPixelSize: request.maxPixelSize, scale: resolvedScale) {
                image = img
            } else {
                image = try await generateWithUIKit(from: data, maxPixelSize: request.maxPixelSize, scale: resolvedScale)
            }
        }

        // 4) Cache
        if let key = request.key, request.cache != .none {
            memoryCache.setObject(image, forKey: key.ns as NSString)
            if request.cache == .memoryAndDisk {
                _ = try? saveToDisk(image: image, forKey: key)
            }
        }

        return image
    }

    /// Convenience overload for local files.
    ///
    /// Uses `Data(contentsOf:options:)` with `mappedIfSafe` to keep memory usage modest.
    ///
    /// - Parameters:
    ///   - url: File URL to the original image.
    ///   - request: Thumbnail configuration.
    /// - Returns: A `UIImage` scaled and downsampled for the requested size.
    public func thumbnail(fromFile url: URL, request: Request) async throws -> UIImage {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return try await thumbnail(from: data, request: request)
    }

    /// Removes all **on-disk** thumbnails created by `Thumbnailer`.
    ///
    /// The thumbnails are stored under `Library/Caches/Thumbnails`.
    /// This does **not** delete any originals your app may store elsewhere.
    public func clearDisk() async {
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) {
            for f in files { try? fm.removeItem(at: f) }
        }
    }

    /// Clears the **in-memory** thumbnail cache.
    public func clearMemory() {
        memoryCache.removeAllObjects()
    }

    /// Removes a single cached thumbnail by key from memory and disk.
    /// - Parameter key: The cache key used when generating the thumbnail.
    public func remove(forKey key: String) async {
        memoryCache.removeObject(forKey: key.ns as NSString)
        try? FileManager.default.removeItem(at: diskPath(forKey: key))
    }

    // MARK: - Generation Backends

    /// Downsamples using CoreGraphics / ImageIO.
    private func generateWithImageIO(from data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
                throw ThumbnailError.cannotCreateImageSource
            }
            let opts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCache: true,
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else {
                throw ThumbnailError.cannotCreateThumbnail
            }
            return UIImage(cgImage: cgThumb, scale: scale, orientation: .up)
        }.value
    }

    /// Uses UIKit’s async thumbnail API.
    private func generateWithUIKit(from data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            guard let full = UIImage(data: data, scale: scale) else {
                throw ThumbnailError.invalidImageData
            }
            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
                let target = CGSize(width: maxPixelSize, height: maxPixelSize)
                full.prepareThumbnail(of: target) { thumb in
                    if let thumb {
                        cont.resume(returning: thumb)
                    } else {
                        cont.resume(throwing: ThumbnailError.cannotCreateThumbnail)
                    }
                }
            }
        }.value
    }

    // MARK: - Disk I/O

    /// Derives a filesystem path for a given cache key.
    /// The “.jpg” extension is cosmetic—files may be PNG if alpha is present.
    private func diskPath(forKey key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8)).hex
        return diskCacheURL.appendingPathComponent("\(digest).jpg", isDirectory: false)
    }

    /// Persists a thumbnail image to disk using JPEG (or PNG if alpha is present).
    private func saveToDisk(image: UIImage, forKey key: String) throws -> URL {
        let url = diskPath(forKey: key)
        // Prefer JPEG (fast decode, small). PNG only if alpha is required.
        let data: Data? = image.hasAlphaChannel ? image.pngData() : image.jpegData(compressionQuality: 0.85)
        guard let out = data else { throw ThumbnailError.failedToWriteDisk }
        do {
            try out.write(to: url, options: .atomic)
            return url
        } catch {
            throw ThumbnailError.failedToWriteDisk
        }
    }

    /// Loads a cached thumbnail from disk (if present).
    private func loadFromDisk(forKey key: String, scale: CGFloat) throws -> UIImage? {
        let url = diskPath(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        // Use the requested scale to match on-screen rendering expectations.
        return UIImage(data: data, scale: scale)
    }
}

// MARK: - Helpers

private extension String {
    var ns: NSString { self as NSString }
}

private extension Digest {
    var hex: String { self.map { String(format: "%02x", $0) }.joined() }
}

private extension UIImage {
    /// Rough check for alpha channel presence.
    var hasAlphaChannel: Bool {
        guard let alpha = cgImage?.alphaInfo else { return false }
        switch alpha {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: return true
        default: return false
        }
    }
}
