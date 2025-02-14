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
import OTFCareKit
import OTFCareKitStore
import Combine

class OTFCareKitStoreManager: NSObject {
    static var shared = OTFCareKitStoreManager()
    let peer = OTFWatchConnectivityPeer()
    var cloudantStore: OTFCloudantStore!
    var session: SessionManager!
    var synchronizedStoreManager: OCKSynchronizedStoreManager!
    var coordinator: OCKStoreCoordinator = {
        let coordinator = OCKStoreCoordinator()
        return coordinator
    }()
    
    override init() {
        let store = try? WatchStoreService.shared.currentStore(peer: self.peer)
        guard let cloudantStore = store else { return }
        self.cloudantStore = cloudantStore
        
        self.coordinator.attach(store: self.cloudantStore)
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        
        peer.automaticallySynchronizes = true
        session = SessionManager(peer: peer, store: cloudantStore)
        
        let subscriber = Subscribers.Sink<OCKStoreNotification, Never> { _ in
        } receiveValue: { _ in
            store?.synchronize(target: Target.mobile, completion: { _ in })
        }
        
        synchronizedStoreManager.notificationPublisher.receive(subscriber: subscriber)
    }
    
    func wipe() throws {
        try cloudantStore.datastoreManager.deleteDatastoreNamed("local_db")
    }
}
