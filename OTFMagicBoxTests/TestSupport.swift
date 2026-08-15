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

import Combine
import Foundation
import Testing
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
import OTFTemplateBox
@testable import OTFMagicBox

struct IsolatedUserDefaults {
    let suiteName: String
    let defaults: UserDefaults

    func cleanup() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

func makeIsolatedUserDefaults(prefix: String = "magicbox-tests") -> IsolatedUserDefaults {
    let suiteName = "\(prefix)-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return IsolatedUserDefaults(suiteName: suiteName, defaults: defaults)
}

final class NotificationSpy {
    private let center: NotificationCenter
    private var token: NSObjectProtocol?
    private(set) var notifications: [Notification] = []

    init(name: Notification.Name, object: Any? = nil, center: NotificationCenter = .default) {
        self.center = center
        token = center.addObserver(forName: name, object: object, queue: nil) { [weak self] notification in
            self?.notifications.append(notification)
        }
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        guard let token else { return }
        center.removeObserver(token)
        self.token = nil
    }
}

final class ImmediateScheduler {
    private(set) var delays: [TimeInterval] = []
    private(set) var runCount = 0

    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) {
        delays.append(delay)
        runCount += 1
        work()
    }
}

enum TestPublisherAwaitError: Error {
    case completedWithoutValue
    case timedOut
}

private final class PublisherAwaitState {
    private let lock = NSLock()
    private var didResume = false
    private var cancellable: AnyCancellable?

    func setCancellable(_ cancellable: AnyCancellable) {
        lock.lock()
        if didResume {
            lock.unlock()
            cancellable.cancel()
            return
        }

        self.cancellable = cancellable
        lock.unlock()
    }

    func resume(_ resumeContinuation: () -> Void) {
        let cancellableToCancel: AnyCancellable?

        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }

        didResume = true
        cancellableToCancel = cancellable
        cancellable = nil
        lock.unlock()

        cancellableToCancel?.cancel()
        resumeContinuation()
    }
}

func firstValue<P: Publisher>(
    from publisher: P,
    timeoutNanoseconds: UInt64 = 1_000_000_000
) async throws -> P.Output {
    let state = PublisherAwaitState()

    return try await withCheckedThrowingContinuation { continuation in
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                state.resume {
                    switch completion {
                    case .finished:
                        continuation.resume(throwing: TestPublisherAwaitError.completedWithoutValue)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            },
            receiveValue: { value in
                state.resume {
                    continuation.resume(returning: value)
                }
            }
        )
        state.setCancellable(cancellable)

        Task {
            try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            state.resume {
                continuation.resume(throwing: TestPublisherAwaitError.timedOut)
            }
        }
    }
}

private final class NotificationAwaitState {
    private let center: NotificationCenter
    private let lock = NSLock()
    private var didResume = false
    private var token: NSObjectProtocol?

    init(center: NotificationCenter) {
        self.center = center
    }

    func setToken(_ token: NSObjectProtocol) {
        lock.lock()
        if didResume {
            lock.unlock()
            center.removeObserver(token)
            return
        }

        self.token = token
        lock.unlock()
    }

    func resume(_ resumeContinuation: () -> Void) {
        let tokenToRemove: NSObjectProtocol?

        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }

        didResume = true
        tokenToRemove = token
        token = nil
        lock.unlock()

        if let tokenToRemove {
            center.removeObserver(tokenToRemove)
        }
        resumeContinuation()
    }
}

func firstNotification(
    named name: Notification.Name,
    object: Any? = nil,
    center: NotificationCenter = .default,
    timeoutNanoseconds: UInt64 = 1_000_000_000
) async throws {
    let state = NotificationAwaitState(center: center)

    try await withCheckedThrowingContinuation { continuation in
        let token = center.addObserver(forName: name, object: object, queue: nil) { _ in
            state.resume {
                continuation.resume()
            }
        }
        state.setToken(token)

        Task {
            try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            state.resume {
                continuation.resume(throwing: TestPublisherAwaitError.timedOut)
            }
        }
    }
}

func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    pollIntervalNanoseconds: UInt64 = 10_000_000,
    _ condition: @escaping () -> Bool
) async throws {
    var elapsed: UInt64 = 0
    while elapsed < timeoutNanoseconds {
        if condition() {
            return
        }
        try await Task.sleep(nanoseconds: pollIntervalNanoseconds)
        elapsed += pollIntervalNanoseconds
    }

    if condition() {
        return
    }
    throw TestPublisherAwaitError.timedOut
}

final class TemporaryCloudantStore {
    let name: String
    private var retainedStore: OTFCloudantStore?

    var store: OTFCloudantStore {
        guard let retainedStore else {
            preconditionFailure("TemporaryCloudantStore used after cleanup")
        }
        return retainedStore
    }

    init(name: String, store: OTFCloudantStore) {
        self.name = name
        self.retainedStore = store
    }

    func cleanup() {
        guard let store = retainedStore else { return }
        let manager = store.datastoreManager
        let name = name
        manager.closeDatastoreNamed(name)
        retainedStore = nil

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.2) {
            try? manager.deleteDatastoreNamed(name)
        }
    }
}

func makeTemporaryCloudantStore() throws -> TemporaryCloudantStore {
    let name = uniqueStoreName()
    let store = try OTFCloudantStore(storeName: name)
    return TemporaryCloudantStore(name: name, store: store)
}

func makeRevision(
    docId: String = "outcome-1",
    revId: String,
    body: [String: Any]?,
    deleted: Bool
) -> CDTDocumentRevision {
    CDTDocumentRevision(
        docId: docId,
        revisionId: revId,
        body: body,
        deleted: deleted,
        attachments: nil,
        sequence: 0
    )
}

func makeTask(id: String, start: Date, end: Date?) -> OCKTask {
    let schedule = OCKSchedule.dailyAtTime(
        hour: 8,
        minutes: 0,
        start: start,
        end: end,
        text: nil
    )
    var task = OCKTask(id: id, title: id, carePlanUUID: nil, schedule: schedule)
    task.createdDate = start
    task.updatedDate = start
    return task
}

func insertBackendStyleTask(
    _ task: OCKTask,
    documentID: String,
    into store: OTFCloudantStore
) throws {
    var body = CDTDocumentRevision.encodedDictionary(fromEntity: task)
    body.removeValue(forKey: "startDate")
    body.removeValue(forKey: "endDate")
    let revision = CDTDocumentRevision(docId: documentID)
    revision.body = NSMutableDictionary(dictionary: body)
    try store.dataStore.createDocument(from: revision)
}

func fetchTaskTitles(in store: OTFCloudantStore, on date: Date) async throws -> [String] {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let nextDay = try #require(Calendar.current.date(byAdding: .day, value: 1, to: startOfDay))
    let endOfDay = nextDay.addingTimeInterval(-1)
    var query = OCKTaskQuery(dateInterval: DateInterval(start: startOfDay, end: endOfDay))
    query.excludesTasksWithNoEvents = true

    let fetchResult = await withCheckedContinuation { continuation in
        store.fetchTasks(query: query, callbackQueue: .main) { result in
            continuation.resume(returning: result)
        }
    }

    switch fetchResult {
    case .success(let tasks):
        return tasks.map { $0.title ?? "" }
    case .failure(let error):
        throw error
    }
}

func uniqueStoreName() -> String {
    let suffix = UUID().uuidString
        .lowercased()
        .replacingOccurrences(of: "-", with: "_")
    return "magicbox_tests_\(suffix)"
}

func makeAuth(token: String, refreshToken: String, expiresIn: TimeInterval = 3600) -> Auth {
    Auth(
        token: token,
        refreshToken: refreshToken,
        iat: Date().timeIntervalSince1970,
        exp: Date().addingTimeInterval(expiresIn).timeIntervalSince1970
    )
}

func makeAppConfiguration(
    apiKey: String = "valid.api.key",
    scheduleTitle: OTFStringLocalized = "Schedule",
    contactsTitle: OTFStringLocalized = "Contacts",
    checkupTitle: OTFStringLocalized = "Check-Up",
    uiTitle: OTFStringLocalized = "UI Lab",
    profileTitle: OTFStringLocalized = "Profile",
    playgroundTitle: OTFStringLocalized = "Playground",
    scheduleSymbol: String = "calendar",
    contactsSymbol: String = "heart",
    checkupSymbol: String = "checkmark.circle",
    playgroundSymbol: String = "apple.image.playground",
    uiSymbol: String = "uiwindow.split.2x1",
    profileSymbol: String = "person",
    useFilledSymbols: Bool = false,
    useCareKit: Bool = true,
    showCheckupScreen: Bool = true,
    showUIScreen: Bool = true,
    enableLocation: Bool = false,
    enableConditions: Bool = false,
    playgroundMode: Bool = false
) -> AppConfiguration {
    AppConfiguration(
        version: "2.1.0",
        apiKey: apiKey,
        teamWebsite: "<your-web-site-url>",
        teamEmail: "<your-team-email>",
        teamPhone: "<your-team-phone>",
        scheduleTitle: scheduleTitle,
        contactsTitle: contactsTitle,
        checkupTitle: checkupTitle,
        uiTitle: uiTitle,
        profileTitle: profileTitle,
        playgroundTitle: playgroundTitle,
        scheduleSymbol: scheduleSymbol,
        contactsSymbol: contactsSymbol,
        checkupSymbol: checkupSymbol,
        playgroundSymbol: playgroundSymbol,
        uiSymbol: uiSymbol,
        profileSymbol: profileSymbol,
        useFilledSymbols: useFilledSymbols,
        useCareKit: useCareKit,
        showCheckupScreen: showCheckupScreen,
        showUIScreen: showUIScreen,
        enableLocation: enableLocation,
        enableConditions: enableConditions,
        showPrivacyAndTerms: true,
        showConsentDocument: true,
        playgroundMode: playgroundMode,
        alertTitle: "API Key Missing",
        alertMessage: "Please set a valid API Key to use the app"
    )
}

func changesFeedData(deletedDocumentID: String, revID: String) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "last_seq": "1",
        "results": [
            [
                "id": deletedDocumentID,
                "deleted": true,
                "changes": [
                    ["rev": revID]
                ]
            ]
        ]
    ])
}

func changedDocumentFeedData(documentID: String, revID: String) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "last_seq": "1",
        "results": [
            [
                "id": documentID,
                "changes": [
                    ["rev": revID]
                ]
            ]
        ]
    ])
}
