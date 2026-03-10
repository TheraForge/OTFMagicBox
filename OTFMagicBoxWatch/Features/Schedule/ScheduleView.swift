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
import OTFCareKit
import OTFCareKitStore

struct ScheduleView: View {

    enum ViewState {
        case loading, loggedOut, content
    }

    @State private var tasks: [OCKTask] = []
    @State private var viewState: ViewState = .loading
    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    private let careKitStore = OCKStoreManager.shared

    private let dateRange: ClosedRange<Date> = {
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -12, to: now) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 12, to: now) ?? now
        return start...end
    }()

    var body: some View {
        NavigationStack {
            Group {
                switch viewState {
                case .loading:
                    ProgressView()

                case .loggedOut:
                    ContentUnavailable(
                        "Sign in to MagicBox",
                        symbol: "person.badge.key",
                        description: Text("Sign in on your iPhone to sync your tasks and progress.")
                    )

                case .content:
                    ScrollView {
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Text(selectedDate.formatted(.dateTime.day().month(.abbreviated).year()))
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom)

                        if tasks.isEmpty {
                            VStack(alignment: .leading) {
                                Text("No Tasks")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("No tasks for this date")
                                    .font(.footnote)
                            }
                        } else {
                            ForEach(tasks, id: \.id) { task in
                                SimpleTaskView(
                                    taskID: task.id,
                                    eventQuery: .init(for: selectedDate),
                                    storeManager: careKitStore.synchronizedStoreManager
                                )
                                .id(task.id + selectedDate.timeIntervalSinceReferenceDate.description)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MagicBox")
            .onAppear(perform: loadDailyTasks)
            .onChange(of: selectedDate) { _ in
                loadDailyTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .databaseSynchronized)) { _ in
                viewState = .loading
                loadDailyTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
                tasks = []
                viewState = .loggedOut
            }
            .sheet(isPresented: $showDatePicker) {
                if #available(watchOS 10.0, *) {
                    DatePicker(
                        "Select a date",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: [.date]
                    )
                }
            }
        }
    }

    private func loadDailyTasks() {
        guard let cloudantStore = careKitStore.cloudantStore else {
            viewState = .loggedOut
            return
        }

        cloudantStore.fetchTasks { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.tasks = []
                    self.viewState = .content

                case .success(let data):
                    let todayTasks = data
                        .filter { $0.schedule.exists(onDay: selectedDate) }
                        .sorted { $0.id < $1.id }
                    self.tasks = todayTasks
                    self.viewState = .content
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
}
