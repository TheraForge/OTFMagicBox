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

struct HealthEducationArticleView: View {
    @Environment(\.dismiss) private var dismiss

    private let article: HealthEducationArticle
    private let config: HealthEducationConfiguration
    private let resolver: HealthEducationContentResolver

    @State private var location: HealthEducationContentLocation?
    @State private var loadState: ArticleLoadState
    @State private var retryGeneration = 0

    init(
        article: HealthEducationArticle,
        config: HealthEducationConfiguration,
        resolver: HealthEducationContentResolver = HealthEducationContentResolver()
    ) {
        self.article = article
        self.config = config
        self.resolver = resolver
        let location = try? resolver.resolve(article.url)
        _location = State(initialValue: location)
        _loadState = State(initialValue: location == nil ? .failed : .loading)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(article.title.localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        styledCloseButton
                    }
                }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .accessibilityLabel(Text(config.closeButtonTitle.localized))
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var styledCloseButton: some View {
        if #available(iOS 17.0, *) {
            closeButton
                .buttonBorderShape(.circle)
        } else {
            closeButton
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .failed:
            failureView
        case .loading, .loaded:
            if let location {
                ZStack {
                    ArticleWebView(
                        location: location,
                        retryGeneration: retryGeneration,
                        loadState: $loadState
                    )
                    if loadState != .loaded {
                        ProgressView(config.loadingLabel.localized)
                            .padding()
                            .background(
                                .regularMaterial,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                }
            } else {
                failureView
            }
        }
    }

    private var failureView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(config.loadErrorTitle.localized)
                .font(.title2.bold())

            Text(config.loadErrorMessage.localized)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(config.retryButtonTitle.localized, action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func retry() {
        do {
            location = try resolver.resolve(article.url)
            retryGeneration += 1
            loadState = .loading
        } catch {
            location = nil
            loadState = .failed
        }
    }
}

#Preview {
    HealthEducationArticleView(
        article: HealthEducationConfiguration.fallback.articles[1],
        config: .fallback
    )
}
