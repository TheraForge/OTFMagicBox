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

@Suite("Network observer")
@MainActor
struct NetworkObserverTests {
    @Test("Inactive observer keeps initial status without pinging endpoint")
    func inactiveObserverKeepsInitialStatusWithoutPingingEndpoint() {
        var pingCount = 0
        let observer = OTFNetworkObserver(status: .cellular, active: false) { completion in
            pingCount += 1
            completion(true)
        }

        #expect(observer.status == .cellular)
        #expect(pingCount == 0)
    }

    @Test("Unsatisfied path marks observer offline without pinging endpoint")
    func unsatisfiedPathMarksObserverOfflineWithoutPingingEndpoint() {
        var pingCount = 0
        let observer = OTFNetworkObserver(status: .wifi, active: false) { completion in
            pingCount += 1
            completion(true)
        }

        observer.updateStatusForPath(isSatisfied: false, isExpensive: false)

        #expect(observer.status == .offline)
        #expect(pingCount == 0)
    }

    @Test("Reachable satisfied paths map expensive flag to cellular or wifi")
    func reachableSatisfiedPathsMapExpensiveFlagToCellularOrWifi() async {
        let observer = OTFNetworkObserver(status: .offline, active: false) { completion in
            completion(true)
        }

        observer.updateStatusForPath(isSatisfied: true, isExpensive: false)
        await yieldToMainQueue()
        #expect(observer.status == .wifi)

        observer.updateStatusForPath(isSatisfied: true, isExpensive: true)
        await yieldToMainQueue()
        #expect(observer.status == .cellular)
    }

    @Test("Satisfied path marks observer offline when endpoint cannot be reached")
    func satisfiedPathMarksObserverOfflineWhenEndpointCannotBeReached() async {
        let observer = OTFNetworkObserver(status: .wifi, active: false) { completion in
            completion(false)
        }

        observer.updateStatusForPath(isSatisfied: true, isExpensive: false)
        await yieldToMainQueue()

        #expect(observer.status == .offline)
    }

    private func yieldToMainQueue() async {
        await Task.yield()
        await Task.yield()
    }
}
