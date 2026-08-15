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
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("Changes tracker")
struct ChangesTrackerTests {
    @Test("Changes Tracker Schedules Retry After Timeout Error")
    func changesTrackerSchedulesRetryAfterTimeoutError() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        var requestCompletion: ((Data?, Error?) -> Void)?
        var scheduledDelay: TimeInterval?
        var scheduledWork: (() -> Void)?
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startRequest: { _, completion in
                requestCompletion = completion
            },
            scheduleAfter: { delay, work in
                scheduledDelay = delay
                scheduledWork = work
            }
        )

        tracker.start()
        requestCompletion?(nil, URLError(.timedOut))

        #expect(scheduledDelay == 5)
        #expect((scheduledWork) != nil)
    }

    @Test("Changes Tracker Stop Prevents Scheduled Retry From Starting Another Request")
    func changesTrackerStopPreventsScheduledRetryFromStartingAnotherRequest() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        var requestStartCount = 0
        var requestCompletion: ((Data?, Error?) -> Void)?
        var scheduledWork: (() -> Void)?
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startRequest: { _, completion in
                requestStartCount += 1
                requestCompletion = completion
            },
            scheduleAfter: { _, work in
                scheduledWork = work
            }
        )

        tracker.start()
        requestCompletion?(nil, URLError(.timedOut))
        tracker.stop()
        scheduledWork?()

        #expect(requestStartCount == 1)
    }

    @Test("Changes Tracker Builds Long Poll Request From Now With Heartbeat")
    func changesTrackerBuildsLongPollRequestFromNowWithHeartbeat() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        var capturedRequest: URLRequest?
        let tracker = ChangesTracker(
            datastore: storeFixture.store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startRequest: { request, _ in
                capturedRequest = request
            }
        )

        tracker.start()

        let requestURL = try #require(capturedRequest?.url)
        let queryItems = queryItemsByName(for: requestURL)
        #expect(requestURL.path == "/db/_changes")
        #expect(queryItems["style"] == "all_docs")
        #expect(queryItems["since"] == "now")
        #expect(queryItems["feed"] == "longpoll")
        #expect(queryItems["heartbeat"] == "30000")
    }

    @Test("Changes Tracker Stop Ignores Late Response Without Scheduling Retry")
    func changesTrackerStopIgnoresLateResponseWithoutSchedulingRetry() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        var requestCompletion: ((Data?, Error?) -> Void)?
        var scheduledDelay: TimeInterval?
        let tracker = ChangesTracker(
            datastore: storeFixture.store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startRequest: { _, completion in
                requestCompletion = completion
            },
            scheduleAfter: { delay, _ in
                scheduledDelay = delay
            }
        )

        tracker.start()
        tracker.stop()
        requestCompletion?(nil, URLError(.timedOut))

        #expect(scheduledDelay == nil)
    }

    @Test("Changes Tracker Does Not Report Deleted Document That Is Already Missing Locally")
    func changesTrackerDoesNotReportDeletedDocumentThatIsAlreadyMissingLocally() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store

        var receivedDeletedDocumentIDs = [[String]]()
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { _, deletedDocumentIDs, _ in
                receivedDeletedDocumentIDs.append(deletedDocumentIDs)
            }
        )

        tracker.processChangesForTesting(try changesFeedData(
            deletedDocumentID: "already-deleted",
            revID: "2-deleted"
        ))

        #expect(receivedDeletedDocumentIDs.isEmpty)
    }

    @Test("Changes Tracker Ignores Malformed Payload Without Reporting Changes")
    func changesTrackerIgnoresMalformedPayloadWithoutReportingChanges() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        var handlerCallCount = 0
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { _, _, _ in
                handlerCallCount += 1
            }
        )

        let hadActivity = tracker.processChangesForTesting(Data(#"{"last_seq":"1","results":"bad"}"#.utf8))

        #expect(!hadActivity)
        #expect(handlerCallCount == 0)
    }

    @Test("Changes Tracker Reports Missing Local Changed Document For Pull")
    func changesTrackerReportsMissingLocalChangedDocumentForPull() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        var receivedChangedDocumentIDs = [[String]]()
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { changedDocumentIDs, _, _ in
                receivedChangedDocumentIDs.append(changedDocumentIDs)
            }
        )

        tracker.processChangesForTesting(try changedDocumentFeedData(
            documentID: "missing-local",
            revID: "1-remote"
        ))

        #expect(receivedChangedDocumentIDs == [["missing-local"]])
    }

    @Test("Changes Tracker Reports Changed Document Without Remote Revision For Pull")
    func changesTrackerReportsChangedDocumentWithoutRemoteRevisionForPull() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        var receivedChangedDocumentIDs = [[String]]()
        let tracker = ChangesTracker(
            datastore: storeFixture.store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { changedDocumentIDs, _, _ in
                receivedChangedDocumentIDs.append(changedDocumentIDs)
            }
        )

        tracker.processChangesForTesting(try changesPayloadData(lastSequence: "2", results: [
            ["id": "remote-without-rev"]
        ]))

        #expect(receivedChangedDocumentIDs == [["remote-without-rev"]])
    }

    @Test("Changes Tracker Skips Changed Document When Local Revision Matches")
    func changesTrackerSkipsChangedDocumentWhenLocalRevisionMatches() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let createdRevision = try store.dataStore.createDocument(from: CDTDocumentRevision(docId: "matching-local"))
        let localRevID = try #require(createdRevision.revId)
        var handlerCallCount = 0
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { _, _, _ in
                handlerCallCount += 1
            }
        )

        let hadActivity = tracker.processChangesForTesting(try changedDocumentFeedData(
            documentID: "matching-local",
            revID: localRevID
        ))

        #expect(hadActivity)
        #expect(handlerCallCount == 0)
    }

    @Test("Changes Tracker Skips Older Remote Changed Document")
    func changesTrackerSkipsOlderRemoteChangedDocument() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        try store.dataStore.createDocument(from: CDTDocumentRevision(docId: "newer-local"))
        var handlerCallCount = 0
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { _, _, _ in
                handlerCallCount += 1
            }
        )

        let hadActivity = tracker.processChangesForTesting(try changedDocumentFeedData(
            documentID: "newer-local",
            revID: "0-older"
        ))

        #expect(hadActivity)
        #expect(handlerCallCount == 0)
    }

    @Test("Changes Tracker Reports Typed Task Deletion Before Deleting Local Document")
    func changesTrackerReportsTypedTaskDeletionBeforeDeletingLocalDocument() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let taskID = "remote-deleted-task"
        let task = makeTask(
            id: taskID,
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: nil
        )
        try store.dataStore.createDocument(from: CDTDocumentRevision.revision(fromEntity: task))

        var receivedDeletedDocumentIDs = [[String]]()
        var receivedTypedDeletions = [[OTFWatchSyncDeletion]]()
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            remoteChangeHandler: { _, deletedDocumentIDs, typedDeletions in
                receivedDeletedDocumentIDs.append(deletedDocumentIDs)
                receivedTypedDeletions.append(typedDeletions)
            }
        )

        tracker.processChangesForTesting(try changesFeedData(
            deletedDocumentID: taskID,
            revID: "2-deleted"
        ))

        #expect(receivedDeletedDocumentIDs == [[taskID]])
        #expect(receivedTypedDeletions == [[OTFWatchSyncDeletion(documentID: taskID, entityType: .task)]])
        #expect((try? store.dataStore.getDocumentWithId(taskID)) == nil)
    }

    @Test("Deletion sweep uses stored sequence token and persists remote last sequence")
    func deletionSweepUsesStoredSequenceTokenAndPersistsRemoteLastSequence() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let defaultsFixture = try makeIsolatedChangesTrackerDefaults()
        let defaults = defaultsFixture.defaults
        defer { defaults.removePersistentDomain(forName: defaultsFixture.suiteName) }
        defaults.set("7", forKey: changesTrackerDeletionSweepSequenceKey)
        var capturedRequest: URLRequest?
        var completionCalled = false
        let tracker = ChangesTracker(
            datastore: storeFixture.store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startDeletionSweepRequest: { request, completion in
                capturedRequest = request
                completion(try? deletionSweepFeedData(lastSequence: "42", results: []), nil)
            },
            defaults: defaults
        )

        tracker.performDeletionSweep {
            completionCalled = true
        }

        let requestURL = try #require(capturedRequest?.url)
        let queryItems = queryItemsByName(for: requestURL)
        #expect(completionCalled)
        #expect(requestURL.path == "/db/_changes")
        #expect(queryItems["style"] == "all_docs")
        #expect(queryItems["since"] == "7")
        #expect(queryItems["feed"] == nil)
        #expect(queryItems["heartbeat"] == nil)
        #expect(defaults.string(forKey: changesTrackerDeletionSweepSequenceKey) == "42")
    }

    @Test("Deletion sweep removes local document when remote tombstone revision is newer")
    func deletionSweepRemovesLocalDocumentWhenRemoteTombstoneRevisionIsNewer() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let defaultsFixture = try makeIsolatedChangesTrackerDefaults()
        let defaults = defaultsFixture.defaults
        defer { defaults.removePersistentDomain(forName: defaultsFixture.suiteName) }
        try store.dataStore.createDocument(from: CDTDocumentRevision(docId: "sweep-deleted"))
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startDeletionSweepRequest: { _, completion in
                completion(
                    try? deletionSweepFeedData(lastSequence: "10", results: [
                        [
                            "id": "sweep-deleted",
                            "deleted": true,
                            "changes": [["rev": "2-deleted"]]
                        ]
                    ]),
                    nil
                )
            },
            defaults: defaults
        )

        tracker.performDeletionSweep {}

        #expect((try? store.dataStore.getDocumentWithId("sweep-deleted")) == nil)
        #expect(defaults.string(forKey: changesTrackerDeletionSweepSequenceKey) == "10")
    }

    @Test("Deletion sweep skips local document when remote tombstone revision is older")
    func deletionSweepSkipsLocalDocumentWhenRemoteTombstoneRevisionIsOlder() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let store = storeFixture.store
        let defaultsFixture = try makeIsolatedChangesTrackerDefaults()
        let defaults = defaultsFixture.defaults
        defer { defaults.removePersistentDomain(forName: defaultsFixture.suiteName) }
        try store.dataStore.createDocument(from: CDTDocumentRevision(docId: "sweep-kept"))
        let tracker = ChangesTracker(
            datastore: store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startDeletionSweepRequest: { _, completion in
                completion(
                    try? deletionSweepFeedData(lastSequence: "11", results: [
                        [
                            "id": "sweep-kept",
                            "deleted": true,
                            "changes": [["rev": "1-deleted"]]
                        ]
                    ]),
                    nil
                )
            },
            defaults: defaults
        )

        tracker.performDeletionSweep {}

        #expect((try? store.dataStore.getDocumentWithId("sweep-kept")) != nil)
        #expect(defaults.string(forKey: changesTrackerDeletionSweepSequenceKey) == "11")
    }

    @Test("Deletion sweep completes and keeps sequence after request failure")
    func deletionSweepCompletesAndKeepsSequenceAfterRequestFailure() throws {
        let storeFixture = try makeTemporaryCloudantStore()
        defer { storeFixture.cleanup() }
        let defaultsFixture = try makeIsolatedChangesTrackerDefaults()
        let defaults = defaultsFixture.defaults
        defer { defaults.removePersistentDomain(forName: defaultsFixture.suiteName) }
        defaults.set("3", forKey: changesTrackerDeletionSweepSequenceKey)
        var completionCalled = false
        let tracker = ChangesTracker(
            datastore: storeFixture.store.dataStore,
            remoteURL: try #require(URL(string: "https://example.com/db")),
            startDeletionSweepRequest: { _, completion in
                completion(nil, URLError(.cannotConnectToHost))
            },
            defaults: defaults
        )

        tracker.performDeletionSweep {
            completionCalled = true
        }

        #expect(completionCalled)
        #expect(defaults.string(forKey: changesTrackerDeletionSweepSequenceKey) == "3")
    }
}

private let changesTrackerDeletionSweepSequenceKey = "changes.tracker.deletion.sweep.sequence"
private let changesTrackerDefaultsSuitePrefix = "ChangesTrackerTests"

private struct IsolatedChangesTrackerDefaults {
    let defaults: UserDefaults
    let suiteName: String
}

private func makeIsolatedChangesTrackerDefaults() throws -> IsolatedChangesTrackerDefaults {
    let suiteName = "\(changesTrackerDefaultsSuitePrefix)-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return IsolatedChangesTrackerDefaults(defaults: defaults, suiteName: suiteName)
}

private func queryItemsByName(for url: URL) -> [String: String] {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    return Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item in
        item.value.map { (item.name, $0) }
    })
}

private func deletionSweepFeedData(lastSequence: String, results: [[String: Any]]) throws -> Data {
    try changesPayloadData(lastSequence: lastSequence, results: results)
}

private func changesPayloadData(lastSequence: String, results: [[String: Any]]) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "last_seq": lastSequence,
        "results": results
    ])
}
