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

import OTFCloudantStore
import WatchConnectivity
import WatchKit
import OTFCareKitStore
import OTFCareKit
import OTFUtilities

class SessionManager: NSObject, WCSessionDelegate {

    private enum FileConstants {
        static let liveStartMessageKey = "healthSensorsLiveHRStart"
    }

    let peer: OTFWatchConnectivityPeer
    let store: OTFCloudantStore

    @Published var tasks = [OCKAnyTask]()

    private let logger = OTFLogger.logger()

    init(peer: OTFWatchConnectivityPeer, store: OTFCloudantStore) {
        self.peer = peer
        self.store = store
        super.init()
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        logger.info("WCSession activation did complete with state: \(activationState.rawValue)")

        if let error {
            logger.info("WCSession activation error: \(error.localizedDescription)")
        }

        switch activationState {
        case .activated:
            logger.info("WCSession activated successfully")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [store, logger] in
                store.synchronize { error in
                    if let error {
                        logger.info("Store synchronization error: \(error.localizedDescription)")
                    } else {
                        logger.info("Store synchronized successfully")
                    }
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                    }
                }
            }

        case .inactive:
            logger.info("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")

        case .notActivated:
            logger.info("Unexpected .notActivated state received after trying to activate the WCSession")

        @unknown default:
            logger.info("Unexpected WCSession state received after trying to activate")
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message, replyHandler: nil)
    }

    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {

        logger.debug("Did receive message from MOBILE APP: \(message)")

        if message[databaseSyncedKey] is String {
            store.synchronize { [logger] error in
                if let error {
                    logger.info("Store synchronization error after databaseSyncedKey message: \(error.localizedDescription)")
                } else {
                    logger.info("Store synchronized successfully after databaseSyncedKey message")
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .databaseSynchronized, object: nil)
                }
            }
            replyHandler?(["received": true])
            return
        }

        let shouldStartLiveHeartRate =
            (message[FileConstants.liveStartMessageKey] as? Bool) == true ||
            (message[FileConstants.liveStartMessageKey] as? Int) == 1

        if shouldStartLiveHeartRate {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .healthSensorsLiveHeartRateStart, object: nil)
            }
            replyHandler?(["received": true])
            return
        }

        if message["userNotLoggedIn"] is String {
            logger.info("Received userNotLoggedIn message; deleting local records")
            store.deleteRecords { _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .userLoggedOut, object: nil)
                }
            }
            replyHandler?(["received": true])
            return
        }

        guard let replyHandler else {
            return
        }

        peer.reply(to: message, store: store, sendReply: replyHandler)
    }
}
