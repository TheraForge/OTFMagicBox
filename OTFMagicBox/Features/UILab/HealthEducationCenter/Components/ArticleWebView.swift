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

import SwiftUI
import WebKit

enum ArticleLoadState: Equatable {
    case loading
    case loaded
    case failed
}

struct ArticleLoadRequest: Equatable {
    let location: HealthEducationContentLocation
    let retryGeneration: Int
}

enum ArticleNavigationRole: Equatable {
    case primary
    case followUp
}

struct ArticleTrackedNavigation: Equatable {
    let request: ArticleLoadRequest
    let role: ArticleNavigationRole
}

enum ArticleNavigationFailureDisposition: Equatable {
    case ignore
    case ignorePolicyCancellation
    case fail(ArticleLoadRequest)
}

struct ArticleLoadTracker {
    private(set) var previousRequest: ArticleLoadRequest?
    private var trackedNavigations: [ObjectIdentifier: ArticleTrackedNavigation] = [:]
    private var pendingMainFrameRequest: ArticleLoadRequest?
    private var policyCancellationRequest: ArticleLoadRequest?
    private var pendingPolicyCancellationCount = 0

    mutating func shouldLoad(_ request: ArticleLoadRequest) -> Bool {
        guard previousRequest != request else { return false }
        previousRequest = request
        trackedNavigations.removeAll(keepingCapacity: true)
        pendingMainFrameRequest = nil
        policyCancellationRequest = request
        pendingPolicyCancellationCount = 0
        return true
    }

    mutating func track(
        _ navigation: AnyObject?,
        for request: ArticleLoadRequest,
        role: ArticleNavigationRole
    ) -> Bool {
        guard let navigation,
              isCurrent(request) else { return false }
        trackedNavigations[ObjectIdentifier(navigation)] = ArticleTrackedNavigation(
            request: request,
            role: role
        )
        return true
    }

    mutating func recordAllowedMainFrameNavigation() {
        pendingMainFrameRequest = previousRequest
    }

    mutating func navigationDidStart(
        _ navigation: AnyObject?
    ) -> ArticleTrackedNavigation? {
        guard let navigation else { return nil }
        let identifier = ObjectIdentifier(navigation)
        if let trackedNavigation = trackedNavigations[identifier] {
            if pendingMainFrameRequest == trackedNavigation.request {
                pendingMainFrameRequest = nil
            }
            return trackedNavigation
        }
        guard let request = pendingMainFrameRequest,
              isCurrent(request) else {
            pendingMainFrameRequest = nil
            return nil
        }
        pendingMainFrameRequest = nil
        let trackedNavigation = ArticleTrackedNavigation(
            request: request,
            role: .followUp
        )
        trackedNavigations[identifier] = trackedNavigation
        return trackedNavigation
    }

    mutating func complete(
        _ navigation: AnyObject?
    ) -> ArticleTrackedNavigation? {
        guard let navigation else { return nil }
        return trackedNavigations.removeValue(
            forKey: ObjectIdentifier(navigation)
        )
    }

    mutating func recordPolicyCancellation() {
        guard let request = previousRequest else { return }
        if policyCancellationRequest != request {
            policyCancellationRequest = request
            pendingPolicyCancellationCount = 0
        }
        pendingPolicyCancellationCount += 1
    }

    mutating func failureDisposition(
        for navigation: AnyObject?,
        error: Error
    ) -> ArticleNavigationFailureDisposition {
        if let trackedNavigation = complete(navigation) {
            guard isCurrent(trackedNavigation.request),
                  ArticleLoadErrorPolicy.shouldPublishFailure(for: error) else {
                return .ignore
            }
            return .fail(trackedNavigation.request)
        }

        guard ArticleLoadErrorPolicy.isInternalPolicyCancellation(error),
              consumePolicyCancellation() else {
            return .ignore
        }
        return .ignorePolicyCancellation
    }

    func isCurrent(_ request: ArticleLoadRequest) -> Bool {
        previousRequest == request
    }

    private mutating func consumePolicyCancellation() -> Bool {
        guard policyCancellationRequest == previousRequest,
              pendingPolicyCancellationCount > 0 else { return false }
        pendingPolicyCancellationCount -= 1
        return true
    }
}

enum ArticleLoadErrorPolicy {
    static func shouldPublishFailure(for error: Error) -> Bool {
        let error = error as NSError
        let isURLCancellation = error.domain == NSURLErrorDomain
            && error.code == NSURLErrorCancelled
        let isPolicyCancellation = error.domain == "WebKitErrorDomain"
            && error.code == 102
        return !isURLCancellation && !isPolicyCancellation
    }

    static func isInternalPolicyCancellation(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == "WebKitInternal" && error.code == 0
    }
}

struct ArticleNewWindowNavigationHandler {
    let navigationPolicy: ArticleNavigationPolicy

    func handle(
        request: URLRequest,
        targetFrameIsNil: Bool,
        load: (URLRequest) -> Void
    ) -> WKWebView? {
        guard targetFrameIsNil,
              navigationPolicy.decision(for: request.url) == .allow else {
            return nil
        }
        load(request)
        return nil
    }
}

struct ArticleWebView: UIViewRepresentable {
    let location: HealthEducationContentLocation
    let retryGeneration: Int
    @Binding var loadState: ArticleLoadState

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.navigationPolicy = ArticleNavigationPolicy(location: location)
        let request = loadRequest
        guard context.coordinator.loadTracker.shouldLoad(request) else { return }
        context.coordinator.begin(request)

        let navigation: WKNavigation?
        switch location {
        case .remote(let url):
            navigation = webView.load(URLRequest(url: url))
        case .bundled(let url):
            navigation = webView.loadFileURL(
                url,
                allowingReadAccessTo: url.deletingLastPathComponent()
            )
        }
        context.coordinator.track(navigation, for: request)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    private var loadRequest: ArticleLoadRequest {
        ArticleLoadRequest(
            location: location,
            retryGeneration: retryGeneration
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ArticleWebView
        var loadTracker = ArticleLoadTracker()
        var navigationPolicy: ArticleNavigationPolicy

        init(parent: ArticleWebView) {
            self.parent = parent
            navigationPolicy = ArticleNavigationPolicy(location: parent.location)
        }

        func begin(_ request: ArticleLoadRequest) {
            publish(.loading, for: request)
        }

        func track(
            _ navigation: WKNavigation?,
            for request: ArticleLoadRequest
        ) {
            _ = loadTracker.track(
                navigation,
                for: request,
                role: .primary
            )
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation?
        ) {
            guard let trackedNavigation = loadTracker.navigationDidStart(navigation),
                  trackedNavigation.role == .primary else { return }
            publish(.loading, for: trackedNavigation.request)
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation?
        ) {
            guard let trackedNavigation = loadTracker.complete(navigation) else { return }
            publish(.loaded, for: trackedNavigation.request)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            handleFailure(error, navigation: navigation)
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            handleFailure(error, navigation: navigation)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            switch navigationPolicy.decision(for: navigationAction.request.url) {
            case .allow:
                // WKNavigationDelegate lifecycle callbacks report main-frame
                // navigations, while policy decisions also include subframes.
                if navigationAction.targetFrame?.isMainFrame == true {
                    loadTracker.recordAllowedMainFrameNavigation()
                }
                decisionHandler(.allow)
            case .cancelWithoutFailure:
                if navigationAction.mayProduceMainFrameCancellationCallback {
                    loadTracker.recordPolicyCancellation()
                }
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            ArticleNewWindowNavigationHandler(
                navigationPolicy: navigationPolicy
            ).handle(
                request: navigationAction.request,
                targetFrameIsNil: navigationAction.targetFrame == nil
            ) { request in
                trackFollowUp(webView.load(request))
            }
        }

        private func publish(
            _ state: ArticleLoadState,
            for request: ArticleLoadRequest
        ) {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      loadTracker.isCurrent(request),
                      parent.loadRequest == request,
                      parent.loadState != state else { return }
                parent.loadState = state
            }
        }

        private func handleFailure(
            _ error: Error,
            navigation: WKNavigation?
        ) {
            guard case .fail(let request) = loadTracker.failureDisposition(
                for: navigation,
                error: error
            ) else { return }
            publish(.failed, for: request)
        }

        private func trackFollowUp(_ navigation: WKNavigation?) {
            guard let request = loadTracker.previousRequest else { return }
            _ = loadTracker.track(
                navigation,
                for: request,
                role: .followUp
            )
        }
    }
}

private extension WKNavigationAction {
    var mayProduceMainFrameCancellationCallback: Bool {
        targetFrame == nil || targetFrame?.isMainFrame == true
    }
}
