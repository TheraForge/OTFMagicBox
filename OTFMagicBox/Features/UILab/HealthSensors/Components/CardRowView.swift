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

struct CardRowView: View {

    private enum FileConstants {
        static let contentSpacing: CGFloat = 5
        static let detailSpacing: CGFloat = 2
        static let iconSize: CGFloat = 30
        static let rowSpacing: CGFloat = 12
        static let verticalPadding: CGFloat = 8
    }

    let card: HealthSensorCard
    @StateObject private var viewModel: CardRowViewModel

    init(card: HealthSensorCard) {
        self.card = card
        _viewModel = StateObject(wrappedValue: CardRowViewModel(metric: card.metric))
    }

    var body: some View {
        HStack(spacing: FileConstants.rowSpacing) {
            HealthSensorMetricIcon(metric: card.metric, size: FileConstants.iconSize)

            VStack(alignment: .leading, spacing: FileConstants.contentSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: FileConstants.rowSpacing) {
                    VStack(alignment: .leading, spacing: FileConstants.detailSpacing) {
                        Text(card.title)
                            .font(.headline)
                            .foregroundStyle(Color.primary)

                        Text(card.subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if let timestamp = viewModel.timestampText {
                        Text(timestamp)
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: FileConstants.rowSpacing) {
                    Text(viewModel.valueText)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(viewModel.usesPlaceholderStyle ? .secondary : .primary)
                        .monospacedDigit()

                    Spacer()

                    if let detail = viewModel.detailText {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }

        }
        .padding(.vertical, FileConstants.verticalPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .onAppear(perform: viewModel.start)
        .onDisappear(perform: viewModel.stop)
    }
}

#Preview {
    HealthSensorSectionCard {
        CardRowView(card: CardRegistry.cards.first!)
    }
    .padding()
    .background(HealthSensorVisualStyle.screenBackground)
}
