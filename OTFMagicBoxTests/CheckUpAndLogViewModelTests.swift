/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import Foundation
import OSLog
import OTFCareKitStore
import OTFTemplateBox
import Testing
@testable import OTFMagicBox

@Suite("CheckUp view model")
struct CheckUpViewModelTests {
    @Test("Fetch tasks applies category summaries from injected snapshot store")
    func fetchTasksAppliesCategorySummaries() throws {
        let day = try fixedCheckUpDate(day: 3)
        var requestedDate: Date?
        var requestedForceRefresh: Bool?
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { day },
            summaryFetcher: { date, forceRefresh, completion in
                requestedDate = date
                requestedForceRefresh = forceRefresh
                completion(.success(checkUpSnapshot(date: date)))
            },
            snapshotInvalidator: { _ in },
            refreshScheduler: { _, _ in }
        )

        model.fetchTasks()

        #expect(requestedDate == fixedCheckUpCalendar.startOfDay(for: day))
        #expect(requestedForceRefresh == false)
        #expect(model.medicationSummary.completedTasks == 1)
        #expect(model.medicationSummary.totalTasks == 2)
        #expect(model.activitySummary.completedTasks == 3)
        #expect(model.appointmentSummary == .zero)
    }

    @Test("Fetch failure resets summaries to zero")
    func fetchFailureResetsSummariesToZero() throws {
        let day = try fixedCheckUpDate(day: 3)
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { day },
            summaryFetcher: { _, _, completion in
                completion(.success(checkUpSnapshot(date: day)))
            },
            snapshotInvalidator: { _ in },
            refreshScheduler: { _, _ in }
        )
        model.fetchTasks()

        let failingModel = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { day },
            summaryFetcher: { _, _, completion in
                completion(.failure(.fetchFailed(reason: "offline")))
            },
            snapshotInvalidator: { _ in },
            refreshScheduler: { _, _ in }
        )

        failingModel.fetchTasks()

        #expect(failingModel.medicationSummary == .zero)
        #expect(failingModel.activitySummary == .zero)
    }

    @Test("Targeted refresh ignores dates outside today")
    func targetedRefreshIgnoresDatesOutsideToday() throws {
        let today = try fixedCheckUpDate(day: 3)
        let futureDate = try #require(fixedCheckUpCalendar.date(byAdding: .day, value: 2, to: today))
        var invalidatedContexts = [ScheduleRefreshContext]()
        var scheduledDelays = [TimeInterval]()
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { today },
            summaryFetcher: { _, _, completion in completion(.success(checkUpSnapshot(date: today))) },
            snapshotInvalidator: { invalidatedContexts.append($0) },
            refreshScheduler: { delay, _ in scheduledDelays.append(delay) }
        )
        let context = ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [futureDate])

        model.scheduleRefresh(using: Notification(name: .scheduleRefreshRequested, userInfo: context.notificationUserInfo))

        #expect(invalidatedContexts.isEmpty)
        #expect(scheduledDelays.isEmpty)
    }

    @Test("Full refresh invalidates and schedules forced summary fetch")
    func fullRefreshInvalidatesAndSchedulesForcedSummaryFetch() throws {
        let today = try fixedCheckUpDate(day: 3)
        var invalidatedContext: ScheduleRefreshContext?
        var scheduledWorkItem: DispatchWorkItem?
        var forceRefreshValues = [Bool]()
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: .current,
            now: { today },
            summaryFetcher: { _, forceRefresh, completion in
                forceRefreshValues.append(forceRefresh)
                completion(.success(checkUpSnapshot(date: today)))
            },
            snapshotInvalidator: { invalidatedContext = $0 },
            refreshScheduler: { _, workItem in scheduledWorkItem = workItem }
        )
        let context = ScheduleRefreshContext(changeKind: .fullResync)

        model.scheduleRefresh(using: Notification(name: .scheduleRefreshRequested, userInfo: context.notificationUserInfo))
        scheduledWorkItem?.perform()

        #expect(invalidatedContext?.changeKind == .fullResync)
        #expect(forceRefreshValues == [true])
    }

    @Test("Targeted refresh for today invalidates and schedules forced summary fetch")
    func targetedRefreshForTodayInvalidatesAndSchedulesForcedSummaryFetch() throws {
        let calendar = Calendar.current
        let today = try #require(calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 3,
            hour: 8
        )))
        var invalidatedContext: ScheduleRefreshContext?
        var scheduledWorkItem: DispatchWorkItem?
        var forceRefreshValues = [Bool]()
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: calendar,
            now: { today },
            summaryFetcher: { _, forceRefresh, completion in
                forceRefreshValues.append(forceRefresh)
                completion(.success(checkUpSnapshot(date: today)))
            },
            snapshotInvalidator: { invalidatedContext = $0 },
            refreshScheduler: { _, workItem in scheduledWorkItem = workItem }
        )
        let context = ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [today])

        model.scheduleRefresh(using: Notification(name: .scheduleRefreshRequested, userInfo: context.notificationUserInfo))
        scheduledWorkItem?.perform()

        #expect(invalidatedContext?.changeKind == .outcomeOnly)
        #expect(forceRefreshValues == [true])
        #expect(model.checkupSummary.completedTasks == 0)
    }

    @Test("Invalid refresh notification falls back to full resync")
    func invalidRefreshNotificationFallsBackToFullResync() throws {
        let today = try fixedCheckUpDate(day: 3)
        var invalidatedContext: ScheduleRefreshContext?
        var scheduledWorkItem: DispatchWorkItem?
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { today },
            summaryFetcher: { _, _, completion in completion(.success(checkUpSnapshot(date: today))) },
            snapshotInvalidator: { invalidatedContext = $0 },
            refreshScheduler: { _, workItem in scheduledWorkItem = workItem }
        )

        model.scheduleRefresh(using: Notification(
            name: .scheduleRefreshRequested,
            userInfo: ["schedule.refresh.kind": "unknown"]
        ))

        #expect(invalidatedContext?.changeKind == .fullResync)
        #expect(scheduledWorkItem != nil)
    }

    @Test("Repeated refresh cancels previous scheduled work")
    func repeatedRefreshCancelsPreviousScheduledWork() throws {
        let today = try fixedCheckUpDate(day: 3)
        var scheduledWorkItems = [DispatchWorkItem]()
        var forceRefreshValues = [Bool]()
        let model = CheckUpViewModel(
            decoder: CheckUpFakeYAMLDecoder(),
            calendar: fixedCheckUpCalendar,
            now: { today },
            summaryFetcher: { _, forceRefresh, completion in
                forceRefreshValues.append(forceRefresh)
                completion(.success(checkUpSnapshot(date: today)))
            },
            snapshotInvalidator: { _ in },
            refreshScheduler: { _, workItem in scheduledWorkItems.append(workItem) }
        )

        model.scheduleRefresh()
        model.scheduleRefresh()
        scheduledWorkItems.first?.perform()
        scheduledWorkItems.last?.perform()

        #expect(scheduledWorkItems.count == 2)
        #expect(forceRefreshValues == [true])
    }
}

@Suite("Log view model")
@MainActor
struct LogViewModelTests {
    @Test("Loads decoded config and derives initial date range from fallback days back")
    func loadsDecodedConfigAndDerivesInitialDateRange() throws {
        let now = try fixedCheckUpDate(day: 6, hour: 14)
        let config = makeLogConfiguration(
            navTitle: "Device Logs",
            rowsMaxLines: 7,
            defaultDaysBack: 3
        )
        let decoder = LogFakeYAMLDecoder(config: config)

        let model = LogViewModel(
            decoder: decoder,
            logReaderFactory: { FakeLogReader(entries: []) },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: { now },
            autoRefresh: false
        )

        #expect(decoder.decodedFiles == ["LogConfiguration"])
        #expect(model.config.navTitle.localized == "Device Logs")
        #expect(model.config.rowsMaxLines == 7)
        #expect(abs(model.endDate.timeIntervalSince(now)) < 0.001)
        #expect(
            abs(model.startDate.timeIntervalSince(
                now.addingTimeInterval(-TimeInterval(LogConfiguration.fallback.defaultDaysBack) * 86400)
            )) < 0.001
        )
    }

    @Test("Falls back to default config after decoder failure")
    func fallsBackToDefaultConfigAfterDecoderFailure() {
        let decoder = LogFakeYAMLDecoder(error: CheckUpFakeDecoderError.missingStub)

        let model = LogViewModel(
            decoder: decoder,
            logReaderFactory: { FakeLogReader(entries: []) },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: Date.init,
            autoRefresh: false
        )

        #expect(decoder.decodedFiles == ["LogConfiguration"])
        #expect(model.config.navTitle.localized == LogConfiguration.fallback.navTitle.localized)
        #expect(model.config.defaultDaysBack == LogConfiguration.fallback.defaultDaysBack)
    }

    @Test("Refresh filters entries through injected log reader and exports filtered logs")
    func refreshFiltersAndExportsLogs() async throws {
        let now = try fixedCheckUpDate(day: 4, hour: 12)
        let matching = SampleLog(
            date: now.addingTimeInterval(-60),
            level: .error,
            category: "Sync",
            subsystem: "com.hippocrates.sync",
            composedMessage: "Cloudant retry failed"
        )
        let ignored = SampleLog(
            date: now.addingTimeInterval(-120),
            level: .info,
            category: "Profile",
            subsystem: "com.hippocrates.profile",
            composedMessage: "Profile loaded"
        )
        let writer = FakeDiagnosticsWriter()
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: {
                FakeLogReader(entries: [matching, ignored])
            },
            diagnosticsWriter: writer,
            now: { now },
            autoRefresh: false
        )
        model.level = .error
        model.search = "retry"

        model.refresh()

        try await waitUntil { !model.isLoading && model.shareURL != nil }
        #expect(model.entries.map(\.composedMessage) == ["Cloudant retry failed"])
        #expect(model.filteredEntries.map(\.category) == ["Sync"])
        #expect(writer.exportedMessages == ["Cloudant retry failed"])
    }

    @Test("Refresh passes selected date range and level to log reader")
    func refreshPassesSelectedDateRangeAndLevelToLogReader() async throws {
        let now = try fixedCheckUpDate(day: 4, hour: 12)
        let start = now.addingTimeInterval(-3600)
        let end = now.addingTimeInterval(60)
        let reader = RecordingLogReader(entries: [])
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: { reader },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: { now },
            autoRefresh: false
        )
        model.startDate = start
        model.endDate = end
        model.level = .error

        model.refresh()

        try await waitUntil { !model.isLoading && reader.requests.count == 1 }
        #expect(reader.requests.first?.startDate == start)
        #expect(reader.requests.first?.endDate == end)
        #expect(reader.requests.first?.level == .error)
    }

    @Test("Reader failure clears entries and exposes alert")
    func readerFailureClearsEntriesAndExposesAlert() async throws {
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: {
                ThrowingLogReader()
            },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: Date.init,
            autoRefresh: false
        )

        model.refresh()

        try await waitUntil { !model.isLoading && model.showAlert }
        #expect(model.entries.isEmpty)
        #expect(model.alertMessage == "log read failed")
    }

    @Test("Log reader configuration failure exposes alert without loading")
    func logReaderConfigurationFailureExposesAlertWithoutLoading() {
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: {
                throw NSError(domain: "LogTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "store unavailable"])
            },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: Date.init,
            autoRefresh: true
        )

        #expect(model.showAlert)
        #expect(model.alertMessage == "store unavailable")
        #expect(!model.isLoading)
        #expect(model.entries.isEmpty)
    }

    @Test("Search matches message category and subsystem case insensitively")
    func searchMatchesMessageCategoryAndSubsystemCaseInsensitively() async throws {
        let now = try fixedCheckUpDate(day: 4, hour: 12)
        let entries = [
            SampleLog(
                date: now.addingTimeInterval(-60),
                level: .error,
                category: "Sync",
                subsystem: "com.hippocrates.sync",
                composedMessage: "Cloudant retry failed"
            ),
            SampleLog(
                date: now.addingTimeInterval(-120),
                level: .info,
                category: "Profile",
                subsystem: "com.hippocrates.account",
                composedMessage: "Loaded user"
            ),
            SampleLog(
                date: now.addingTimeInterval(-180),
                level: .debug,
                category: "Health",
                subsystem: "com.hippocrates.vitals",
                composedMessage: "Fresh sample"
            )
        ]
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: { FakeLogReader(entries: entries) },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: { now },
            autoRefresh: false
        )

        model.refresh()
        try await waitUntil { !model.isLoading && model.entries.count == 3 }

        model.search = "PROFILE"
        #expect(model.filteredEntries.map(\.composedMessage) == ["Loaded user"])

        model.search = "VITALS"
        #expect(model.filteredEntries.map(\.category) == ["Health"])

        model.search = "retry"
        #expect(model.filteredEntries.map(\.category) == ["Sync"])
    }

    @Test("Whitespace only search returns all log entries")
    func whitespaceOnlySearchReturnsAllLogEntries() async throws {
        let now = try fixedCheckUpDate(day: 4, hour: 12)
        let entries = [
            SampleLog(
                date: now.addingTimeInterval(-60),
                level: .error,
                category: "Sync",
                subsystem: "com.hippocrates.sync",
                composedMessage: "Cloudant retry failed"
            ),
            SampleLog(
                date: now.addingTimeInterval(-120),
                level: .info,
                category: "Profile",
                subsystem: "com.hippocrates.profile",
                composedMessage: "Profile loaded"
            )
        ]
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: {
                FakeLogReader(entries: entries)
            },
            diagnosticsWriter: FakeDiagnosticsWriter(),
            now: { now },
            autoRefresh: false
        )

        model.refresh()
        try await waitUntil { !model.isLoading && model.entries.count == 2 }
        model.search = "   "

        #expect(model.filteredEntries.map(\.composedMessage) == [
            "Cloudant retry failed",
            "Profile loaded"
        ])
    }

    @Test("Diagnostics writer failure keeps entries and exposes alert")
    func diagnosticsWriterFailureKeepsEntriesAndExposesAlert() async throws {
        let now = try fixedCheckUpDate(day: 4, hour: 12)
        let entry = SampleLog(
            date: now.addingTimeInterval(-60),
            level: .error,
            category: "Sync",
            subsystem: "com.hippocrates.sync",
            composedMessage: "Cloudant retry failed"
        )
        let model = LogViewModel(
            decoder: LogFakeYAMLDecoder(),
            logReaderFactory: {
                FakeLogReader(entries: [entry])
            },
            diagnosticsWriter: FakeDiagnosticsWriter(error: NSError(
                domain: "LogTests",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "export failed"]
            )),
            now: { now },
            autoRefresh: false
        )

        model.refresh()

        try await waitUntil { !model.isLoading && model.showAlert }
        #expect(model.entries.map(\.composedMessage) == ["Cloudant retry failed"])
        #expect(model.shareURL == nil)
        #expect(model.alertMessage == "export failed")
    }
}

private struct CheckUpFakeYAMLDecoder: OTFYAMLDecoding {
    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        guard file == "CheckUpConfiguration",
              let config = CheckUpConfiguration.fallback as? T
        else {
            throw CheckUpFakeDecoderError.missingStub
        }
        return config
    }
}

private final class LogFakeYAMLDecoder: OTFYAMLDecoding {
    private let config: LogConfiguration
    private let error: Error?
    private(set) var decodedFiles: [String] = []

    init(config: LogConfiguration = .fallback, error: Error? = nil) {
        self.config = config
        self.error = error
    }

    func decode<T>(_ file: String, as type: T.Type) throws -> T where T: OTFVersionedDecodable {
        decodedFiles.append(file)
        if let error {
            throw error
        }
        guard file == "LogConfiguration",
              let config = config as? T
        else {
            throw CheckUpFakeDecoderError.missingStub
        }
        return config
    }
}

private enum CheckUpFakeDecoderError: Error {
    case missingStub
}

private struct FakeLogReader: LogEntryReading {
    let entries: [OSLogEntryLog]

    func entries(startDate: Date, endDate: Date, level: OSLogEntryLog.Level) throws -> [OSLogEntryLog] {
        entries.filter { entry in
            guard entry.date >= startDate, entry.date <= endDate else { return false }
            return level == .undefined || entry.level == level
        }
    }
}

private final class RecordingLogReader: LogEntryReading {
    struct Request: Equatable {
        let startDate: Date
        let endDate: Date
        let level: OSLogEntryLog.Level
    }

    private(set) var requests: [Request] = []
    private let entries: [OSLogEntryLog]

    init(entries: [OSLogEntryLog]) {
        self.entries = entries
    }

    func entries(startDate: Date, endDate: Date, level: OSLogEntryLog.Level) throws -> [OSLogEntryLog] {
        requests.append(Request(startDate: startDate, endDate: endDate, level: level))
        return entries
    }
}

private struct ThrowingLogReader: LogEntryReading {
    func entries(startDate: Date, endDate: Date, level: OSLogEntryLog.Level) throws -> [OSLogEntryLog] {
        throw NSError(domain: "LogTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "log read failed"])
    }
}

private final class FakeDiagnosticsWriter: DiagnosticsLogWriting {
    private(set) var exportedMessages = [String]()
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func write(entries: [OSLogEntryLog]) throws -> URL {
        if let error {
            throw error
        }
        exportedMessages = entries.map(\.composedMessage)
        return URL(fileURLWithPath: "/tmp/fake-diagnostics.log")
    }
}

private let fixedCheckUpCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}()

private func fixedCheckUpDate(day: Int, hour: Int = 8) throws -> Date {
    let components = DateComponents(
        calendar: fixedCheckUpCalendar,
        timeZone: fixedCheckUpCalendar.timeZone,
        year: 2026,
        month: 6,
        day: day,
        hour: hour
    )
    return try #require(fixedCheckUpCalendar.date(from: components))
}

private func checkUpSnapshot(date: Date) -> DaySummarySnapshot {
    DaySummarySnapshot(
        date: date,
        summaries: [
            .medication: CategorySummary(totalTasks: 2, completedTasks: 1),
            .activity: CategorySummary(totalTasks: 3, completedTasks: 3),
            .checkup: CategorySummary(totalTasks: 1, completedTasks: 0),
            .appointment: .zero
        ]
    )
}

private func makeLogConfiguration(
    navTitle: String = "Logs",
    rowsMaxLines: Int = LogConfiguration.fallback.rowsMaxLines,
    defaultDaysBack: Int = LogConfiguration.fallback.defaultDaysBack
) -> LogConfiguration {
    let fallback = LogConfiguration.fallback
    return LogConfiguration(
        version: "1.1.0",
        featureTitle: fallback.featureTitle,
        navTitle: OTFStringLocalized(navTitle),
        emptyTitle: fallback.emptyTitle,
        emptySubtitle: fallback.emptySubtitle,
        filterLabel: fallback.filterLabel,
        startLabel: fallback.startLabel,
        endLabel: fallback.endLabel,
        levelLabel: fallback.levelLabel,
        detailTitle: fallback.detailTitle,
        dateLabel: fallback.dateLabel,
        categoryLabel: fallback.categoryLabel,
        subsystemLabel: fallback.subsystemLabel,
        searchPlaceholder: fallback.searchPlaceholder,
        refreshTitle: fallback.refreshTitle,
        exportTitle: fallback.exportTitle,
        copyTitle: fallback.copyTitle,
        rowsMaxLines: rowsMaxLines,
        defaultDaysBack: defaultDaysBack
    )
}
