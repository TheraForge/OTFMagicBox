/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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

class SessionManager: NSObject, WCSessionDelegate {
    
    fileprivate(set) var peer: OTFWatchConnectivityPeer!
    fileprivate(set) var store: OTFCloudantStore!
    @Published var tasks = [OCKAnyTask]()
    
    init(peer: OTFWatchConnectivityPeer!, store: OTFCloudantStore!) {
        super.init()
        self.peer = peer
        self.store = store
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
            
        print("New session state: \(activationState)")
        if let error {
            print("Error is \(error.localizedDescription)")
        }
        
        switch activationState {
        case .activated:
            print("WCSession activated successfully")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.store.synchronize { error in
                    print(error?.localizedDescription ?? "Successful sync!")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .databaseSync, object: nil)
                    }
                }
            }
            
        case .inactive:
            print("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")
        case .notActivated:
            print("Unexpected .notActivated state received after trying to activate the WCSession")
        @unknown default:
            print("Unexpected state received after trying to activate the WCSession")
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        print("Did receive message from MOBILE APP!")
        if message[databaseSyncedKey] as? String != nil {
            self.store.synchronize { error in
                print(error?.localizedDescription ?? "Successful sync!")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .databaseSync, object: nil)
                }
            }
        } else if message["userNotLoggedIn"] as? String != nil {
            // Wipe out data
            self.store.deleteRecords { _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .userLoggedOut, object: nil)
                }
            }
        } else {
            peer.reply(to: message, store: store) { reply in
                replyHandler(reply)
            }
        }
    }
}
