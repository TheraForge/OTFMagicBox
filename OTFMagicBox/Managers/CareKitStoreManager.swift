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
import OTFCareKit
import OTFCareKitStore
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

    private(set) lazy var coordinator: OCKStoreCoordinator = {
        let coordinator = OCKStoreCoordinator()
        return coordinator
    }()

    // MARK: - Private Properties

    private let logger = OTFLogger.logger()
    private var cancellable: AnyCancellable?

    // MARK: - Initialization

    override init() {
        super.init()

        guard let cloudantStore = cloudantSyncManager.cloudantStore else {
            logger.error("CareKitStoreManager: Failed to get Cloudant store")
            return
        }

        self.cloudantStore = cloudantStore
        coordinator.attach(store: cloudantStore)
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        subscribeToNotifications()

        logger.info("CareKitStoreManager: Initialized successfully")
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
        self.cloudantStore = newStore
        
        // Re-create coordinator and SynchronizedStoreManager
        let newCoordinator = OCKStoreCoordinator()
        newCoordinator.attach(store: newStore)
        self.coordinator = newCoordinator
        
        self.synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: newCoordinator)
        
        // Re-subscribe to notifications on the new manager
        subscribeToNotifications()
        
        logger.info("CareKitStoreManager: Store refreshed successfully")
    }

    /// Wipes the local database. Use with caution.
    func wipe() throws {
        try CloudantSyncManager.shared.cloudantStore?.datastoreManager.deleteDatastoreNamed("local_db")
        logger.info("CareKitStoreManager: Local database wiped")
    }

    // MARK: - Private Methods

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
            .sink { [weak self] _ in
                self?.handleStoreNotification()
            }

        logger.info("CareKitStoreManager: Subscribed to store notifications")
    }

    /// Handles store notifications by syncing to server/watch.
    ///
    /// We use `notifyWhenDone: false` because:
    /// 1. CareKit already updates its UI automatically for local changes
    /// 2. Notifying here would cause redundant reloads and UI flickering
    /// 3. Only SSE (remote changes) should trigger UI reloads
    private func handleStoreNotification() {
        // Mark pending offline changes if we're offline
        // This prevents data loss on next app launch
        if !NetworkHelper.isImmediatelyAvailable() {
            CloudantSyncManager.shared.markPendingOfflineChanges()
        }
        
        // Sync to watchOS
        CloudantSyncManager.shared.cloudantStore?.synchronize(target: .mobile) { [weak self] error in
            if let error = error {
                self?.logger.error("CareKitStoreManager: WatchOS sync error: \(error.localizedDescription)")
            } else {
                self?.logger.info("CareKitStoreManager: WatchOS sync completed")
            }
        }

        // Sync to remote server (no UI notification for local changes)
        CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: false, completion: nil)
    }

    func mockSensorTask(for metric: HealthKitDataManager.HealthMetric, on date: Date = Date()) {
        guard let store = cloudantStore else { return }

        var query = OCKTaskQuery(for: date)
        query.ids = [metric.scheduleTaskType.rawValue]

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        let time = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = time.hour ?? 9
        let minute = time.minute ?? 0
        let schedule = OCKSchedule.dailyAtTime(hour: hour, minutes: minute, start: date, end: endOfDay, text: nil)

        var task = OCKTask(id: UUID().uuidString, title: metric.taskTitle, carePlanUUID: nil, schedule: schedule)
        task.instructions = metric.taskInstructions
        task.groupIdentifier = groupIdentifier(category: .checkup, viewType: metric.scheduleTaskType)

        store.addAnyTasks([task], callbackQueue: .main) { [weak self] result in
            NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
            if case .failure(let error) = result {
                self?.logger.error("CareKitStoreManager: Sensor task add failed: \(error.localizedDescription)")
            }
        }
    }

    private func groupIdentifier(category: CheckUpTaskType, viewType: ScheduleTaskType) -> String? {
        let keys = GroupIdentifierKeys(category: category, viewType: viewType)
        guard let data = try? JSONEncoder().encode(keys) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private extension HealthKitDataManager.HealthMetric {
    var taskTitle: String {
        let config = SensorTaskConfigurationLoader.config
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

    var taskInstructions: String {
        let config = SensorTaskConfigurationLoader.config
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

    var scheduleTaskType: ScheduleTaskType {
        switch self {
        case .heartRate: .heartRate
        case .bloodGlucose: .bloodGlucose
        case .bloodPressure: .bloodPressure
        case .ecg: .ecg
        case .respiratoryRate: .respiratoryRate
        case .restingHeartRate: .restingHeartRate
        case .oxygenSaturation: .oxygenSaturation
        case .vo2Max: .vo2Max
        }
    }
}
