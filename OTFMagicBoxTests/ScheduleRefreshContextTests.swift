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

import Foundation
import Testing
import OTFCareKit
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("Schedule refresh context", .serialized)
struct ScheduleRefreshContextTests {
    @Test("Schedule controller starts on the bound date without reporting today")
    @MainActor
    func scheduleControllerStartsOnBoundDateWithoutReportingToday() throws {
        let store = OCKStore(
            name: "ScheduleInitialDateTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let initialDate = try #require(Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: Date()
        ))
        let controller = ScheduleViewController(
            storeManager: OCKSynchronizedStoreManager(wrapping: store),
            initialDate: initialDate
        )
        var reportedDates: [Date] = []
        controller.onSelectedDateChange = { reportedDates.append($0) }

        controller.loadViewIfNeeded()

        #expect(Calendar.current.isDate(controller.selectedDate, inSameDayAs: initialDate))
        #expect(reportedDates.isEmpty)
    }

    @Test("Unrelated SwiftUI updates do not reapply an unchanged bound date")
    @MainActor
    func unrelatedSwiftUIUpdatesDoNotReapplyUnchangedBoundDate() throws {
        let today = Date()
        let selectedDate = try #require(Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: today
        ))
        let coordinator = ScheduleViewRepresentable.Coordinator(selectedDate: today)

        #expect(!coordinator.shouldApplyBoundDate(today))

        coordinator.controllerSelectedDate(selectedDate)
        #expect(!coordinator.shouldApplyBoundDate(selectedDate))
        #expect(coordinator.shouldApplyBoundDate(today))
    }

    @Test("Visible CareKit dates synchronize back to the Schedule binding")
    @MainActor
    func visibleCareKitDatesSynchronizeBackToScheduleBinding() throws {
        let store = OCKStore(
            name: "ScheduleSelectedDateTests-\(UUID().uuidString)",
            type: .inMemory
        )
        let controller = ScheduleViewController(
            storeManager: OCKSynchronizedStoreManager(wrapping: store)
        )
        controller.loadViewIfNeeded()

        let selectedDate = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: Date()
        ) ?? Date()
        controller.selectDate(selectedDate, animated: false)

        var reportedDate: Date?
        controller.onSelectedDateChange = { reportedDate = $0 }

        controller.reportSelectedDateIfVisible(selectedDate)

        #expect(Calendar.current.isDate(
            try #require(reportedDate),
            inSameDayAs: selectedDate
        ))

        reportedDate = nil
        let adjacentDate = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: selectedDate
        ) ?? selectedDate
        controller.reportSelectedDateIfVisible(adjacentDate)
        #expect(reportedDate == nil)
    }

    @Test("Outcome Creates Targeted Schedule Refresh Context")
    func outcomeCreatesTargetedScheduleRefreshContext() {
        let effectiveDate = Date(timeIntervalSince1970: 1_800_100_000)
        var outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )
        outcome.effectiveDate = effectiveDate

        let context = CareKitStoreManager.shared.scheduleRefreshContext(for: outcome)

        #expect(context.changeKind == .outcomeOnly)
        #expect(context.affectedDates.map { Calendar.current.startOfDay(for: $0) } == [Calendar.current.startOfDay(for: effectiveDate)])
    }

    @Test("Schedule Refresh Context Round Trips Outcome Only Notification")
    func scheduleRefreshContextRoundTripsOutcomeOnlyNotification() {
        let affectedDate = Date(timeIntervalSince1970: 1_800_200_000)
        let originalContext = ScheduleRefreshContext(
            changeKind: .outcomeOnly,
            affectedDates: [affectedDate]
        )
        let notification = Notification(
            name: .scheduleRefreshRequested,
            object: nil,
            userInfo: originalContext.notificationUserInfo
        )

        let decodedContext = ScheduleRefreshContext(notification: notification)

        #expect(decodedContext?.changeKind == .outcomeOnly)
        #expect(decodedContext?.affectedDates == originalContext.affectedDates)
    }

    @Test("Watch Outcome Payload Creates Targeted Schedule Refresh Context")
    func watchOutcomePayloadCreatesTargetedScheduleRefreshContext() throws {
        let effectiveDate = Date(timeIntervalSince1970: 1_800_300_000)
        var outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )
        outcome.effectiveDate = effectiveDate
        let payload = OTFWatchSyncPayload(outcomes: [try JSONEncoder().encode(outcome)])

        let context = try #require(WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(outcomes: 1),
            payload: payload
        ))

        #expect(context.changeKind == .outcomeOnly)
        #expect(!(context.invalidatesAllDates))
        #expect(context.affectedDates == [Calendar.current.startOfDay(for: effectiveDate)])
    }

    @Test("Watch Deletion Payload Falls Back To Full Resync When Deleted Date Is Unknown")
    func watchDeletionPayloadFallsBackToFullResyncWhenDeletedDateIsUnknown() throws {
        let payload = OTFWatchSyncPayload(deletedDocumentIDs: ["deleted-outcome"])

        let context = try #require(WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(deletions: 1),
            payload: payload
        ))

        #expect(context.changeKind == .fullResync)
        #expect(context.invalidatesAllDates)
    }

    @Test("Typed Watch Outcome Deletion Payload Creates Targeted Schedule Refresh Context")
    func typedWatchOutcomeDeletionPayloadCreatesTargetedScheduleRefreshContext() throws {
        let taskUUID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let payload = OTFWatchSyncPayload(deletions: [
            OTFWatchSyncDeletion(
                documentID: "\(taskUUID.uuidString)_0",
                entityType: .outcome,
                taskUUID: taskUUID,
                occurrenceIndex: 0
            )
        ])
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var task = makeTask(id: "task", start: start, end: nil)
        task.uuid = taskUUID
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))

        let context = try #require(WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(deletions: 1),
            payload: payload,
            store: store
        ))

        #expect(context.changeKind == .outcomeOnly)
        #expect(!(context.invalidatesAllDates))
    }

    @Test("Phone Session Rejects Watch Payload When Store Is Not Ready")
    func phoneSessionRejectsWatchPayloadWhenStoreIsNotReady() {
        let originalReadiness = CareKitStoreManager.shared.isWatchSyncReadyForTesting()
        CareKitStoreManager.shared.setWatchSyncReadyForTesting(false)
        defer { CareKitStoreManager.shared.setWatchSyncReadyForTesting(originalReadiness) }

        let sessionManager = SessionManager()
        let payload = OTFWatchSyncPayload(deletions: [
            OTFWatchSyncDeletion(documentID: "task-1", entityType: .task)
        ])
        var reply: [String: Any]?

        sessionManager.handleIncomingMessageForTesting(
            [OTFWatchConnectivityMessageKey.incrementalRevisionPush: payload.message],
            replyHandler: { reply = $0 }
        )

        #expect((reply?[OTFWatchConnectivityMessageKey.revisionError]) != nil)
    }

    @Test("Schedule refresh context normalizes affected dates")
    func scheduleRefreshContextNormalizesAffectedDates() {
        let morning = Date(timeIntervalSince1970: 1_800_200_000)
        let laterSameDay = morning.addingTimeInterval(60 * 60)
        let nextDay = morning.addingTimeInterval(24 * 60 * 60)

        let context = ScheduleRefreshContext(
            changeKind: .outcomeOnly,
            affectedDates: [laterSameDay, nextDay, morning]
        )

        #expect(context.affectedDates.count == 2)
        #expect(context.affectedDates == context.affectedDates.sorted())
        #expect(context.affects(date: laterSameDay))
        #expect(!context.invalidatesAllDates)
    }

    @Test("Schedule refresh context invalidates all dates for empty targeted context")
    func scheduleRefreshContextInvalidatesAllDatesForEmptyTargetedContext() {
        let context = ScheduleRefreshContext(changeKind: .outcomeOnly)

        #expect(context.invalidatesAllDates)
        #expect(context.affects(date: Date(timeIntervalSince1970: 1_800_200_000)))
    }

    @Test("Invalid schedule refresh notification is ignored")
    func invalidScheduleRefreshNotificationIsIgnored() {
        let notification = Notification(
            name: .scheduleRefreshRequested,
            object: nil,
            userInfo: ["schedule.refresh.kind": "unsupported"]
        )

        #expect(ScheduleRefreshContext(notification: notification) == nil)
    }

    @Test("Watch task changes prefer task membership refresh")
    func watchTaskChangesPreferTaskMembershipRefresh() throws {
        let effectiveDate = Date(timeIntervalSince1970: 1_800_300_000)
        var outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(true)]
        )
        outcome.effectiveDate = effectiveDate
        let payload = OTFWatchSyncPayload(outcomes: [try JSONEncoder().encode(outcome)])

        let context = try #require(WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(tasks: 1, outcomes: 1),
            payload: payload
        ))

        #expect(context.changeKind == .taskMembership)
        #expect(context.invalidatesAllDates)
    }

    @Test("Malformed watch outcome payload falls back to full resync")
    func malformedWatchOutcomePayloadFallsBackToFullResync() throws {
        let payload = OTFWatchSyncPayload(outcomes: [Data("not-json".utf8)])

        let context = try #require(WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(outcomes: 1),
            payload: payload
        ))

        #expect(context.changeKind == .fullResync)
        #expect(context.invalidatesAllDates)
    }

    @Test("Watch payload with no applied changes does not request schedule refresh")
    func watchPayloadWithNoAppliedChangesDoesNotRequestScheduleRefresh() {
        let payload = OTFWatchSyncPayload()

        let context = WatchSyncScheduleRefreshContextResolver.context(
            for: OTFIncrementalSyncApplyResult(),
            payload: payload
        )

        #expect(context == nil)
    }
}
