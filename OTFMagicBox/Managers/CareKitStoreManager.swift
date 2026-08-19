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

import Combine
import Foundation
import OTFCareKit
import OTFCareKitStore
import OTFCloudClientAPI
import OTFCloudantStore
import OTFUtilities

/// Manages the CareKit store and coordinates with Cloudant synchronization.
///
/// `CareKitStoreManager` is responsible for:
/// - Initializing and managing the `OTFCloudantStore`
/// - Providing access to the `OCKSynchronizedStoreManager` for CareKit views
/// - Subscribing to store notifications and triggering server sync when local data changes
///
/// ## Sync Behavior
/// When local store changes occur (e.g., user completes a task), this manager:
/// 1. Syncs to watchOS via `synchronize(target: .mobile)`
/// 2. Pushes/pulls to the remote Cloudant database via `syncCloudantStore`
///
/// The `notifyWhenDone: false` parameter prevents UI reload flickering for local changes,
/// since CareKit's own subscription system already updates the UI automatically.
class CareKitStoreManager: NSObject {
    // MARK: - Singleton

    static let shared = CareKitStoreManager()

    // MARK: - Public Properties

    lazy var peer = OTFWatchConnectivityPeer()
    private(set) var cloudantStore: OTFCloudantStore?
    private(set) var synchronizedStoreManager: OCKSynchronizedStoreManager!
    private(set) var cloudantSyncManager = CloudantSyncManager.shared
    lazy var daySnapshotStore = CareKitDaySnapshotStore(storeProvider: { [weak self] in
        self?.currentCloudantStore()
    })

    private(set) lazy var coordinator: OCKStoreCoordinator = {
        let coordinator = OCKStoreCoordinator()
        return coordinator
    }()

    // MARK: - Private Properties

    private let logger = OTFLogger.logger()
    private let ecgReportAttachmentLifecycle = ECGReportAttachmentLifecycleCoordinator()
    private var cancellable: AnyCancellable?
    private let watchSyncStateLock = NSLock()
    private var suppressOutgoingSync = 0
    private var isWatchSyncReady = WatchAuthSessionStore.shared.isLoginReadyPublishable(
        isLoggedIn: TheraForgeKeychainService.shared.loadAuth() != nil
    )

    // MARK: - Initialization

    override init() {
        super.init()

        peer.outboundMessageContextProvider = { [weak self] in
            guard TheraForgeKeychainService.shared.loadAuth() != nil else {
                return nil
            }
            guard self?.isWatchSyncReadyForOutboundMessages() == true else {
                return nil
            }
            return WatchAuthSessionStore.shared.currentContext()
        }

        guard let cloudantStore = cloudantSyncManager.cloudantStore else {
            logger.error("CareKitStoreManager: Failed to get Cloudant store")
            return
        }

        updateCloudantStore(cloudantStore)
        coordinator.attach(store: cloudantStore)
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        subscribeToNotifications()
        reconcilePendingECGReportAttachments()

        logger.debug("CareKitStoreManager: Initialized successfully")
    }

    // MARK: - Public Methods

    /// Refreshes the store references. Use this after wiping the database or switching users.
    func refreshStore() {
        // Re-fetch the store from the service (creates new instance if file was deleted)
        guard let newStore = try? StoreService.shared.currentStore(peer: peer) else {
            logger.error("CareKitStoreManager: Failed to create new store during refresh")
            return
        }

        // Update CloudantSyncManager's reference
        CloudantSyncManager.shared.cloudantStore = newStore
        newStore.ensureClientSideIndexes()

        // Update local reference
        updateCloudantStore(newStore)
        daySnapshotStore.invalidateAll()
        
        // Re-create coordinator and SynchronizedStoreManager
        let newCoordinator = OCKStoreCoordinator()
        newCoordinator.attach(store: newStore)
        self.coordinator = newCoordinator
        
        self.synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: newCoordinator)
        
        // Re-subscribe to notifications on the new manager
        subscribeToNotifications()
        reconcilePendingECGReportAttachments()
        
        logger.info("CareKitStoreManager: Store refreshed successfully")
    }

    func setWatchSyncReady(_ isReady: Bool) {
        withWatchSyncStateLock {
            isWatchSyncReady = isReady
        }
    }

    func isWatchSyncReadyForOutboundMessages() -> Bool {
        let stateReady = withWatchSyncStateLock {
            isWatchSyncReady
        }
        guard stateReady else {
            return false
        }
        return hasReadyWatchAuthSession()
    }

    func currentCloudantStoreForWatchSync() -> OTFCloudantStore? {
        let state = withWatchSyncStateLock {
            (isReady: isWatchSyncReady, store: cloudantStore)
        }

        guard state.isReady, hasReadyWatchAuthSession() else {
            logger.error("CareKitStoreManager: Watch sync requested before store is ready")
            return nil
        }

        guard let cloudantStore = state.store else {
            logger.error("CareKitStoreManager: Watch sync requested without an active store")
            return nil
        }

        return cloudantStore
    }

    /// Wipes the local database. Use with caution.
    func wipe() throws {
        setWatchSyncReady(false)
        try CloudantSyncManager.shared.cloudantStore?.datastoreManager.deleteDatastoreNamed("local_db")
        daySnapshotStore.invalidateAll()
        logger.info("CareKitStoreManager: Local database wiped")
    }

    #if DEBUG
    func setWatchSyncReadyForTesting(_ isReady: Bool) {
        setWatchSyncReady(isReady)
    }

    func isWatchSyncReadyForTesting() -> Bool {
        withWatchSyncStateLock {
            isWatchSyncReady
        }
    }
    #endif

    // MARK: - Private Methods

    private func updateCloudantStore(_ store: OTFCloudantStore?) {
        withWatchSyncStateLock {
            cloudantStore = store
        }
    }

    private func currentCloudantStore() -> OTFCloudantStore? {
        withWatchSyncStateLock {
            cloudantStore
        }
    }

    private func hasReadyWatchAuthSession() -> Bool {
        WatchAuthSessionStore.shared.isLoginReadyPublishable(
            isLoggedIn: TheraForgeKeychainService.shared.loadAuth() != nil
        )
    }

    private func withWatchSyncStateLock<T>(_ work: () -> T) -> T {
        watchSyncStateLock.lock()
        defer { watchSyncStateLock.unlock() }
        return work()
    }

    private var isApplyingRemoteWatchChanges: Bool {
        withWatchSyncStateLock {
            suppressOutgoingSync > 0
        }
    }

    private func initStore(forceUpdate: Bool = false) {
        #if HEALTH
        healthKitStore.populateSampleData()
        #endif
        UserDefaults.standard.set(Date(), forKey: Constants.Storage.kCareKitDataInitDate)
    }

    /// Subscribes to CareKit store notifications to trigger sync on local changes.
    private func subscribeToNotifications() {
        cancellable = synchronizedStoreManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleStoreNotification(notification)
            }

        logger.debug("CareKitStoreManager: Subscribed to store notifications")
    }

    /// Handles store notifications by syncing to server/watch.
    ///
    /// We use `notifyWhenDone: false` because:
    /// 1. CareKit already updates its UI automatically for local changes
    /// 2. Notifying here would cause redundant reloads and UI flickering
    /// 3. Only SSE (remote changes) should trigger UI reloads
    func beginApplyingRemoteWatchChanges() {
        withWatchSyncStateLock {
            suppressOutgoingSync += 1
        }
    }

    func endApplyingRemoteWatchChanges() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.withWatchSyncStateLock {
                self.suppressOutgoingSync = max(0, self.suppressOutgoingSync - 1)
            }
        }
    }

    func notifyRemoteOutcomeChange(_ reason: String) {
        guard let cloudantStore = currentCloudantStore() else {
            logger.error("CareKitStoreManager: Cannot notify remote outcome change without a store")
            return
        }

        synchronizedStoreManager.outcomeStore(cloudantStore, didEncounterUnknownChange: reason)
    }

    func notifyRemoteCloudantPullChange(_ reason: String, refreshContext: ScheduleRefreshContext?) {
        beginApplyingRemoteWatchChanges()
        if let refreshContext {
            daySnapshotStore.invalidate(using: refreshContext)
            NotificationCenter.default.postScheduleRefresh(refreshContext)
        }
        notifyRemoteOutcomeChange(reason)
        endApplyingRemoteWatchChanges()
    }

    func scheduleCloudantSyncForExplicitLocalMutation(reason: String, debounce: TimeInterval = 0.25) {
        CloudantSyncManager.shared.markPendingOfflineChanges()
        CloudantSyncManager.shared.recordLocalMutation()
        CloudantSyncManager.shared.scheduleIncrementalSync(reason: reason, debounce: debounce)
    }

    private func handleStoreNotification(_ notification: OCKStoreNotification) {
        ecgReportAttachmentLifecycle.handle(notification)

        guard !isApplyingRemoteWatchChanges else {
            logger.debug("CareKitStoreManager: Suppressing outbound sync while applying remote watch changes")
            return
        }

        if String(reflecting: type(of: notification)).contains("UnknownChangeNotification") {
            logger.debug("CareKitStoreManager: Skipping outbound sync for unknown change notification")
            return
        }

        SyncPerformanceTracker.shared.increment("store.notifications.ios")

        pushIncrementalWatchPayload(for: notification)
        if shouldScheduleCloudantSync(for: notification) {
            scheduleCloudantSyncForExplicitLocalMutation(reason: storeNotificationReason(notification))
        }
        if let scheduleRefreshContext = scheduleRefreshContext(for: notification) {
            NotificationCenter.default.postScheduleRefresh(scheduleRefreshContext, object: notification)
        }
        NotificationCenter.default.post(name: .localScheduleContentChanged, object: notification)
    }

    private func reconcilePendingECGReportAttachments() {
        guard let synchronizedStoreManager else { return }
        synchronizedStoreManager.store.fetchAnyOutcomes(
            query: OCKOutcomeQuery(),
            callbackQueue: .main
        ) { result in
            guard case .success(let outcomes) = result else { return }
            self.ecgReportAttachmentLifecycle.reconcile(
                outcomes: outcomes,
                store: synchronizedStoreManager.store
            )
        }
    }

    private func pushIncrementalWatchPayload(for notification: OCKStoreNotification) {
        guard let cloudantStore = currentCloudantStoreForWatchSync() else { return }

        do {
            switch notification {
            case let taskNotification as OCKTaskNotification:
                let deletions: [OTFWatchSyncDeletion]
                if taskNotification.category == .delete {
                    if let task = taskNotification.task as? OCKTask {
                        deletions = WatchStoreDeletionDescriptorBuilder.taskDeletionDescriptors(for: task)
                    } else {
                        deletions = [
                            OTFWatchSyncDeletion(
                                documentID: WatchStoreDeletionDescriptorBuilder.documentID(
                                    for: taskNotification.task
                                ),
                                entityType: .task
                            )
                        ]
                    }
                } else {
                    deletions = []
                }
                let payload = try cloudantStore.makeIncrementalSyncPayload(
                    tasks: taskNotification.category == .delete ? [] : [taskNotification.task as? OCKTask].compactMap { $0 },
                    deletions: deletions
                )
                tryPushWatchPayload(payload)

            case let outcomeNotification as OCKOutcomeNotification:
                let deletions: [OTFWatchSyncDeletion]
                if outcomeNotification.category == .delete {
                    if let outcome = outcomeNotification.outcome as? OCKOutcome {
                        deletions = WatchStoreDeletionDescriptorBuilder.outcomeDeletionDescriptors(
                            for: outcome,
                            documentIDs: deletedDocumentIDs(for: outcome)
                        )
                    } else {
                        deletions = [
                            OTFWatchSyncDeletion(
                                documentID: WatchStoreDeletionDescriptorBuilder.documentID(
                                    for: outcomeNotification.outcome
                                ),
                                entityType: .outcome
                            )
                        ]
                    }
                } else {
                    deletions = []
                }
                let payload = try cloudantStore.makeIncrementalSyncPayload(
                    outcomes: outcomeNotification.category == .delete ? [] : [outcomeNotification.outcome as? OCKOutcome].compactMap { $0 },
                    deletions: deletions
                )
                tryPushWatchPayload(payload)

            default:
                break
            }
        } catch {
            logger.error("CareKitStoreManager: Failed to build watch sync payload: \(error.localizedDescription)")
        }
    }

    private func tryPushWatchPayload(_ payload: OTFWatchSyncPayload) {
        guard !payload.isEmpty else { return }

        cloudantSyncManager.peer.pushIncrementalPayloadWithDeliveryOutcome(payload) { [weak self] result in
            switch result {
            case .success(.delivered):
                SyncPerformanceTracker.shared.recordWatchPayload(
                    direction: "sent",
                    tasks: payload.tasks.count,
                    outcomes: payload.outcomes.count,
                    deletions: payload.deletedDocumentIDs.count
                )
                self?.logger.debug("CareKitStoreManager: Watch incremental sync delivered")
            case .success(.queued):
                self?.logger.debug("CareKitStoreManager: Watch incremental sync queued")
            case .failure(let error):
                self?.logger.error("CareKitStoreManager: Watch incremental sync error: \(error.localizedDescription)")
            }
        }
    }

    private func storeNotificationReason(_ notification: OCKStoreNotification) -> String {
        switch notification {
        case is OCKTaskNotification:
            return "task notification"
        case is OCKOutcomeNotification:
            return "outcome notification"
        default:
            return "store notification"
        }
    }

    private func shouldScheduleCloudantSync(for notification: OCKStoreNotification) -> Bool {
        switch notification {
        case is OCKTaskNotification, is OCKOutcomeNotification:
            return true
        default:
            return true
        }
    }

    func scheduleRefreshContext(for notification: OCKStoreNotification) -> ScheduleRefreshContext? {
        switch notification {
        case is OCKTaskNotification:
            return ScheduleRefreshContext(changeKind: .taskMembership)
        case let notification as OCKOutcomeNotification:
            guard let outcome = notification.outcome as? OCKOutcome else {
                return ScheduleRefreshContext(changeKind: .fullResync)
            }
            return scheduleRefreshContext(for: outcome)
        default:
            return ScheduleRefreshContext(changeKind: .fullResync)
        }
    }

    func scheduleRefreshContext(for outcome: OCKOutcome) -> ScheduleRefreshContext {
        ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [outcome.effectiveDate])
    }

    private func deletedDocumentIDs(for outcome: OCKOutcome) -> [String] {
        currentCloudantStore()?.outcomeDeletionDocumentIDs(for: outcome) ?? [
            WatchStoreDeletionDescriptorBuilder.documentID(for: outcome)
        ]
    }

    func mockSensorTask(
        for metric: HealthKitDataManager.HealthMetric,
        mode: SensorTaskMode = .sensor,
        on date: Date = Date()
    ) {
        guard let store = cloudantStore else { return }

        let task = Self.makeMockSensorTask(for: metric, mode: mode, on: date)

        store.addAnyTasks([task], callbackQueue: .main) { [weak self] result in
            NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
            if case .failure(let error) = result {
                self?.logger.error("CareKitStoreManager: Sensor task add failed: \(error.localizedDescription)")
            }
        }
    }

    static func makeMockSensorTask(
        for metric: HealthKitDataManager.HealthMetric,
        mode: SensorTaskMode = .sensor,
        on date: Date,
        calendar: Calendar = .current
    ) -> OCKTask {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: date,
                end: endOfDay,
                interval: DateComponents(day: 1)
            )
        ])

        var task = OCKTask(
            id: UUID().uuidString,
            title: metric.taskTitle(for: mode),
            carePlanUUID: nil,
            schedule: schedule
        )
        task.instructions = metric.taskInstructions(for: mode)
        task.groupIdentifier = groupIdentifier(category: .checkup, viewType: metric.scheduleTaskType(for: mode))
        return task
    }

    private static func groupIdentifier(category: CheckUpTaskType, viewType: ScheduleTaskType) -> String? {
        let keys = GroupIdentifierKeys(category: category, viewType: viewType)
        guard let data = try? JSONEncoder().encode(keys) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

struct DayTaskSnapshot {
    let date: Date
    let tasks: [OCKTask]
}

struct DaySummarySnapshot {
    let date: Date
    let summaries: [CheckUpTaskType: CategorySummary]

    func summary(for category: CheckUpTaskType) -> CategorySummary {
        summaries[category] ?? .zero
    }
}

final class CareKitDaySnapshotStore {

    typealias TaskSnapshotCompletion = (Result<DayTaskSnapshot, OCKStoreError>) -> Void
    typealias SummarySnapshotCompletion = (Result<DaySummarySnapshot, OCKStoreError>) -> Void
    typealias TaskFetcher = (OCKTaskQuery, DispatchQueue, @escaping (Result<[OCKTask], OCKStoreError>) -> Void) -> Void
    typealias OutcomeFetcher = (
        OCKOutcomeQuery,
        DispatchQueue,
        @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void
    ) -> Void

    private let taskFetcher: TaskFetcher
    private let outcomeFetcher: OutcomeFetcher
    private let calendar: Calendar
    private let summaryBuilder: DaySummarySnapshotBuilder
    private let workQueue = DispatchQueue(label: "com.hippocrates.magicbox.daysnapshot", qos: .userInitiated)
    private let stateQueue = DispatchQueue(label: "com.hippocrates.magicbox.daysnapshot.state")

    private var cachedTaskSnapshots = [Date: DayTaskSnapshot]()
    private var cachedSummarySnapshots = [Date: DaySummarySnapshot]()
    private var inFlightTaskFetches = [Date: InFlightTaskFetch]()
    private var inFlightSummaryFetches = [Date: InFlightSummaryFetch]()
    private var taskFetchGenerations = [Date: Int]()
    private var summaryFetchGenerations = [Date: Int]()

    private struct InFlightTaskFetch {
        let generation: Int
        var completions: [TaskSnapshotCompletion]
    }

    private struct InFlightSummaryFetch {
        let generation: Int
        var completions: [SummarySnapshotCompletion]
    }

    init(storeProvider: @escaping () -> OTFCloudantStore?) {
        self.taskFetcher = { query, callbackQueue, completion in
            guard let store = storeProvider() else {
                completion(.failure(.fetchFailed(reason: "Cloudant store unavailable")))
                return
            }
            store.fetchTasks(query: query, callbackQueue: callbackQueue, completion: completion)
        }
        self.outcomeFetcher = { query, callbackQueue, completion in
            guard let store = storeProvider() else {
                completion(.failure(.fetchFailed(reason: "Cloudant store unavailable")))
                return
            }
            store.fetchOutcomes(query: query, callbackQueue: callbackQueue, completion: completion)
        }
        self.calendar = .current
        self.summaryBuilder = DaySummarySnapshotBuilder(calendar: .current)
    }

    init(
        calendar: Calendar = .current,
        taskFetcher: @escaping TaskFetcher,
        outcomeFetcher: @escaping OutcomeFetcher
    ) {
        self.taskFetcher = taskFetcher
        self.outcomeFetcher = outcomeFetcher
        self.calendar = calendar
        self.summaryBuilder = DaySummarySnapshotBuilder(calendar: calendar)
    }

    func cachedSnapshot(for date: Date) -> DayTaskSnapshot? {
        let normalizedDay = normalizedDate(for: date)
        return stateQueue.sync {
            cachedTaskSnapshots[normalizedDay]
        }
    }

    func snapshot(for date: Date, forceRefresh: Bool = false, completion: @escaping TaskSnapshotCompletion) {
        let normalizedDay = normalizedDate(for: date)

        if !forceRefresh, let snapshot = cachedSnapshot(for: normalizedDay) {
            DispatchQueue.main.async {
                completion(.success(snapshot))
            }
            return
        }

        let generationToFetch = stateQueue.sync { () -> Int? in
            if var inFlightFetch = inFlightTaskFetches[normalizedDay] {
                inFlightFetch.completions.append(completion)
                inFlightTaskFetches[normalizedDay] = inFlightFetch
                return nil
            }

            let generation = taskFetchGenerations[normalizedDay, default: 0]
            inFlightTaskFetches[normalizedDay] = InFlightTaskFetch(
                generation: generation,
                completions: [completion]
            )
            return generation
        }

        guard let generationToFetch else { return }
        fetchTaskSnapshot(for: normalizedDay, generation: generationToFetch)
    }

    func summary(for date: Date, forceRefresh: Bool = false, completion: @escaping SummarySnapshotCompletion) {
        let normalizedDay = normalizedDate(for: date)

        if !forceRefresh, let summarySnapshot = stateQueue.sync(execute: { cachedSummarySnapshots[normalizedDay] }) {
            DispatchQueue.main.async {
                completion(.success(summarySnapshot))
            }
            return
        }

        let generationToFetch = stateQueue.sync { () -> Int? in
            if var inFlightFetch = inFlightSummaryFetches[normalizedDay] {
                inFlightFetch.completions.append(completion)
                inFlightSummaryFetches[normalizedDay] = inFlightFetch
                return nil
            }

            let generation = summaryFetchGenerations[normalizedDay, default: 0]
            inFlightSummaryFetches[normalizedDay] = InFlightSummaryFetch(
                generation: generation,
                completions: [completion]
            )
            return generation
        }

        guard let generationToFetch else { return }

        snapshot(for: normalizedDay, forceRefresh: forceRefresh) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.finishSummaryFetch(for: normalizedDay, generation: generationToFetch, with: .failure(error))

            case .success(let taskSnapshot):
                self.fetchSummarySnapshot(for: normalizedDay, tasks: taskSnapshot.tasks, generation: generationToFetch)
            }
        }
    }

    func prefetchAdjacentDays(around date: Date) {
        [-1, 1]
            .compactMap { calendar.date(byAdding: .day, value: $0, to: date) }
            .forEach { date in
                snapshot(for: date) { _ in }
            }
    }

    func invalidate(using context: ScheduleRefreshContext, preserving preservedDays: Set<Date> = []) {
        stateQueue.async {
            let preservedDays = Set(preservedDays.map(self.normalizedDate(for:)))
            let affectedDays: Set<Date>

            if context.invalidatesAllDates {
                affectedDays = Set(
                    Array(self.cachedTaskSnapshots.keys) +
                    Array(self.cachedSummarySnapshots.keys) +
                    Array(self.inFlightTaskFetches.keys) +
                    Array(self.inFlightSummaryFetches.keys)
                )
                self.cachedTaskSnapshots.keys
                    .filter { !preservedDays.contains($0) }
                    .forEach { self.cachedTaskSnapshots.removeValue(forKey: $0) }
                self.cachedSummarySnapshots.keys
                    .filter { !preservedDays.contains($0) }
                    .forEach { self.cachedSummarySnapshots.removeValue(forKey: $0) }
            } else {
                affectedDays = Set(context.affectedDates.map(self.normalizedDate(for:)))
                affectedDays.forEach { normalizedDay in
                    if !preservedDays.contains(normalizedDay) {
                        self.cachedTaskSnapshots.removeValue(forKey: normalizedDay)
                        self.cachedSummarySnapshots.removeValue(forKey: normalizedDay)
                    }
                }
            }

            affectedDays.forEach { normalizedDay in
                self.taskFetchGenerations[normalizedDay, default: 0] += 1
                self.summaryFetchGenerations[normalizedDay, default: 0] += 1
                self.inFlightTaskFetches.removeValue(forKey: normalizedDay)
                self.inFlightSummaryFetches.removeValue(forKey: normalizedDay)
            }
        }
    }

    func invalidateAll() {
        stateQueue.async {
            let affectedDays = Set(
                Array(self.cachedTaskSnapshots.keys) +
                Array(self.cachedSummarySnapshots.keys) +
                Array(self.inFlightTaskFetches.keys) +
                Array(self.inFlightSummaryFetches.keys)
            )
            affectedDays.forEach { normalizedDay in
                self.taskFetchGenerations[normalizedDay, default: 0] += 1
                self.summaryFetchGenerations[normalizedDay, default: 0] += 1
            }
            self.cachedTaskSnapshots.removeAll()
            self.cachedSummarySnapshots.removeAll()
            self.inFlightTaskFetches.removeAll()
            self.inFlightSummaryFetches.removeAll()
        }
    }

    private func fetchTaskSnapshot(for date: Date, generation: Int) {
        let dayInterval = dayInterval(for: date)
        var taskQuery = OCKTaskQuery(dateInterval: dayInterval)
        taskQuery.excludesTasksWithNoEvents = true

        taskFetcher(taskQuery, workQueue) { [self] result in
            handleTaskFetchResult(result, for: date, generation: generation)
        }
    }

    private func handleTaskFetchResult(_ result: Result<[OCKTask], OCKStoreError>, for date: Date, generation: Int) {
        switch result {
        case .failure(let error):
            finishTaskFetch(for: date, generation: generation, with: .failure(error))

        case .success(let tasks):
            var dayTasks = [OCKTask]()
            for task in tasks where task.hasScheduledEvents(onDay: date, calendar: calendar) {
                dayTasks.append(task)
            }

            let snapshot = DayTaskSnapshot(date: date, tasks: dayTasks)
            finishTaskFetch(for: date, generation: generation, with: .success(snapshot))
        }
    }

    private func finishTaskFetch(for date: Date, generation: Int, with result: Result<DayTaskSnapshot, OCKStoreError>) {
        let completions = stateQueue.sync { () -> [TaskSnapshotCompletion] in
            guard let inFlightFetch = inFlightTaskFetches[date],
                  inFlightFetch.generation == generation else {
                return []
            }

            if case .success(let snapshot) = result {
                cachedTaskSnapshots[date] = snapshot
            }

            inFlightTaskFetches.removeValue(forKey: date)
            return inFlightFetch.completions
        }

        DispatchQueue.main.async {
            completions.forEach { $0(result) }
        }
    }

    private func fetchSummarySnapshot(for date: Date, tasks: [OCKTask], generation: Int) {
        guard !tasks.isEmpty else {
            let emptySummary = summaryBuilder.emptySnapshot(for: date)
            finishSummaryFetch(for: date, generation: generation, with: .success(emptySummary))
            return
        }

        var outcomeQuery = OCKOutcomeQuery(dateInterval: dayInterval(for: date))
        outcomeQuery.taskUUIDs = tasks.map { $0.uuid }

        outcomeFetcher(outcomeQuery, workQueue) { [self] result in
            switch result {
            case .failure(let error):
                finishSummaryFetch(for: date, generation: generation, with: .failure(error))

            case .success(let outcomes):
                let summarySnapshot = summaryBuilder.makeSummarySnapshot(
                    for: date,
                    tasks: tasks,
                    outcomes: outcomes
                )
                finishSummaryFetch(for: date, generation: generation, with: .success(summarySnapshot))
            }
        }
    }

    private func finishSummaryFetch(for date: Date, generation: Int, with result: Result<DaySummarySnapshot, OCKStoreError>) {
        let completions = stateQueue.sync { () -> [SummarySnapshotCompletion] in
            guard let inFlightFetch = inFlightSummaryFetches[date],
                  inFlightFetch.generation == generation else {
                return []
            }

            if case .success(let snapshot) = result {
                cachedSummarySnapshots[date] = snapshot
            }

            inFlightSummaryFetches.removeValue(forKey: date)
            return inFlightFetch.completions
        }

        DispatchQueue.main.async {
            completions.forEach { $0(result) }
        }
    }

    private func normalizedDate(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let startOfDay = normalizedDate(for: date)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? startOfDay
        return DateInterval(start: startOfDay, end: endOfDay)
    }
}

struct DaySummarySnapshotBuilder {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeSummarySnapshot(for date: Date, tasks: [OCKTask], outcomes: [OCKOutcome]) -> DaySummarySnapshot {
        let interval = dayInterval(for: date)
        let outcomesByTaskUUID = Dictionary(grouping: outcomes, by: \.taskUUID)
        var totalsByCategory = [CheckUpTaskType: Int]()
        var completedByCategory = [CheckUpTaskType: Int]()

        for task in tasks {
            let events = task.schedule.events(from: interval.start, to: interval.end)
            guard !events.isEmpty else { continue }

            let category = task.category
            totalsByCategory[category, default: 0] += 1

            let occurrencesForDay = Set(events.map(\.occurrence))
            let completedOccurrences = Set<Int>(
                (outcomesByTaskUUID[task.uuid] ?? []).compactMap { outcome in
                    guard occurrencesForDay.contains(outcome.taskOccurrenceIndex) else { return nil }
                    return outcome.taskOccurrenceIndex
                }
            )

            if completedOccurrences.count == occurrencesForDay.count {
                completedByCategory[category, default: 0] += 1
            }
        }

        let summaries = Dictionary(uniqueKeysWithValues: CheckUpTaskType.allCases.map { category in
            (
                category,
                CategorySummary(
                    totalTasks: totalsByCategory[category, default: 0],
                    completedTasks: completedByCategory[category, default: 0]
                )
            )
        })

        return DaySummarySnapshot(date: date, summaries: summaries)
    }

    func emptySnapshot(for date: Date) -> DaySummarySnapshot {
        DaySummarySnapshot(date: date, summaries: emptySummaries())
    }

    private func normalizedDate(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let startOfDay = normalizedDate(for: date)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? startOfDay
        return DateInterval(start: startOfDay, end: endOfDay)
    }

    private func emptySummaries() -> [CheckUpTaskType: CategorySummary] {
        Dictionary(uniqueKeysWithValues: CheckUpTaskType.allCases.map { category in
            (category, CategorySummary.zero)
        })
    }
}

private extension HealthKitDataManager.HealthMetric {
    func taskTitle(for mode: SensorTaskMode) -> String {
        let config = SensorTaskConfigurationLoader.config
        if mode == .manual {
            return String(
                format: config.manualTaskTitleFormat.localized,
                displayTitle(config: HealthSensorsConfigurationLoader.config)
            )
        }
        return switch self {
        case .heartRate: config.taskTitleHeartRate.localized
        case .bloodGlucose: config.taskTitleBloodGlucose.localized
        case .bloodPressure: config.taskTitleBloodPressure.localized
        case .ecg: config.taskTitleECG.localized
        case .respiratoryRate: config.taskTitleRespiratoryRate.localized
        case .restingHeartRate: config.taskTitleRestingHeartRate.localized
        case .oxygenSaturation: config.taskTitleOxygenSaturation.localized
        case .vo2Max: config.taskTitleVO2Max.localized
        }
    }

    func taskInstructions(for mode: SensorTaskMode) -> String {
        let config = SensorTaskConfigurationLoader.config
        if mode == .manual {
            return String(
                format: config.manualTaskInstructionsFormat.localized,
                displayTitle(config: HealthSensorsConfigurationLoader.config)
            )
        }
        return switch self {
        case .heartRate: config.taskInstructionsHeartRate.localized
        case .bloodGlucose: config.taskInstructionsBloodGlucose.localized
        case .bloodPressure: config.taskInstructionsBloodPressure.localized
        case .ecg: config.taskInstructionsECG.localized
        case .respiratoryRate: config.taskInstructionsRespiratoryRate.localized
        case .restingHeartRate: config.taskInstructionsRestingHeartRate.localized
        case .oxygenSaturation: config.taskInstructionsOxygenSaturation.localized
        case .vo2Max: config.taskInstructionsVO2Max.localized
        }
    }

    func scheduleTaskType(for mode: SensorTaskMode) -> ScheduleTaskType {
        switch (mode, self) {
        case (.sensor, .heartRate): .heartRate
        case (.sensor, .bloodGlucose): .bloodGlucose
        case (.sensor, .bloodPressure): .bloodPressure
        case (.sensor, .ecg): .ecg
        case (.sensor, .respiratoryRate): .respiratoryRate
        case (.sensor, .restingHeartRate): .restingHeartRate
        case (.sensor, .oxygenSaturation): .oxygenSaturation
        case (.sensor, .vo2Max): .vo2Max
        case (.manual, .heartRate): .manualHeartRate
        case (.manual, .bloodGlucose): .manualBloodGlucose
        case (.manual, .bloodPressure): .manualBloodPressure
        case (.manual, .ecg): .manualECG
        case (.manual, .respiratoryRate): .manualRespiratoryRate
        case (.manual, .restingHeartRate): .manualRestingHeartRate
        case (.manual, .oxygenSaturation): .manualOxygenSaturation
        case (.manual, .vo2Max): .manualVO2Max
        }
    }
}
