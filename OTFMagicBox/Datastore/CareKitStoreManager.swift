//
//  CareKitStoreManager.swift
//  OTFMagicBox
//
//  Created by Admin on 07/12/2021.
//

import Combine
import OTFCareKit
import OTFCareKitStore
import OTFCloudantStore

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
            debugPrint(completion)
        } receiveValue: { storeNotification in
            if let outcomeStoreNotification = storeNotification as? OCKOutcomeNotification {
                print(outcomeStoreNotification)
            }
            else if let taskStoreNotification = storeNotification as? OCKTaskNotification {
                print(taskStoreNotification)
            }
            
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: false, completion: nil)
        }
        
        synchronizedStoreManager.notificationPublisher.receive(subscriber: subscriber)
    }
}
