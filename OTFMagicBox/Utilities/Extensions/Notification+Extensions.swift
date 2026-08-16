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

enum ScheduleRefreshKind: String {
    case taskMembership
    case outcomeOnly
    case fullResync
}

struct ScheduleRefreshContext {
    private enum UserInfoKeys {
        static let kind = "schedule.refresh.kind"
        static let affectedDates = "schedule.refresh.affectedDates"
    }

    let changeKind: ScheduleRefreshKind
    let affectedDates: [Date]

    init(changeKind: ScheduleRefreshKind, affectedDates: [Date] = []) {
        let calendar = Calendar.current
        self.changeKind = changeKind
        self.affectedDates = Array(
            Set(affectedDates.map { calendar.startOfDay(for: $0) })
        ).sorted()
    }

    init?(notification: Notification) {
        guard let rawKind = notification.userInfo?[UserInfoKeys.kind] as? String,
              let changeKind = ScheduleRefreshKind(rawValue: rawKind) else {
            return nil
        }

        let affectedDates = notification.userInfo?[UserInfoKeys.affectedDates] as? [Date] ?? []
        self.init(changeKind: changeKind, affectedDates: affectedDates)
    }

    var invalidatesAllDates: Bool {
        changeKind == .fullResync || affectedDates.isEmpty
    }

    func affects(date: Date, calendar: Calendar = .current) -> Bool {
        guard !invalidatesAllDates else { return true }
        return affectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    var notificationUserInfo: [AnyHashable: Any] {
        [
            UserInfoKeys.kind: changeKind.rawValue,
            UserInfoKeys.affectedDates: affectedDates
        ]
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name(Constants.Notification.kOnboardingCompleted)
    static let dataSyncRequest = Notification.Name(rawValue: Constants.Notification.kDataSyncRequest)
    static let databaseSynchronized = Notification.Name(rawValue: Constants.Notification.kDatabaseSynchronized)
    static let localScheduleContentChanged = Notification.Name(rawValue: "notification.schedule.local.content.changed")
    static let scheduleRefreshRequested = Notification.Name(rawValue: "notification.schedule.refresh.requested")
    static let imageDownloaded = Notification.Name(rawValue: Constants.Notification.kImageDownloaded)
    static let deleteUserAccount = Notification.Name(rawValue: Constants.Notification.kDeleteUserAccount)
    static let healthSensorsLiveHeartRate = Notification.Name(rawValue: Constants.Notification.kHealthSensorsLiveHeartRate)
}

extension NotificationCenter {
    func postScheduleRefresh(_ context: ScheduleRefreshContext, object: Any? = nil) {
        post(name: .scheduleRefreshRequested, object: object, userInfo: context.notificationUserInfo)
    }
}
