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
    @State private var cachedTasksByDay = [Date: [OCKTask]]()
    @State private var viewState: ViewState = .loading
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var fetchToken = UUID()
    @State private var prefetchedDaysInFlight = Set<Date>()

    private let careKitStore = OCKStoreManager.shared
    private let calendar = Calendar.current

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
                                .id(taskViewIdentity(for: task, date: selectedDate))
                            }
                        }
                    }
                }
            }
            .navigationTitle("MagicBox")
            .onAppear {
                loadDailyTasks(showLoadingState: true)
            }
            .onChange(of: selectedDate) { _ in
                loadDailyTasks(showLoadingState: cachedTasks(for: selectedDate) == nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .scheduleRefreshRequested)) { notification in
                handleScheduleRefresh(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
                tasks = []
                cachedTasksByDay.removeAll()
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

    private func loadDailyTasks(forceRefresh: Bool = false, showLoadingState: Bool) {
        guard let cloudantStore = careKitStore.cloudantStore else {
            viewState = .loggedOut
            return
        }

        let day = normalizedDate(for: selectedDate)
        if !forceRefresh, let cachedTasks = cachedTasksByDay[day] {
            tasks = cachedTasks
            viewState = .content
            SyncPerformanceTracker.shared.recordWatchScheduleLoad(date: selectedDate, fetchedTasks: cachedTasks.count, fromCache: true)
            return
        }

        if showLoadingState {
            viewState = .loading
        }

        let activeFetchToken = UUID()
        fetchToken = activeFetchToken

        var query = OCKTaskQuery(for: selectedDate)
        query.excludesTasksWithNoEvents = true

        cloudantStore.fetchTasks(query: query) { result in
            DispatchQueue.main.async {
                guard self.fetchToken == activeFetchToken else { return }

                switch result {
                case .failure:
                    self.tasks = self.cachedTasksByDay[day] ?? []
                    self.viewState = .content

                case .success(let data):
                    let todayTasks = data
                        .filter { $0.schedule.exists(onDay: selectedDate) }
                        .sorted { $0.id < $1.id }
                    self.cachedTasksByDay[day] = todayTasks
                    self.tasks = todayTasks
                    self.viewState = .content
                    SyncPerformanceTracker.shared.recordWatchScheduleLoad(date: selectedDate, fetchedTasks: todayTasks.count, fromCache: false)
                    self.prefetchAdjacentDays(around: selectedDate)
                }
            }
        }
    }

    private func handleScheduleRefresh(_ notification: Notification) {
        let context = ScheduleRefreshContext(notification: notification) ?? ScheduleRefreshContext(changeKind: .fullResync)
        let visibleDay = normalizedDate(for: selectedDate)
        let preserveVisibleDay = context.affects(date: selectedDate, calendar: calendar) && cachedTasksByDay[visibleDay] != nil
        invalidateCachedDays(using: context, preserving: preserveVisibleDay ? [visibleDay] : [])

        guard context.changeKind == .fullResync || context.affects(date: selectedDate, calendar: calendar) else {
            return
        }

        if context.changeKind == .outcomeOnly, preserveVisibleDay {
            return
        }

        loadDailyTasks(forceRefresh: true, showLoadingState: false)
    }

    private func invalidateCachedDays(using context: ScheduleRefreshContext, preserving preservedDays: Set<Date> = []) {
        let invalidation = WatchScheduleCacheInvalidation.result(
            cachedDays: Set(cachedTasksByDay.keys),
            prefetchedDaysInFlight: prefetchedDaysInFlight,
            context: context,
            preserving: preservedDays,
            calendar: calendar
        )

        cachedTasksByDay.keys
            .filter { !invalidation.cachedDays.contains($0) }
            .forEach {
            cachedTasksByDay.removeValue(forKey: $0)
        }
        prefetchedDaysInFlight = invalidation.prefetchedDaysInFlight
    }

    private func prefetchAdjacentDays(around date: Date) {
        [-1, 1]
            .compactMap { calendar.date(byAdding: .day, value: $0, to: date) }
            .forEach(prefetchTasksIfNeeded(for:))
    }

    private func prefetchTasksIfNeeded(for date: Date) {
        guard let cloudantStore = careKitStore.cloudantStore else { return }

        let normalizedDay = normalizedDate(for: date)
        guard cachedTasksByDay[normalizedDay] == nil,
              !prefetchedDaysInFlight.contains(normalizedDay) else {
            return
        }

        prefetchedDaysInFlight.insert(normalizedDay)

        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        cloudantStore.fetchTasks(query: query) { result in
            DispatchQueue.main.async {
                self.prefetchedDaysInFlight.remove(normalizedDay)

                guard case .success(let data) = result else { return }
                let dayTasks = data
                    .filter { $0.schedule.exists(onDay: date) }
                    .sorted { $0.id < $1.id }
                self.cachedTasksByDay[normalizedDay] = dayTasks
            }
        }
    }

    private func cachedTasks(for date: Date) -> [OCKTask]? {
        cachedTasksByDay[normalizedDate(for: date)]
    }

    private func normalizedDate(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func taskViewIdentity(for task: OCKTask, date: Date) -> String {
        let day = normalizedDate(for: date).timeIntervalSince1970
        return "\(task.id)-\(day)"
    }
}

#Preview {
    ScheduleView()
}
