/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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

import Combine
import OTFCareKit
import OTFCareKitStore
import OTFCloudantStore
import OTFUtilities

class CareKitManager: NSObject {
    
    #if HEALTH
    let healthKitStore = OCKHealthKitPassthroughStore(name: "CareKitHealthKitStore",
                                                      type: .onDisk(protection: .none))
    #endif
    private(set) var cloudantStore: OTFCloudantStore?
    private(set) var synchronizedStoreManager: OCKSynchronizedStoreManager!
    private(set) lazy var coordinator: OCKStoreCoordinator = {
        let coordinator = OCKStoreCoordinator()
        return coordinator
    }()
    
    static let shared = CareKitManager()
    
    override init() {
        super.init()
        
        initStore()
        
        #if HEALTH
        coordinator.attach(store: healthKitStore)
        #endif
        
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        
        subscribeToNotifications()
        
        guard let cloudantStore = CloudantSyncManager.shared.cloudantStore else { return }
        self.cloudantStore = cloudantStore
        coordinator.attach(store: cloudantStore)
    }
    
    func wipe() throws {
        try CloudantSyncManager.shared.cloudantStore?.datastoreManager.deleteDatastoreNamed("local_db")
    }
    
    fileprivate func initStore(forceUpdate: Bool = false) {
        #if HEALTH
        healthKitStore.populateSampleData()
        #endif
        UserDefaults.standard.set(Date(), forKey: Constants.prefCareKitDataInitDate)
    }
    
    private func subscribeToNotifications() {
        let subscriber = Subscribers.Sink<OCKStoreNotification, Never> { completion in
        } receiveValue: { storeNotification in
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true, completion: nil)
        }
        
        synchronizedStoreManager.notificationPublisher.receive(subscriber: subscriber)
    }
}
