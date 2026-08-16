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

import Testing
@testable import OTFMagicBox

@Suite("Cloudant sync request")
struct CloudantSyncRequestTests {
    @Test("Merged sync requests preserve notification and completion intent")
    func mergedSyncRequestsPreserveNotificationAndCompletionIntent() {
        var firstCompletionCalled = false
        var secondCompletionCalled = false
        var request = CloudantSyncRequest(
            notifyWhenDone: false,
            reasons: ["foreground stale sync"],
            completions: [{ _ in firstCompletionCalled = true }],
            syncOrder: .pullOnly
        )
        let other = CloudantSyncRequest(
            notifyWhenDone: true,
            reasons: ["local mutation"],
            completions: [{ _ in secondCompletionCalled = true }],
            syncOrder: .pushThenPull
        )

        request.merge(other)
        request.completions.forEach { $0?(nil) }

        #expect(request.notifyWhenDone)
        #expect(request.reasons == ["foreground stale sync", "local mutation"])
        #expect(request.completions.count == 2)
        #expect(firstCompletionCalled)
        #expect(secondCompletionCalled)
    }

    @Test(
        "Merged sync requests keep the highest priority order",
        arguments: [
            (SyncOrder.pullOnly, SyncOrder.pushThenPull, SyncOrder.pushThenPull),
            (.pushThenPull, .pullOnly, .pushThenPull),
            (.pullOnly, .pullThenPush, .pullThenPush)
        ]
    )
    func mergedSyncRequestsKeepHighestPriorityOrder(
        initialOrder: SyncOrder,
        otherOrder: SyncOrder,
        expectedOrder: SyncOrder
    ) {
        var request = CloudantSyncRequest(
            notifyWhenDone: false,
            reasons: ["initial"],
            completions: [nil],
            syncOrder: initialOrder
        )
        let other = CloudantSyncRequest(
            notifyWhenDone: false,
            reasons: ["other"],
            completions: [nil],
            syncOrder: otherOrder
        )

        request.merge(other)

        #expect(request.syncOrder == expectedOrder)
    }
}
