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

@Suite("Watch live heart rate message")
struct WatchLiveHeartRateMessageTests {
    @Test("Start request accepts boolean and legacy integer payloads")
    func startRequestAcceptsBooleanAndLegacyIntegerPayloads() {
        #expect(WatchLiveHeartRateMessage.shouldStart(from: WatchLiveHeartRateMessage.startRequest()))
        #expect(WatchLiveHeartRateMessage.shouldStart(from: ["healthSensorsLiveHRStart": 1]))
        #expect(!WatchLiveHeartRateMessage.shouldStart(from: ["healthSensorsLiveHRStart": false]))
        #expect(!WatchLiveHeartRateMessage.shouldStart(from: ["healthSensorsLiveHRStart": 0]))
    }

    @Test("BPM payload round trips sample data")
    func bpmPayloadRoundTripsSampleData() throws {
        let timestamp = Date(timeIntervalSince1970: 1_800_400_000)
        let payload = WatchLiveHeartRateMessage.bpmPayload(bpm: 82, timestamp: timestamp)

        let sample = try #require(WatchLiveHeartRateMessage.sample(from: payload))

        #expect(sample == WatchLiveHeartRateSample(bpm: 82, timestamp: timestamp.timeIntervalSince1970))
    }

    @Test("Malformed BPM payloads are ignored")
    func malformedBPMPayloadsAreIgnored() {
        #expect(WatchLiveHeartRateMessage.sample(from: nil) == nil)
        #expect(WatchLiveHeartRateMessage.sample(from: ["bpm": 82]) == nil)
        #expect(WatchLiveHeartRateMessage.sample(from: ["timestamp": 1_800_400_000]) == nil)
        #expect(WatchLiveHeartRateMessage.sample(from: ["bpm": "82", "timestamp": 1_800_400_000]) == nil)
    }

    @Test("Start request delivery requires supported reachable session")
    func startRequestDeliveryRequiresSupportedReachableSession() throws {
        let payload = try #require(WatchLiveHeartRateDelivery.startRequestPayload(
            isSessionSupported: true,
            isReachable: true
        ))

        #expect(WatchLiveHeartRateMessage.shouldStart(from: payload))
        #expect(WatchLiveHeartRateDelivery.startRequestPayload(isSessionSupported: false, isReachable: true) == nil)
        #expect(WatchLiveHeartRateDelivery.startRequestPayload(isSessionSupported: true, isReachable: false) == nil)
    }

    @Test("BPM delivery requires supported reachable session")
    func bpmDeliveryRequiresSupportedReachableSession() throws {
        let timestamp = Date(timeIntervalSince1970: 1_800_500_000)
        let payload = try #require(WatchLiveHeartRateDelivery.bpmPayload(
            bpm: 91,
            timestamp: timestamp,
            isSessionSupported: true,
            isReachable: true
        ))

        let sample = try #require(WatchLiveHeartRateMessage.sample(from: payload))

        #expect(sample == WatchLiveHeartRateSample(bpm: 91, timestamp: timestamp.timeIntervalSince1970))
        #expect(WatchLiveHeartRateDelivery.bpmPayload(
            bpm: 91,
            isSessionSupported: false,
            isReachable: true
        ) == nil)
        #expect(WatchLiveHeartRateDelivery.bpmPayload(
            bpm: 91,
            isSessionSupported: true,
            isReachable: false
        ) == nil)
    }
}
