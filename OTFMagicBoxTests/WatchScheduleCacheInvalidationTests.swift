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
@testable import OTFMagicBox

@Suite("Watch schedule cache invalidation")
struct WatchScheduleCacheInvalidationTests {
    @Test("Full resync clears cached and in-flight days")
    func fullResyncClearsCachedAndInFlightDays() throws {
        let first = try fixedDate(day: 1)
        let second = try fixedDate(day: 2)

        let result = WatchScheduleCacheInvalidation.result(
            cachedDays: [first, second],
            prefetchedDaysInFlight: [first],
            context: ScheduleRefreshContext(changeKind: .fullResync),
            calendar: fixedCalendar
        )

        #expect(result.cachedDays.isEmpty)
        #expect(result.prefetchedDaysInFlight.isEmpty)
    }

    @Test("Targeted refresh clears only affected cached and in-flight days")
    func targetedRefreshClearsOnlyAffectedCachedAndInFlightDays() throws {
        let first = try fixedDate(day: 1)
        let second = try fixedDate(day: 2)
        let third = try fixedDate(day: 3)

        let result = WatchScheduleCacheInvalidation.result(
            cachedDays: [first, second, third],
            prefetchedDaysInFlight: [first, second],
            context: ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [second]),
            calendar: fixedCalendar
        )

        #expect(result.cachedDays == [first, third])
        #expect(result.prefetchedDaysInFlight == [first])
    }

    @Test("Preserved visible day survives full and targeted refreshes")
    func preservedVisibleDaySurvivesFullAndTargetedRefreshes() throws {
        let first = try fixedDate(day: 1)
        let second = try fixedDate(day: 2)
        let third = try fixedDate(day: 3)

        let fullResync = WatchScheduleCacheInvalidation.result(
            cachedDays: [first, second, third],
            prefetchedDaysInFlight: [first, second],
            context: ScheduleRefreshContext(changeKind: .fullResync),
            preserving: [second],
            calendar: fixedCalendar
        )
        let targeted = WatchScheduleCacheInvalidation.result(
            cachedDays: [first, second, third],
            prefetchedDaysInFlight: [first, second],
            context: ScheduleRefreshContext(changeKind: .outcomeOnly, affectedDates: [second]),
            preserving: [second],
            calendar: fixedCalendar
        )

        #expect(fullResync.cachedDays == [second])
        #expect(fullResync.prefetchedDaysInFlight == [second])
        #expect(targeted.cachedDays == [first, second, third])
        #expect(targeted.prefetchedDaysInFlight == [first, second])
    }
}

private let fixedCalendar: Calendar = {
    Calendar.current
}()

private func fixedDate(day: Int) throws -> Date {
    let components = DateComponents(
        calendar: fixedCalendar,
        timeZone: fixedCalendar.timeZone,
        year: 2026,
        month: 6,
        day: day,
        hour: 12
    )
    let date = try #require(fixedCalendar.date(from: components))
    return fixedCalendar.startOfDay(for: date)
}
