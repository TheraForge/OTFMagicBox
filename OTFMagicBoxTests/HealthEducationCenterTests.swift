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
import OTFTemplateBox
import Testing
import UIKit
@testable import OTFMagicBox

@Suite("Health education configuration")
struct HealthEducationConfigurationTests {
    @Test("Migrates localized native copy and ordered articles")
    func migratesLocalizedNativeCopyAndOrderedArticles() throws {
        let raw = try decodeRaw(RawHealthEducationConfiguration.self, from: [
            "version": "2.1.0",
            "title": localized("Education"),
            "loadingLabel": localized("Loading"),
            "articles": [
                articleObject(id: "first", title: "First"),
                articleObject(id: "second", title: "Second")
            ]
        ])
        let version = try #require(OTFSemanticVersion(string: "2.0.0"))

        let config = try HealthEducationConfiguration.migrate(from: version, raw: raw)

        #expect(config.version == "2.1.0")
        #expect(config.title.localized == "Education")
        #expect(config.loadingLabel.localized == "Loading")
        #expect(
            config.articleLanguageLabel.localized
                == HealthEducationConfiguration.fallback.articleLanguageLabel.localized
        )
        #expect(config.articles.map(\.id) == ["first", "second"])
        #expect(config.articles.map { $0.title.localized } == ["First", "Second"])
        #expect(
            config.retryButtonTitle.localized
                == HealthEducationConfiguration.fallback.retryButtonTitle.localized
        )
    }

    @Test("Uses fallback articles for missing empty or wholly invalid arrays")
    func usesFallbackArticlesForMissingEmptyOrWhollyInvalidArrays() throws {
        let missingRaw = try decodeRaw(RawHealthEducationConfiguration.self, from: [
            "version": "2.2.0"
        ])
        let emptyRaw = try decodeRaw(RawHealthEducationConfiguration.self, from: [
            "version": "2.2.1",
            "articles": []
        ])
        let invalidRaw = try decodeRaw(RawHealthEducationConfiguration.self, from: [
            "version": "2.2.2",
            "articles": [articleObject(id: nil, title: "Missing ID")]
        ])

        let missing = HealthEducationConfiguration(from: missingRaw)
        let empty = HealthEducationConfiguration(from: emptyRaw)
        let invalid = HealthEducationConfiguration(from: invalidRaw)
        let fallbackIDs = HealthEducationConfiguration.fallback.articles.map(\.id)

        #expect(missing.articles.map(\.id) == fallbackIDs)
        #expect(empty.articles.map(\.id) == fallbackIDs)
        #expect(invalid.articles.map(\.id) == fallbackIDs)
    }

    @Test("Decodes the shipped YAML through the production decoder")
    func decodesShippedYAMLThroughProductionDecoder() throws {
        let config = try OTFYAMLDecoderEngine().decode(
            "HealthEducationConfiguration",
            as: HealthEducationConfiguration.self
        )

        #expect(config.version == "2.0.0")
        #expect(config.articles.map(\.id) == [
            "no-code-health-app",
            "type-2-diabetes",
            "asthma"
        ])
    }

    @Test("Configuration loader returns fallback when decoding fails")
    func configurationLoaderReturnsFallbackWhenDecodingFails() {
        let config = HealthEducationConfigurationLoader.load(
            decoder: FailingHealthEducationYAMLDecoder()
        )

        #expect(config.version == HealthEducationConfiguration.fallback.version)
        #expect(
            config.articles.map(\.id)
                == HealthEducationConfiguration.fallback.articles.map(\.id)
        )
    }

    @Test("Discards invalid and duplicate identifiers")
    func discardsInvalidAndDuplicateIdentifiers() throws {
        var emptyLocalizedTitle = articleObject(id: "empty-title", title: "Placeholder")
        emptyLocalizedTitle["title"] = localized("   ")
        let raw = try decodeRaw(RawHealthEducationConfiguration.self, from: [
            "articles": [
                articleObject(id: "kept", title: "First value"),
                articleObject(id: "kept", title: "Duplicate value"),
                articleObject(id: nil, title: "Invalid value"),
                emptyLocalizedTitle
            ]
        ])

        let config = HealthEducationConfiguration(from: raw)

        #expect(config.articles.map(\.id) == ["kept"])
        #expect(config.articles.first?.title.localized == "First value")
    }

    @Test("Fallback identifiers remain stable and unique")
    func fallbackIdentifiersRemainStableAndUnique() {
        let identifiers = HealthEducationConfiguration.fallback.articles.map(\.id)

        #expect(identifiers == [
            "no-code-health-app",
            "type-2-diabetes",
            "asthma"
        ])
        #expect(Set(identifiers).count == identifiers.count)
    }
}

@Suite("Health education content resolver")
struct HealthEducationContentResolverTests {
    @Test(
        "Trims whitespace and treats HTTPS scheme case-insensitively",
        arguments: [
            "  https://example.com/article  ",
            "HTTPS://example.com/article"
        ]
    )
    func resolvesHTTPS(_ source: String) throws {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        let location = try resolver.resolve(source)
        let url = try #require(location.remoteURL)

        #expect(url.scheme?.lowercased() == "https")
        #expect(url.host == "example.com")
    }

    @Test("Resolves a trimmed bundled HTML source through injected lookup")
    func resolvesBundledHTMLSource() throws {
        let localURL = URL(fileURLWithPath: "/tmp/health-education-fixture.html")
        let resolver = HealthEducationContentResolver { name, fileExtension in
            guard name == "fixture", fileExtension == "html" else { return nil }
            return localURL
        }

        #expect(try resolver.resolve("  fixture.html\n") == .bundled(localURL))
    }

    @Test(
        "Reports empty source after trimming whitespace",
        arguments: ["", "   \n\t"]
    )
    func reportsEmptySource(_ source: String) {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        do {
            _ = try resolver.resolve(source)
            Issue.record("Expected emptySource")
        } catch let error as HealthEducationContentResolutionError {
            #expect(error == .emptySource)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(
        "Rejects unsupported remote schemes",
        arguments: [
            "http://example.com/article",
            "FILE:///tmp/article.html",
            "mailto:care@example.com",
            "health-app://article"
        ]
    )
    func rejectsUnsupportedRemoteSchemes(_ source: String) {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        #expect(throws: HealthEducationContentResolutionError.self) {
            try resolver.resolve(source)
        }
    }

    @Test("Rejects malformed HTTPS")
    func rejectsMalformedHTTPS() {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        #expect(throws: HealthEducationContentResolutionError.self) {
            try resolver.resolve("https://")
        }
    }

    @Test(
        "Rejects unsafe or noncanonical local filenames",
        arguments: [
            "../article.html",
            "folder/article.html",
            "folder\\article.html",
            "article.html?mode=reader",
            "article.html#section",
            "%2e%2e%2farticle.html",
            "article.HTML",
            "article.pdf"
        ]
    )
    func rejectsUnsafeLocalFilenames(_ source: String) {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        #expect(throws: HealthEducationContentResolutionError.self) {
            try resolver.resolve(source)
        }
    }

    @Test("Reports a missing injected bundle resource")
    func reportsMissingBundledResource() {
        let resolver = HealthEducationContentResolver { _, _ in nil }

        #expect(throws: HealthEducationContentResolutionError.self) {
            try resolver.resolve("missing.html")
        }
    }
}

@Suite("Article loading and navigation policy")
struct ArticleLoadingAndNavigationPolicyTests {
    @Test("Retry generation reloads an unchanged source")
    func retryGenerationReloadsUnchangedSource() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let location = HealthEducationContentLocation.remote(url)
        var tracker = ArticleLoadTracker()

        let initialLoad = tracker.shouldLoad(.init(location: location, retryGeneration: 0))
        let unchangedLoad = tracker.shouldLoad(.init(location: location, retryGeneration: 0))
        let retryLoad = tracker.shouldLoad(.init(location: location, retryGeneration: 1))

        #expect(initialLoad)
        #expect(!unchangedLoad)
        #expect(retryLoad)
    }

    @Test("Stale callbacks cannot complete a newer retry generation")
    func staleCallbacksCannotCompleteNewerRetryGeneration() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let location = HealthEducationContentLocation.remote(url)
        let initialRequest = ArticleLoadRequest(
            location: location,
            retryGeneration: 0
        )
        let retryRequest = ArticleLoadRequest(
            location: location,
            retryGeneration: 1
        )
        let initialNavigation = NSObject()
        let retryNavigation = NSObject()
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadInitialRequest = tracker.shouldLoad(initialRequest)
        #expect(shouldLoadInitialRequest)
        let didTrackInitialNavigation = tracker.track(
            initialNavigation,
            for: initialRequest,
            role: .primary
        )
        #expect(didTrackInitialNavigation)
        let shouldLoadRetryRequest = tracker.shouldLoad(retryRequest)
        #expect(shouldLoadRetryRequest)
        let staleStart = tracker.navigationDidStart(initialNavigation)
        #expect(staleStart == nil)
        let didTrackRetryNavigation = tracker.track(
            retryNavigation,
            for: retryRequest,
            role: .primary
        )
        #expect(didTrackRetryNavigation)

        let staleDisposition = tracker.failureDisposition(
            for: initialNavigation,
            error: connectionFailure
        )
        #expect(staleDisposition == .ignore)
        let retryDisposition = tracker.failureDisposition(
            for: retryNavigation,
            error: connectionFailure
        )
        #expect(retryDisposition == .fail(retryRequest))
    }

    @Test("A newer retry clears pending navigation and cancellation tracking")
    func newerRetryClearsTransientTracking() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let initialRequest = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let retryRequest = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 1
        )
        let staleNavigation = NSObject()
        let internalPolicyCancellation = NSError(
            domain: "WebKitInternal",
            code: 0
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadInitialRequest = tracker.shouldLoad(initialRequest)
        #expect(shouldLoadInitialRequest)
        tracker.recordAllowedMainFrameNavigation()
        tracker.recordPolicyCancellation()

        let shouldLoadRetryRequest = tracker.shouldLoad(retryRequest)
        let staleStart = tracker.navigationDidStart(staleNavigation)
        let staleCancellationDisposition = tracker.failureDisposition(
            for: staleNavigation,
            error: internalPolicyCancellation
        )

        #expect(shouldLoadRetryRequest)
        #expect(staleStart == nil)
        #expect(staleCancellationDisposition == .ignore)
    }

    @Test("Allowed HTTPS follow-up failures are reported")
    func allowedHTTPSFollowUpFailureIsReported() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let articleNavigation = NSObject()
        let followUpNavigation = NSObject()
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        #expect(shouldLoadRequest)
        let didTrackArticleNavigation = tracker.track(
            articleNavigation,
            for: request,
            role: .primary
        )
        #expect(didTrackArticleNavigation)
        let articleCompletion = tracker.complete(articleNavigation)
        #expect(articleCompletion == ArticleTrackedNavigation(
            request: request,
            role: .primary
        ))

        tracker.recordAllowedMainFrameNavigation()
        let trackedFollowUp = tracker.navigationDidStart(followUpNavigation)
        #expect(trackedFollowUp == ArticleTrackedNavigation(
            request: request,
            role: .followUp
        ))
        let disposition = tracker.failureDisposition(
            for: followUpNavigation,
            error: connectionFailure
        )
        #expect(disposition == .fail(request))
    }

    @Test("Untracked navigation failures leave a loaded article unchanged")
    func untrackedNavigationFailureIsIgnored() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let untrackedNavigation = NSObject()
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        #expect(shouldLoadRequest)
        let trackedNavigation = tracker.navigationDidStart(untrackedNavigation)
        #expect(trackedNavigation == nil)

        let disposition = tracker.failureDisposition(
            for: untrackedNavigation,
            error: connectionFailure
        )
        #expect(disposition == .ignore)
    }

    @Test("Matching policy-cancellation callback leaves article state unchanged")
    func matchingPolicyCancellationCallbackIsIgnored() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let policyCancelledNavigation = NSObject()
        let internalPolicyCancellation = NSError(
            domain: "WebKitInternal",
            code: 0
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        #expect(shouldLoadRequest)
        tracker.recordPolicyCancellation()

        let disposition = tracker.failureDisposition(
            for: policyCancelledNavigation,
            error: internalPolicyCancellation
        )
        #expect(disposition == .ignorePolicyCancellation)
    }

    @Test("A policy cancellation cannot hide an allowed navigation failure")
    func policyCancellationCannotHideAllowedNavigationFailure() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let allowedNavigation = NSObject()
        let internalFailure = NSError(
            domain: "WebKitInternal",
            code: 0
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        #expect(shouldLoadRequest)
        tracker.recordPolicyCancellation()
        tracker.recordAllowedMainFrameNavigation()
        let trackedNavigation = tracker.navigationDidStart(allowedNavigation)
        #expect(trackedNavigation?.role == .followUp)

        let disposition = tracker.failureDisposition(
            for: allowedNavigation,
            error: internalFailure
        )
        #expect(disposition == .fail(request))
    }

    @Test("Nil navigation remains untracked and cannot fail the article")
    func nilNavigationRemainsUntracked() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        let didTrackNavigation = tracker.track(nil, for: request, role: .primary)
        let trackedStart = tracker.navigationDidStart(nil)
        let failureDisposition = tracker.failureDisposition(
            for: nil,
            error: connectionFailure
        )

        #expect(shouldLoadRequest)
        #expect(!didTrackNavigation)
        #expect(trackedStart == nil)
        #expect(failureDisposition == .ignore)
    }

    @Test("Allowed new-window failures are reported")
    func allowedNewWindowFailureIsReported() throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let request = ArticleLoadRequest(
            location: .remote(url),
            retryGeneration: 0
        )
        let newWindowNavigation = NSObject()
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost
        )
        var tracker = ArticleLoadTracker()

        let shouldLoadRequest = tracker.shouldLoad(request)
        #expect(shouldLoadRequest)
        let didTrackNewWindowNavigation = tracker.track(
            newWindowNavigation,
            for: request,
            role: .followUp
        )
        #expect(didTrackNewWindowNavigation)

        let disposition = tracker.failureDisposition(
            for: newWindowNavigation,
            error: connectionFailure
        )
        #expect(disposition == .fail(request))
    }

    @Test(
        "Allows HTTPS redirects and links on any host",
        arguments: [
            "https://www.hippocratestech.com/article",
            "HTTPS://redirect.example.net/path",
            "https://www.cdc.gov/asthma/about/index.html"
        ]
    )
    func allowsHTTPSNavigation(_ value: String) throws {
        let initialURL = try #require(URL(string: "https://example.com"))
        let candidateURL = try #require(URL(string: value))
        let policy = ArticleNavigationPolicy(location: .remote(initialURL))

        #expect(policy.decision(for: candidateURL) == .allow)
    }

    @Test("Allows the WebKit about blank placeholder")
    func allowsAboutBlank() throws {
        let initialURL = try #require(URL(string: "https://example.com"))
        let aboutBlankURL = try #require(URL(string: "about:blank"))
        let policy = ArticleNavigationPolicy(location: .remote(initialURL))

        #expect(policy.decision(for: aboutBlankURL) == .allow)
    }

    @Test("Loads allowed new-window HTTPS requests in the same web view")
    func loadsAllowedNewWindowHTTPSRequestInSameWebView() throws {
        let initialURL = try #require(URL(string: "https://example.com"))
        let targetURL = try #require(URL(string: "https://www.cdc.gov/asthma"))
        let handler = ArticleNewWindowNavigationHandler(
            navigationPolicy: ArticleNavigationPolicy(location: .remote(initialURL))
        )
        var loadedRequest: URLRequest?

        let createdWebView = handler.handle(
            request: URLRequest(url: targetURL),
            targetFrameIsNil: true
        ) { request in
            loadedRequest = request
        }

        #expect(createdWebView == nil)
        #expect(loadedRequest?.url == targetURL)
    }

    @Test(
        "Cancels unsupported schemes without article failure",
        arguments: [
            "http://example.com",
            "mailto:care@example.com",
            "tel:+351000000000",
            "health-app://article"
        ]
    )
    func cancelsUnsupportedSchemes(_ value: String) throws {
        let initialURL = try #require(URL(string: "https://example.com"))
        let candidateURL = try #require(URL(string: value))
        let policy = ArticleNavigationPolicy(location: .remote(initialURL))

        #expect(policy.decision(for: candidateURL) == .cancelWithoutFailure)
    }

    @Test("Allows only files within the resolved bundle directory")
    func constrainsLocalFileNavigation() {
        let articleURL = URL(fileURLWithPath: "/bundle/articles/asthma.html")
        let siblingURL = URL(fileURLWithPath: "/bundle/articles/reference.html")
        let outsideURL = URL(fileURLWithPath: "/private/outside.html")
        let policy = ArticleNavigationPolicy(location: .bundled(articleURL))

        #expect(policy.decision(for: articleURL) == .allow)
        #expect(policy.decision(for: siblingURL) == .allow)
        #expect(policy.decision(for: outsideURL) == .cancelWithoutFailure)
    }

    @Test("Ignores standard cancellation failures")
    func ignoresCancellationFailures() {
        let urlCancellation = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCancelled
        )
        let policyCancellation = NSError(
            domain: "WebKitErrorDomain",
            code: 102
        )
        let internalPolicyCancellation = NSError(
            domain: "WebKitInternal",
            code: 0
        )
        let connectionFailure = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet
        )

        #expect(!ArticleLoadErrorPolicy.shouldPublishFailure(for: urlCancellation))
        #expect(!ArticleLoadErrorPolicy.shouldPublishFailure(for: policyCancellation))
        #expect(ArticleLoadErrorPolicy.shouldPublishFailure(for: internalPolicyCancellation))
        #expect(ArticleLoadErrorPolicy.shouldPublishFailure(for: connectionFailure))
    }
}

@Suite("Health education production resources")
struct HealthEducationProductionResourceTests {
    @Test(
        "Fallback image asset exists in the host app",
        arguments: [
            "health-education-no-code",
            "health-education-diabetes",
            "health-education-asthma"
        ]
    )
    func fallbackImageAssetExists(_ imageName: String) {
        #expect(UIImage(named: imageName) != nil)
    }

    @Test(
        "Production HTML resource exists in the host app",
        arguments: ["type-2-diabetes", "asthma"]
    )
    func productionHTMLResourceExists(_ resourceName: String) {
        #expect(Bundle.main.url(forResource: resourceName, withExtension: "html") != nil)
    }
}

private extension HealthEducationContentLocation {
    var remoteURL: URL? {
        guard case .remote(let url) = self else { return nil }
        return url
    }
}

private func decodeRaw<T: Decodable>(
    _ type: T.Type,
    from object: Any
) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(type, from: data)
}

private func localized(_ englishValue: String) -> [String: String] {
    ["en": englishValue]
}

private func articleObject(
    id: String?,
    title: String
) -> [String: Any] {
    var object: [String: Any] = [
        "imageName": "health-education-test",
        "title": localized(title),
        "summary": localized("Summary for \(title)"),
        "url": "\(title.lowercased()).html"
    ]
    if let id {
        object["id"] = id
    }
    return object
}

private enum FailingHealthEducationYAMLDecoderError: Error {
    case requestedFailure
}

private struct FailingHealthEducationYAMLDecoder: OTFYAMLDecoding {
    func decode<T>(
        _ file: String,
        as type: T.Type
    ) throws -> T where T: OTFVersionedDecodable {
        throw FailingHealthEducationYAMLDecoderError.requestedFailure
    }
}
