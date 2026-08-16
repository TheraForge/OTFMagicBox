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

import Foundation
import OTFCareKitStore
import OTFUtilities
import OTFTemplateBox

final class CheckUpViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName = "CheckUpConfiguration"
        static let refreshDebounceInterval: TimeInterval = 0.2
    }

    typealias SummaryFetcher = (
        _ date: Date,
        _ forceRefresh: Bool,
        _ completion: @escaping (Result<DaySummarySnapshot, OCKStoreError>) -> Void
    ) -> Void
    typealias SnapshotInvalidator = (ScheduleRefreshContext) -> Void
    typealias RefreshScheduler = (TimeInterval, DispatchWorkItem) -> Void

    // MARK: - Publishers

    @Published private(set) var medicationSummary: CategorySummary = .zero
    @Published private(set) var activitySummary: CategorySummary = .zero
    @Published private(set) var checkupSummary: CategorySummary = .zero
    @Published private(set) var appointmentSummary: CategorySummary = .zero
    @Published private(set) var config: CheckUpConfiguration = .fallback

    // MARK: - Properties

    private let decoder: OTFYAMLDecoding
    private let logger = OTFLogger.logger()
    private var refreshWorkItem: DispatchWorkItem?
    private let calendar: Calendar
    private let now: () -> Date
    private let summaryFetcher: SummaryFetcher
    private let snapshotInvalidator: SnapshotInvalidator
    private let refreshScheduler: RefreshScheduler

    // MARK: - Init

    init(
        decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        summaryFetcher: @escaping SummaryFetcher = { date, forceRefresh, completion in
            CareKitStoreManager.shared.daySnapshotStore.summary(
                for: date,
                forceRefresh: forceRefresh,
                completion: completion
            )
        },
        snapshotInvalidator: @escaping SnapshotInvalidator = { context in
            CareKitStoreManager.shared.daySnapshotStore.invalidate(using: context)
        },
        refreshScheduler: @escaping RefreshScheduler = { delay, workItem in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    ) {
        self.decoder = decoder
        self.calendar = calendar
        self.now = now
        self.summaryFetcher = summaryFetcher
        self.snapshotInvalidator = snapshotInvalidator
        self.refreshScheduler = refreshScheduler
        load()
    }

    // MARK: - Methods

    func load() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: CheckUpConfiguration.self)
        } catch {
            logger.error("CheckUp YAML decode error: \(error)")
            self.config = .fallback
        }
    }

    func fetchTasks() {
        let today = calendar.startOfDay(for: now())

        fetchSummary(for: today, forceRefresh: false, errorMessage: "CheckUp summary fetch failed")
    }

    func scheduleRefresh() {
        scheduleRefresh(forceRefresh: true)
    }

    func scheduleRefresh(using notification: Notification) {
        let context = ScheduleRefreshContext(notification: notification) ?? ScheduleRefreshContext(changeKind: .fullResync)
        guard context.changeKind == .fullResync || context.affects(date: now(), calendar: calendar) else {
            return
        }

        snapshotInvalidator(context)
        scheduleRefresh(forceRefresh: true)
    }

    private func scheduleRefresh(forceRefresh: Bool) {
        refreshWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if forceRefresh {
                let today = self.calendar.startOfDay(for: self.now())
                self.fetchSummary(for: today, forceRefresh: true, errorMessage: "CheckUp summary refresh failed")
            } else {
                self.fetchTasks()
            }
        }

        refreshWorkItem = workItem
        refreshScheduler(FileConstants.refreshDebounceInterval, workItem)
    }

    private func fetchSummary(for date: Date, forceRefresh: Bool, errorMessage: String) {
        summaryFetcher(date, forceRefresh) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.logger.error("\(errorMessage): \(error)")
                self.applySummaries(from: nil)

            case .success(let snapshot):
                self.applySummaries(from: snapshot)
            }
        }
    }

    private func applySummaries(from snapshot: DaySummarySnapshot?) {
        medicationSummary = snapshot?.summary(for: .medication) ?? .zero
        activitySummary = snapshot?.summary(for: .activity) ?? .zero
        checkupSummary = snapshot?.summary(for: .checkup) ?? .zero
        appointmentSummary = snapshot?.summary(for: .appointment) ?? .zero
    }
}
