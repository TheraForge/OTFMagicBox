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

import UIKit
import OTFCareKit
import OTFCareKitUI
import OTFCareKitStore
import OTFUtilities

/// Displays a daily schedule of CareKit tasks with support for multiple task view types.
///
/// `ScheduleViewController` extends `OCKDailyPageViewController` to:
/// - Display tasks for a selected date with appropriate view controllers
/// - Listen for database synchronization events and refresh content
/// - Handle empty states with a user-friendly tip view
///
/// ## Synchronization Behavior
/// The view controller observes `.databaseSynchronized` notifications and reloads content
/// after a short debounce delay (300ms). This debounce prevents rapid consecutive reloads
/// when multiple sync events occur in quick succession.
///
/// - Note: Local task completions do NOT trigger this reload because CareKit's internal
///   subscription system handles those updates automatically. Only remote changes
///   (from other devices via SSE) trigger the notification-based reload.
class ScheduleViewController: OCKDailyPageViewController {

    // MARK: - Configuration

    struct Strings {
        let noTasksTitle: String
        let noTasksSubtitle: String
        let deletedAlertTitle: String
        let deletedAlertMessage: String
    }

    // MARK: - Private Properties

    private let logger = OTFLogger.logger()
    private var loadTokens: [ObjectIdentifier: UUID] = [:]
    private var reloadWorkItem: DispatchWorkItem?
    private let reloadDebounceInterval: TimeInterval = 0.3
    
    /// Tracks first load to show skeleton cards while waiting for sync
    private var isFirstLoad = true

    // MARK: - Public Properties

    var onSelectedDateChange: ((Date) -> Void)?
    var strings: Strings?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        reloadWorkItem?.cancel()
    }

    // MARK: - Public Methods

    /// Navigates to today's date in the calendar.
    func goToToday(animated: Bool = true) {
        selectDate(Date(), animated: animated)
        onSelectedDateChange?(Date())
    }

    override func selectDate(_ date: Date, animated: Bool) {
        super.selectDate(date, animated: animated)
        onSelectedDateChange?(date)
    }

    // MARK: - OCKDailyPageViewController

    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        let listID = ObjectIdentifier(listViewController)
        let token = UUID()
        loadTokens[listID] = token

        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak listViewController] in
            self?.storeManager.store.fetchAnyTasks(query: query, callbackQueue: .main) { result in
                self?.handleTasksResult(result, listViewController: listViewController, date: date, token: token)
            }
        }
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStoreChangeNotification), name: .databaseSynchronized, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteProfileEventNotification), name: .deleteUserAccount, object: nil)
    }

    @objc private func didReceiveStoreChangeNotification(_ notification: Notification) {
        // Debounce rapid notifications
        reloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // If we receive a sync notification, we can assume the initial wait is over.
            self.isFirstLoad = false
            self.reload()
            
            // Force full UI refresh (including header rings) by toggling the date
            // The simple selectDate(current) is optimized away by CareKit, so we must
            // switch to a different date and back to force a redraw.
            let currentDate = self.selectedDate
            let pastDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) ?? currentDate
            
            // Temporarily disable callback to avoid side effects
            let originalCallback = self.onSelectedDateChange
            self.onSelectedDateChange = nil
            self.selectDate(pastDate, animated: false)
            self.selectDate(currentDate, animated: false)
            self.onSelectedDateChange = originalCallback
        }
        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + reloadDebounceInterval, execute: workItem)
    }

    @objc private func deleteProfileEventNotification(_ notification: Notification) {
        guard let strings = strings else { return }
        alertWithAction(title: strings.deletedAlertTitle, message: strings.deletedAlertMessage) { _ in
            OTFTheraforgeNetwork.shared.moveToOnboardingView()
        }
    }

    private func handleTasksResult(_ result: Result<[OCKAnyTask], OCKStoreError>, listViewController: OCKListViewController?, date: Date, token: UUID) {
        guard let list = listViewController, loadTokens[ObjectIdentifier(list)] == token else { return }

        switch result {
        case .failure(let error):
            logger.error("ScheduleViewController: fetchAnyTasks failed: \(error.localizedDescription)")
            isFirstLoad = false

        case .success(let tasks):
            // Filter and sort tasks for consistent display order
            let todayTasks = tasks
                .filter { $0.schedule.exists(onDay: date) }
                .sorted { $0.id < $1.id }
            
            if todayTasks.isEmpty {
                if isFirstLoad {
                    // Show skeleton cards while waiting for initial sync
                    appendSkeletonCards(to: list, count: 3)
                    
                    // Trigger a sync to ensure we don't wait forever if the notification was missed
                    CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true, completion: nil)
                } else {
                    // Actually empty - show tip view
                    appendEmptyStateView(to: list)
                }
            } else {
                isFirstLoad = false
                appendTaskViewControllers(for: todayTasks, to: list, date: date)
            }
        }
    }

    private func appendSkeletonCards(to list: OCKListViewController, count: Int) {
        for _ in 0..<count {
            let skeletonView = SkeletonCardView()
            list.appendView(skeletonView, animated: false)
        }
    }
    
    private func appendEmptyStateView(to list: OCKListViewController) {
        let tipView = TipView()
        tipView.headerView.titleLabel.text = strings?.noTasksTitle
        tipView.headerView.detailLabel.text = strings?.noTasksSubtitle
        list.appendView(tipView, animated: false)
    }

    private func appendTaskViewControllers(for tasks: [OCKAnyTask], to list: OCKListViewController, date: Date) {
        for task in tasks {

            guard task.schedule.exists(onDay: date) else { continue }

            let controller = createTaskViewController(for: task, date: date)
            list.appendViewController(controller, animated: false)
        }
    }

    private func createTaskViewController(for task: OCKAnyTask, date: Date) -> UIViewController {
        let eventQuery = OCKEventQuery(for: date)

        switch task.viewType {
        case .simple:
            return OCKSimpleTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .instruction:
            return OCKInstructionsTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .buttonLog:
            return OCKButtonLogTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .grid:
            return OCKGridTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .checklist:
            return OCKChecklistTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .steps:
            return MotionStepsHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .cadence:
            return MotionCadenceHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .balance:
            return MotionBalanceHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .accelerometer:
            return MotionAccelerometerHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .gyroscope:
            return MotionGyroscopeHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .gps:
            return MotionGPSHostingController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .heartRate:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .heartRate)
        case .bloodGlucose:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .bloodGlucose)
        case .bloodPressure:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .bloodPressure)
        case .ecg:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .ecg)
        case .respiratoryRate:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .respiratoryRate)
        case .restingHeartRate:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .restingHeartRate)
        case .oxygenSaturation:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .oxygenSaturation)
        case .vo2Max:
            return SensorTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager, selectedDate: date, metric: .vo2Max)
        }
    }
}
