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

struct WatchLiveHeartRateSample: Equatable {
    let bpm: Int
    let timestamp: TimeInterval
}

enum WatchLiveHeartRateMessage {
    private enum Key {
        static let start = "healthSensorsLiveHRStart"
        static let bpm = "bpm"
        static let timestamp = "timestamp"
    }

    static func startRequest() -> [String: Any] {
        [Key.start: true]
    }

    static func shouldStart(from message: [String: Any]) -> Bool {
        (message[Key.start] as? Bool) == true || (message[Key.start] as? Int) == 1
    }

    static func bpmPayload(bpm: Int, timestamp: Date = Date()) -> [String: Any] {
        [
            Key.bpm: bpm,
            Key.timestamp: timestamp.timeIntervalSince1970
        ]
    }

    static func sample(from message: [AnyHashable: Any]?) -> WatchLiveHeartRateSample? {
        guard let message,
              let bpm = message[Key.bpm] as? Int,
              let timestamp = message[Key.timestamp] as? TimeInterval else {
            return nil
        }

        return WatchLiveHeartRateSample(bpm: bpm, timestamp: timestamp)
    }
}

enum WatchLiveHeartRateDelivery {
    static func startRequestPayload(
        isSessionSupported: Bool,
        isReachable: Bool
    ) -> [String: Any]? {
        guard isSessionSupported, isReachable else { return nil }
        return WatchLiveHeartRateMessage.startRequest()
    }

    static func bpmPayload(
        bpm: Int,
        timestamp: Date = Date(),
        isSessionSupported: Bool,
        isReachable: Bool
    ) -> [String: Any]? {
        guard isSessionSupported, isReachable else { return nil }
        return WatchLiveHeartRateMessage.bpmPayload(bpm: bpm, timestamp: timestamp)
    }
}
