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

import SwiftUI
import OTFTemplateBox

struct OnboardingView: View {

    @StateObject private var model = OnboardingViewModel()

    @State private var sheet: Sheet?
    @State private var backgroundColor: Color = Color(.systemBackground)

    var body: some View {
        ZStack {
            LinearGradient(colors: [backgroundColor.opacity(0.5), .clear, .clear], startPoint: .top, endPoint: .bottom)
                .animation(.easeInOut(duration: 0.35), value: backgroundColor)
                .ignoresSafeArea()

            VStack {
                TabView(selection: $model.currentPage) {
                    ForEach(Array(model.config.pages.enumerated()), id: \.1.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                            .accessibilityElement(children: .contain)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    sheet = .signup
                } label: {
                    Text(model.config.primaryButtonTitle.localized)
                        .foregroundStyle(model.config.primaryButtonTitleColor.color)
                        .frame(maxWidth: .infinity)
                }.tint(model.config.primaryButtonBackgroundColor.color)

                Button {
                    sheet = .signin
                } label: {
                    Text(model.config.secondaryButtonTitle.localized)
                        .foregroundStyle(model.config.secondaryButtonTitleColor.color)
                        .frame(maxWidth: .infinity)
                }
                // Apply the app-wide tint color defined by the global style system.
                // Use this when you want the secondary button to automatically follow the app's current accent color.
                .globalStyle(.tintColor)
                // Alternatively, uncomment the line below to override the tint with a specific color from the onboarding configuration.
                // This is useful when the design calls for a custom secondary action color that differs from the global tint.
                // .tint(model.config.secondaryButtonBackgroundColor.color)
            }
            .fontWeight(.semibold)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(item: $sheet) { result in
            Group {
                switch result {
                case .signin: AuthTaskRepresentable(mode: .login)
                case .signup: AuthTaskRepresentable(mode: .signup)
                }
            }.ignoresSafeArea()
        }
        .onAppear {
            updateAnimatedBackground()
        }
        .onChange(of: model.currentPage) { _ in
            updateAnimatedBackground()
        }
        .onChange(of: model.config.pages.count) { _ in
            updateAnimatedBackground()
        }
    }

    private func updateAnimatedBackground() {
        if let color = model.config.pages[safe: model.currentPage]?.backgroundColor.color {
            backgroundColor = color
        } else {
            backgroundColor = Color(.systemBackground)
        }
    }
}

// MARK: - Helpers

extension OnboardingView {
    enum Sheet: Hashable, Identifiable {
        var id: Self { self }
        case signin
        case signup
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
