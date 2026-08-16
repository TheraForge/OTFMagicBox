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

enum HealthSensorVisualStyle {
    static let cardCornerRadius: CGFloat = 12
    static let cardShadowOpacity = 0.07
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowYOffset: CGFloat = 2
    static let contentSpacing: CGFloat = 16
    static let fieldMinimumHeight: CGFloat = 76
    static let horizontalPadding: CGFloat = 16
    static let screenBottomPadding: CGFloat = 72
    static let screenTopPadding: CGFloat = 8
    static let sectionLabelSpacing: CGFloat = 8
    static let sectionPadding: CGFloat = 16
    static let segmentedControlVerticalPadding: CGFloat = 12

    static var screenBackground: Color {
        Color(.systemGroupedBackground)
    }

    static var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

}

struct HealthSensorMetricIcon: View {
    let metric: HealthKitDataManager.HealthMetric
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 36

    init(
        metric: HealthKitDataManager.HealthMetric,
        size: CGFloat = 36
    ) {
        self.metric = metric
        _size = ScaledMetric(wrappedValue: size, relativeTo: .title2)
    }

    var body: some View {
        Image(systemName: metric.sensorSymbol)
            .font(.system(size: size * 0.58, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct HealthSensorFieldSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, HealthSensorVisualStyle.sectionPadding)
    }
}

struct HealthSensorSectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: HealthSensorVisualStyle.cardCornerRadius,
            style: .continuous
        )

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(HealthSensorVisualStyle.sectionPadding)
            .background(HealthSensorVisualStyle.cardBackground, in: shape)
            .overlay {
                shape
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(HealthSensorVisualStyle.cardShadowOpacity),
                radius: HealthSensorVisualStyle.cardShadowRadius,
                y: HealthSensorVisualStyle.cardShadowYOffset
            )
    }
}

struct HealthSensorSectionTitle: View {
    let title: String
    var systemImage: String?

    var body: some View {
        Label {
            Text(title)
                .font(.headline)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
