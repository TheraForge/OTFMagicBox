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
/// The view controller observes typed schedule refresh notifications and only invalidates
/// the cached days that were affected. Full resyncs still reload the visible day, while
/// outcome-only changes can avoid unnecessary cold reloads.
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
    private let calendar = Calendar.current
    private let initialDate: Date
    private var loadTokens: [ObjectIdentifier: UUID] = [:]
    private var reloadWorkItem: DispatchWorkItem?
    private let reloadDebounceInterval: TimeInterval = 0.3
    private var isApplyingInitialDate = false
    
    /// Tracks first load to show skeleton cards while waiting for sync
    private var isFirstLoad = true

    // MARK: - Public Properties

    var onSelectedDateChange: ((Date) -> Void)?
    var strings: Strings?

    // MARK: - Lifecycle

    init(storeManager: OCKSynchronizedStoreManager, initialDate: Date = Date()) {
        self.initialDate = initialDate
        super.init(storeManager: storeManager)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        isApplyingInitialDate = true
        super.viewDidLoad()

        if !calendar.isDate(selectedDate, inSameDayAs: initialDate) {
            super.selectDate(initialDate, animated: false)
        }

        isApplyingInitialDate = false
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
        let calendar = Calendar.current
        if calendar.isDate(selectedDate, inSameDayAs: date) {
            return
        }

        super.selectDate(date, animated: animated)
        onSelectedDateChange?(date)
    }

    // MARK: - OCKDailyPageViewController

    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        reportSelectedDateIfVisible(date)

        let listID = ObjectIdentifier(listViewController)
        let token = UUID()
        loadTokens[listID] = token

        let snapshotStore = CareKitStoreManager.shared.daySnapshotStore
        if let cachedSnapshot = snapshotStore.cachedSnapshot(for: date) {
            let cachedTasks = cachedSnapshot.tasks.map { $0 as OCKAnyTask }
            SyncPerformanceTracker.shared.recordScheduleLoad(date: date, fetchedTasks: cachedTasks.count, fromCache: true)
            handleTasksResult(.success(cachedTasks), listViewController: listViewController, date: date, token: token)
            return
        }

        snapshotStore.snapshot(for: date) { [weak self, weak listViewController] result in
            let anyResult = result.map { snapshot in
                snapshot.tasks.map { $0 as OCKAnyTask }
            }
            self?.handleTasksResult(anyResult, listViewController: listViewController, date: date, token: token)
        }
    }

    func reportSelectedDateIfVisible(_ date: Date) {
        guard !isApplyingInitialDate else { return }
        guard calendar.isDate(selectedDate, inSameDayAs: date) else { return }
        onSelectedDateChange?(date)
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveScheduleRefreshNotification), name: .scheduleRefreshRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteProfileEventNotification), name: .deleteUserAccount, object: nil)
    }

    @objc private func didReceiveScheduleRefreshNotification(_ notification: Notification) {
        let context = ScheduleRefreshContext(notification: notification) ?? ScheduleRefreshContext(changeKind: .fullResync)
        reloadWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.applyScheduleRefresh(context)
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

            SyncPerformanceTracker.shared.recordScheduleLoad(date: date, fetchedTasks: todayTasks.count, fromCache: false)
            prefetchAdjacentDays(around: date)
            
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

    private func applyScheduleRefresh(_ context: ScheduleRefreshContext) {
        isFirstLoad = false
        let visibleDay = normalizedDate(for: selectedDate)
        let snapshotStore = CareKitStoreManager.shared.daySnapshotStore
        let affectsVisibleDate = context.affects(date: selectedDate, calendar: calendar)
        let hasCachedVisibleSnapshot = snapshotStore.cachedSnapshot(for: selectedDate) != nil
        let preserveVisibleDay = affectsVisibleDate && hasCachedVisibleSnapshot
        snapshotStore.invalidate(using: context, preserving: preserveVisibleDay ? [visibleDay] : [])
        refreshAffectedCalendarRings(using: context)

        guard context.changeKind == .fullResync || affectsVisibleDate else {
            return
        }

        if context.changeKind == .outcomeOnly, preserveVisibleDay {
            return
        }

        if preserveVisibleDay {
            snapshotStore.snapshot(for: selectedDate, forceRefresh: true) { [weak self] _ in
                guard let self else { return }
                SyncPerformanceTracker.shared.increment("schedule.reloads")
                self.reload()
            }
            return
        }

        SyncPerformanceTracker.shared.increment("schedule.reloads")
        reload()
    }

    private func refreshAffectedCalendarRings(using context: ScheduleRefreshContext) {
        guard context.changeKind == .outcomeOnly else { return }

        let visibleCalendarControllers = childViewControllers(ofType: OCKWeekCalendarViewController.self)
        let visibleCalendarViews = view.descendants(ofType: OCKWeekCalendarView.self)
        guard !visibleCalendarControllers.isEmpty || !visibleCalendarViews.isEmpty else { return }

        let snapshotStore = CareKitStoreManager.shared.daySnapshotStore
        let affectedDates = context.affectedDates.map(normalizedDate(for:))
        affectedDates.forEach { affectedDate in
            let visibleControllersForDate = visibleCalendarControllers.filter {
                $0.calendarView.dateInterval.contains(affectedDate)
            }
            let visibleViewsForDate = visibleCalendarViews.filter {
                $0.dateInterval.contains(affectedDate) && $0.completionRingFor(date: affectedDate) != nil
            }
            guard !visibleControllersForDate.isEmpty || !visibleViewsForDate.isEmpty else { return }

            snapshotStore.summary(for: affectedDate, forceRefresh: true) { [weak self] result in
                guard let self,
                      case .success(let snapshot) = result else {
                    return
                }

                let state = self.completionState(for: snapshot, date: affectedDate)
                visibleControllersForDate.forEach {
                    self.updateCalendarController($0, state: state, for: affectedDate)
                }
                visibleViewsForDate.forEach { calendarView in
                    calendarView.completionRingFor(date: affectedDate)?.setState(state, animated: true)
                }
            }
        }
    }

    private func updateCalendarController(
        _ calendarController: OCKWeekCalendarViewController,
        state: OCKCompletionState,
        for date: Date
    ) {
        let dayOffset = calendar.dateComponents([.day], from: calendarController.calendarView.dateInterval.start, to: date).day
        guard let dayOffset,
              dayOffset >= 0,
              dayOffset < calendarController.calendarView.completionRingButtons.count else {
            return
        }

        var states = calendarController.controller.completionStates
        if states.count == calendarController.calendarView.completionRingButtons.count {
            states[dayOffset] = state
            calendarController.controller.completionStates = states
        } else {
            calendarController.calendarView.completionRingButtons[dayOffset].setState(state, animated: true)
        }
    }

    private func completionState(for snapshot: DaySummarySnapshot, date: Date) -> OCKCompletionState {
        let totals = CheckUpTaskType.allCases.reduce(into: (total: 0, completed: 0)) { result, category in
            let summary = snapshot.summary(for: category)
            result.total += summary.totalTasks
            result.completed += summary.completedTasks
        }

        guard totals.total > 0 else {
            return .dimmed
        }

        guard totals.completed > 0 else {
            return date > Date() && !calendar.isDateInToday(date) ? .empty : .zero
        }

        return .progress(CGFloat(totals.completed) / CGFloat(totals.total))
    }

    private func prefetchAdjacentDays(around date: Date) {
        CareKitStoreManager.shared.daySnapshotStore.prefetchAdjacentDays(around: date)
    }

    private func normalizedDate(for date: Date) -> Date {
        calendar.startOfDay(for: date)
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

        if let descriptor = task.viewType.sensorTaskDescriptor {
            return SensorTaskViewController(
                task: task,
                eventQuery: eventQuery,
                storeManager: storeManager,
                selectedDate: date,
                metric: descriptor.metric,
                mode: descriptor.mode
            )
        }

        switch task.viewType {
        case .simple:
            return SyncingSimpleTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .instruction:
            return SyncingInstructionsTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .buttonLog:
            return SyncingButtonLogTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .grid:
            return SyncingGridTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
        case .checklist:
            return SyncingChecklistTaskViewController(task: task, eventQuery: eventQuery, storeManager: storeManager)
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
        case .heartRate, .bloodGlucose, .bloodPressure, .ecg,
             .respiratoryRate, .restingHeartRate, .oxygenSaturation, .vo2Max,
             .manualHeartRate, .manualBloodGlucose, .manualBloodPressure, .manualECG,
             .manualRespiratoryRate, .manualRestingHeartRate, .manualOxygenSaturation, .manualVO2Max:
            preconditionFailure("Sensor task type must provide a descriptor")
        }
    }
}

private extension UIViewController {
    func childViewControllers<ViewControllerType: UIViewController>(
        ofType type: ViewControllerType.Type
    ) -> [ViewControllerType] {
        children.flatMap { child -> [ViewControllerType] in
            var matches = child.childViewControllers(ofType: type)
            if let typedChild = child as? ViewControllerType {
                matches.insert(typedChild, at: 0)
            }
            return matches
        }
    }
}

private extension UIView {
    func descendants<ViewType: UIView>(ofType type: ViewType.Type) -> [ViewType] {
        subviews.flatMap { subview -> [ViewType] in
            var matches = subview.descendants(ofType: type)
            if let typedSubview = subview as? ViewType {
                matches.insert(typedSubview, at: 0)
            }
            return matches
        }
    }
}
