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
import OSLog

struct LogView: View {

    private enum FileConstants {
        static let emptySymbol = "doc.text.magnifyingglass"
        static let refreshSymbol = "arrow.clockwise"
        static let filterSymbol = "slider.horizontal.3"
    }

    @StateObject private var model = LogViewModel()
    @State private var showFilters = false

    var body: some View {
        ZStack {
            if model.isLoading {
                ProgressView()
                    .tint(.secondary)

            } else if model.filteredEntries.isEmpty {
                ContentUnavailable(
                    model.config.emptyTitle.localized,
                    symbol: FileConstants.emptySymbol,
                    description: Text(model.config.emptySubtitle.localized)
                )
            } else {
                List(model.filteredEntries, id: \.self) { entry in
                    NavigationLink {
                        LogDetailView(entry: entry, config: model.config)
                    } label: {
                        LogRow(entry: entry, maxLines: model.config.rowsMaxLines)
                    }
                }
                .listStyle(.plain)
                .refreshable { model.refresh() }
            }
        }
        .navigationTitle(model.config.navTitle.localized)
        .globalStyle(.navigationTitleDisplayMode)
        .searchable(
            text: $model.search,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(model.config.searchPlaceholder.localized)
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(model.config.refreshTitle.localized, systemImage: FileConstants.refreshSymbol) {
                    model.refresh()
                }

                if let url = model.shareURL, !model.entries.isEmpty {
                    ShareLink(model.config.exportTitle.localized, item: url)
                }

                Button(model.config.filterLabel.localized, systemImage: FileConstants.filterSymbol) {
                    showFilters.toggle()
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            LogFilterView(model: model)
                .presentationDetents([.medium])
        }
        .alert(model.alertMessage, isPresented: $model.showAlert) {}
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
}
