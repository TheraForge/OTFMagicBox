//
//  ContactsViewController.swift
//  SampleApp
//
//  Created by Spurti Benakatti on 03/08/21.
//

import OTFCareKitStore
import OTFCareKit
import Foundation
import UIKit
import SwiftUI

struct ContactsViewController: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    
    func updateUIViewController(_ taskViewController: UIViewController, context: Context) {}
    func makeUIViewController(context: Context) -> UIViewController {
        let manager = CareKitManager.shared
        
        let viewController = OCKContactsListViewController(storeManager: manager.synchronizedStoreManager)
        viewController.title = "Care Team"
        
        return UINavigationController(rootViewController: viewController)
    }
    
}


class CareKitManager: NSObject {
    
//    let dataStore = OCKStore(name: "SampleAppStore", type: .onDisk(protection: .none))
    #if HEALTH
    let healthKitStore = OCKHealthKitPassthroughStore(name: "CareKitHealthKitStore",
                                                      type: .onDisk(protection: .none))
    #endif
    private(set) var synchronizedStoreManager: OCKSynchronizedStoreManager!
    
    static let shared = CareKitManager()
    
    override init() {
        super.init()
        
        initStore()
        
        let coordinator = OCKStoreCoordinator()
        #if HEALTH
        coordinator.attach(store: healthKitStore)
        #endif
//        coordinator.attach(store: dataStore)
        
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
    }
    
    func wipe() throws {
//        try dataStore.delete()
        try CloudantSyncManager.shared.cloudantStore?.datastoreManager.deleteDatastoreNamed("local_db")
    }
    
    fileprivate func initStore(forceUpdate: Bool = false) {
//        dataStore.populateSampleData()
        #if HEALTH
        healthKitStore.populateSampleData()
        #endif
        UserDefaults.standard.set(Date(), forKey: Constants.prefCareKitDataInitDate)
    }
}
