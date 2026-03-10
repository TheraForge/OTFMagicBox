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
import OTFUtilities
import OTFCloudantStore
import WatchConnectivity

class SessionManager: NSObject, WCSessionDelegate {

    private enum FileConstants {
        static let liveBpmKey = "bpm"
        static let liveTimestampKey = "timestamp"
    }

    private let logger = OTFLogger.logger()
    var peer: OTFWatchConnectivityPeer?
    var store: OTFCloudantStore?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.debug("WCSession activation did complete: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.debug("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.debug("WCSession did deactivate")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }

    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        logger.debug("Did receive message from Watch App: \(message)")
        if message[databaseSyncedKey] is String {
            self.store?.synchronize { _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                    CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: false) { _ in }
                    replyHandler?(["received": true])
                }
            }
        } else if let bpm = message[FileConstants.liveBpmKey] as? Int,
                  let timestamp = message[FileConstants.liveTimestampKey] as? TimeInterval {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .healthSensorsLiveHeartRate,
                    object: nil,
                    userInfo: [FileConstants.liveBpmKey: bpm, FileConstants.liveTimestampKey: timestamp]
                )
            }
            replyHandler?(["received": true])
        } else {
            guard let store else {
                replyHandler?(["error": "Store unavailable"])
                return
            }

            guard let replyHandler else {
                return
            }

            peer?.reply(to: message, store: store) { reply in
                replyHandler(reply)
            }
        }
    }
}
