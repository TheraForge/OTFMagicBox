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
import Combine
import OTFCareKit
import OTFCareKitStore

struct SensorTaskDetailView: View {

    private enum FileConstants {
        static let errorSpacing: CGFloat = 16
        static let errorSymbol = "exclamationmark.triangle.fill"
    }

    @StateObject private var viewModel: SensorTaskDetailViewModel

    @Environment(\.dismiss) private var dismiss
    private let config = SensorTaskConfigurationLoader.config

    init(viewModel: SensorTaskDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .background(HealthSensorVisualStyle.screenBackground)
                .navigationTitle(viewModel.metric.displayTitle(
                    config: HealthSensorsConfigurationLoader.config
                ))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(config.doneLabel.localized) {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ZStack {
                HealthSensorVisualStyle.screenBackground
                    .ignoresSafeArea()
                ProgressView(config.loadingLabel.localized)
            }
        case .pending:
            pendingContent
        case .submitted(let outcome, let submittedAt):
            SensorOutcomeSummaryView(
                metric: viewModel.metric,
                outcome: outcome,
                submittedAt: submittedAt,
                ecgReportState: viewModel.ecgReportState,
                retryECGReport: viewModel.retryECGReportDownload
            )
        case .failed:
            ZStack {
                HealthSensorVisualStyle.screenBackground
                    .ignoresSafeArea()

                HealthSensorSectionCard {
                    VStack(spacing: FileConstants.errorSpacing) {
                        Image(systemName: FileConstants.errorSymbol)
                            .font(.largeTitle)
                            .foregroundStyle(Color.orange)
                        Text(config.outcomeLoadError.localized)
                            .multilineTextAlignment(.center)
                        Button(config.retryLabel.localized, action: viewModel.refresh)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var pendingContent: some View {
        VStack(spacing: 0) {
            if viewModel.mode == .sensor {
                GenericHealthCardView(
                    metric: viewModel.metric,
                    onSendOutcome: viewModel.sendOutcome,
                    sendOutcomeDisabled: viewModel.sendOutcomeDisabled,
                    scheduledDate: viewModel.manualEntryDate
                )
            } else {
                ManualSensorEntryView(
                    metric: viewModel.metric,
                    scheduledDate: viewModel.manualEntryDate,
                    onSubmit: viewModel.sendOutcome
                )
                .disabled(viewModel.sendOutcomeDisabled)
            }

            if viewModel.submissionFailed {
                Text(config.outcomeLoadError.localized)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .padding()
            }
        }
    }
}

enum SensorTaskDetailState {
    case loading
    case pending
    case submitted(DecodedSensorOutcome, submittedAt: Date?)
    case failed
}

enum ECGReportLoadState: Equatable {
    case unavailable
    case loading
    case loaded(ECGReport)
    case failed
}

final class SensorTaskDetailViewModel: ObservableObject {

    typealias OutcomeFetcher = (
        OCKOutcomeQuery,
        DispatchQueue,
        @escaping (Result<[OCKAnyOutcome], OCKStoreError>) -> Void
    ) -> Void

    @Published private(set) var sendOutcomeDisabled = false
    @Published private(set) var submissionFailed = false
    @Published private(set) var state: SensorTaskDetailState = .loading
    @Published private(set) var ecgReportState: ECGReportLoadState = .unavailable

    let metric: HealthKitDataManager.HealthMetric
    let mode: SensorTaskMode
    var manualEntryDate: Date { selectedDate }

    private let task: OCKAnyTask
    private let selectedDate: Date
    private let occurrence: Int
    private let storeManager: OCKSynchronizedStoreManager
    private let outcomeFetcher: OutcomeFetcher
    private let attachmentStore: ECGReportAttachmentStoring
    private var cancellable: AnyCancellable?
    private var refreshGeneration = 0
    private var reportDownloadGeneration = 0

    init(
        task: OCKAnyTask,
        selectedDate: Date,
        occurrence: Int,
        storeManager: OCKSynchronizedStoreManager,
        metric: HealthKitDataManager.HealthMetric,
        mode: SensorTaskMode,
        outcomeFetcher: OutcomeFetcher? = nil,
        attachmentStore: ECGReportAttachmentStoring = ECGReportAttachmentStore.shared
    ) {
        self.task = task
        self.selectedDate = selectedDate
        self.occurrence = occurrence
        self.storeManager = storeManager
        self.metric = metric
        self.mode = mode
        self.attachmentStore = attachmentStore
        self.outcomeFetcher = outcomeFetcher ?? { query, callbackQueue, completion in
            storeManager.store.fetchAnyOutcomes(
                query: query,
                callbackQueue: callbackQueue,
                completion: completion
            )
        }

        cancellable = storeManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else { return }
                if let outcomeNotification = notification as? OCKOutcomeNotification {
                    guard
                        outcomeNotification.outcome.belongs(to: self.task),
                        outcomeNotification.outcome.taskOccurrenceIndex == self.occurrence
                    else {
                        return
                    }
                    self.refresh()
                } else if String(reflecting: type(of: notification)).contains("UnknownChangeNotification") {
                    self.refresh()
                }
            }
    }

    func sendOutcome(_ payload: SensorOutcomePayload) {
        sendOutcomeDisabled = true
        submissionFailed = false
        SensorTaskOutcomeHelper.sendOutcome(
            payload: payload,
            task: task,
            on: selectedDate,
            occurrence: occurrence,
            storeManager: storeManager,
            attachmentStore: attachmentStore
        ) { [weak self] success in
            if success {
                self?.refresh()
            } else {
                self?.sendOutcomeDisabled = false
                self?.submissionFailed = true
            }
        }
    }

    private var dayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    func refresh() {
        refreshGeneration += 1
        reportDownloadGeneration += 1
        let generation = refreshGeneration
        state = .loading
        ecgReportState = .unavailable
        var query = OCKOutcomeQuery(for: dayStart)
        query.taskUUIDs = [task.uuid]

        outcomeFetcher(query, .main) { [weak self] result in
            guard let self, generation == self.refreshGeneration else { return }
            switch result {
            case .success(let outcomes):
                let matchingOutcome = outcomes.first {
                    $0.taskOccurrenceIndex == self.occurrence
                }
                self.sendOutcomeDisabled = matchingOutcome != nil
                if let matchingOutcome {
                    let storedOutcome = matchingOutcome as? OCKOutcome
                    let decodedOutcome = SensorOutcomeCodec.decode(
                        metric: self.metric,
                        values: matchingOutcome.values
                    )
                    self.state = .submitted(
                        decodedOutcome,
                        submittedAt: storedOutcome?.createdDate ??
                            storedOutcome?.updatedDate ??
                            storedOutcome?.effectiveDate
                    )
                    self.loadECGReport(from: decodedOutcome, generation: generation)
                } else {
                    self.state = .pending
                }
            case .failure:
                self.sendOutcomeDisabled = false
                self.state = .failed
            }
        }
    }

    func retryECGReportDownload() {
        guard case .submitted(let outcome, _) = state else { return }
        loadECGReport(from: outcome, generation: refreshGeneration)
    }

    private func loadECGReport(
        from outcome: DecodedSensorOutcome,
        generation: Int
    ) {
        guard case .payload(let payload) = outcome else { return }
        guard let attachment = payload.ecgReportAttachment else { return }

        reportDownloadGeneration += 1
        let downloadGeneration = reportDownloadGeneration
        ecgReportState = .loading
        attachmentStore.download(attachment: attachment) { [weak self] result in
            guard
                let self,
                generation == self.refreshGeneration,
                downloadGeneration == self.reportDownloadGeneration
            else {
                return
            }
            switch result {
            case .success(let report):
                self.ecgReportState = .loaded(report)
            case .failure:
                self.ecgReportState = .failed
            }
        }
    }
}

struct SensorOutcomeSubmissionEnvironment {
    let now: Date
    let sessionIdentity: () -> String
    let scheduleSync: (_ initiatingSessionIdentity: String) -> Bool

    static func current(now: Date = Date()) -> SensorOutcomeSubmissionEnvironment {
        SensorOutcomeSubmissionEnvironment(
            now: now,
            sessionIdentity: { KeychainCloudManager.getEmailAddress },
            scheduleSync: { initiatingSessionIdentity in
                guard KeychainCloudManager.getEmailAddress == initiatingSessionIdentity else {
                    return false
                }
                CareKitStoreManager.shared.scheduleCloudantSyncForExplicitLocalMutation(
                    reason: "ios sensor outcome"
                )
                return true
            }
        )
    }
}

enum SensorTaskOutcomeHelper {
    private struct PersistenceContext {
        let storeManager: OCKSynchronizedStoreManager
        let now: Date
        let attachmentStore: ECGReportAttachmentStoring
        let initiatingSessionIdentity: String
        let sessionIdentity: () -> String
        let scheduleSync: (_ initiatingSessionIdentity: String) -> Bool

        var belongsToActiveSession: Bool {
            sessionIdentity() == initiatingSessionIdentity
        }
    }

    static func event(
        for task: OCKAnyTask,
        on date: Date,
        occurrence: Int? = nil
    ) -> OCKScheduleEvent? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let events = task.schedule.events(from: dayStart, to: dayEnd)
        guard let occurrence else { return events.first }
        return events.first { $0.occurrence == occurrence }
    }

    static func sendOutcome(
        payload: SensorOutcomePayload,
        task: OCKAnyTask,
        on date: Date,
        occurrence: Int? = nil,
        storeManager: OCKSynchronizedStoreManager,
        attachmentStore: ECGReportAttachmentStoring = ECGReportAttachmentStore.shared,
        environment: SensorOutcomeSubmissionEnvironment = .current(),
        completion: ((Bool) -> Void)? = nil
    ) {
        guard SensorOutcomeSubmissionPolicy.canSubmit(
            payload,
            on: date,
            now: environment.now
        ) else {
            completion?(false)
            return
        }
        let initiatingSessionIdentity = environment.sessionIdentity()
        let context = PersistenceContext(
            storeManager: storeManager,
            now: environment.now,
            attachmentStore: attachmentStore,
            initiatingSessionIdentity: initiatingSessionIdentity,
            sessionIdentity: environment.sessionIdentity,
            scheduleSync: environment.scheduleSync
        )

        if let report = payload.ecgReport, payload.ecgReportAttachment == nil {
            attachmentStore.upload(report: report) { result in
                switch result {
                case .success(let attachment):
                    guard environment.sessionIdentity() == initiatingSessionIdentity else {
                        attachmentStore.delete(attachmentID: attachment.attachmentID)
                        completion?(false)
                        return
                    }
                    persistOutcome(
                        payload: payload.replacingECGReport(with: attachment),
                        task: task,
                        on: date,
                        occurrence: occurrence,
                        uploadedAttachmentID: attachment.attachmentID,
                        context: context,
                        completion: completion
                    )
                case .failure:
                    completion?(false)
                }
            }
            return
        }

        persistOutcome(
            payload: payload,
            task: task,
            on: date,
            occurrence: occurrence,
            context: context,
            completion: completion
        )
    }

    private static func persistOutcome(
        payload: SensorOutcomePayload,
        task: OCKAnyTask,
        on date: Date,
        occurrence: Int?,
        uploadedAttachmentID: String? = nil,
        context: PersistenceContext,
        completion: ((Bool) -> Void)?
    ) {
        guard context.belongsToActiveSession else {
            if let uploadedAttachmentID {
                context.attachmentStore.delete(attachmentID: uploadedAttachmentID)
            }
            completion?(false)
            return
        }
        guard let outcome = makeOutcome(
            payload: payload,
            task: task,
            on: date,
            occurrence: occurrence,
            now: context.now
        ) else {
            if let uploadedAttachmentID {
                context.attachmentStore.delete(attachmentID: uploadedAttachmentID)
            }
            completion?(false)
            return
        }

        context.storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { result in
            switch result {
            case .success(let persistedOutcome):
                guard
                    context.belongsToActiveSession,
                    context.scheduleSync(context.initiatingSessionIdentity)
                else {
                    rollbackPersistedOutcome(
                        persistedOutcome,
                        uploadedAttachmentID: uploadedAttachmentID,
                        ownerID: task.uuid.uuidString,
                        context: context,
                        completion: completion
                    )
                    return
                }
                if let uploadedAttachmentID {
                    context.attachmentStore.markCommitted(
                        attachmentID: uploadedAttachmentID,
                        ownerID: task.uuid.uuidString
                    )
                }
                completion?(true)
            case .failure:
                if let uploadedAttachmentID {
                    context.attachmentStore.delete(attachmentID: uploadedAttachmentID)
                }
                completion?(false)
            }
        }
    }

    private static func rollbackPersistedOutcome(
        _ outcome: OCKAnyOutcome,
        uploadedAttachmentID: String?,
        ownerID: String,
        context: PersistenceContext,
        completion: ((Bool) -> Void)?
    ) {
        context.storeManager.store.deleteAnyOutcome(outcome, callbackQueue: .main) { result in
            if let uploadedAttachmentID {
                switch result {
                case .success:
                    context.attachmentStore.delete(attachmentID: uploadedAttachmentID)
                case .failure:
                    context.attachmentStore.markCommitted(
                        attachmentID: uploadedAttachmentID,
                        ownerID: ownerID
                    )
                }
            }
            completion?(false)
        }
    }

    static func makeOutcome(
        payload: SensorOutcomePayload,
        task: OCKAnyTask,
        on date: Date,
        occurrence: Int? = nil,
        now: Date = Date()
    ) -> OCKOutcome? {
        guard SensorOutcomeSubmissionPolicy.canSubmit(payload, on: date, now: now) else {
            return nil
        }
        guard payload.ecgReport == nil || payload.ecgReportAttachment != nil else {
            return nil
        }
        guard let event = event(for: task, on: date, occurrence: occurrence) else {
            return nil
        }

        let values = SensorOutcomeCodec.encode(payload)
        guard !values.isEmpty else { return nil }
        var outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: event.occurrence,
            values: values
        )
        outcome.effectiveDate = event.start
        return outcome
    }
}
