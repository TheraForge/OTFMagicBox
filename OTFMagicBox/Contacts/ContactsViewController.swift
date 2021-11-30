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
import Combine

class OTFContactsListViewController: OCKContactsListViewController {
    
}

final class ContactsViewController: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    
    @State private var contactsListViewController: OCKContactsListViewController
    private var subscription: Cancellable?
    
    init() {
        let manager = CareKitManager.shared
        let viewController = OCKContactsListViewController(storeManager: manager.synchronizedStoreManager)
        viewController.title = "Care Team"
        contactsListViewController = viewController
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStoreChangeNotification(_:)),
                                               name: .databaseSuccessfllySynchronized, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateUIViewController(_ taskViewController: UIViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: contactsListViewController)
    }
    
    @objc private func didReceiveStoreChangeNotification(_ notification: Notification) {
        contactsListViewController.fetchContacts()
    }
}


class CareKitManager: NSObject {
    
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
        
        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        
        guard let cloudantStore = CloudantSyncManager.shared.cloudantStore else { return }
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
}
