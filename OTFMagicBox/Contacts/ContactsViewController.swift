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
        coordinator.taskDelegate = self
        coordinator.contactDelegate = self
        coordinator.outcomeDelegate = self
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
            
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true, completion: nil)
        }
        
        synchronizedStoreManager.notificationPublisher.receive(subscriber: subscriber)
    }
}

extension CareKitManager: OCKContactStoreDelegate {
    func contactStore(_ store: OCKAnyReadOnlyContactStore, didAddContacts contacts: [OCKAnyContact]) {
        print(contacts)
    }
    
    func contactStore(_ store: OCKAnyReadOnlyContactStore, didUpdateContacts contacts: [OCKAnyContact]) {
        
    }
    
    func contactStore(_ store: OCKAnyReadOnlyContactStore, didDeleteContacts contacts: [OCKAnyContact]) {
        
    }
}

extension CareKitManager: OCKTaskStoreDelegate {
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, didAddTasks tasks: [OCKAnyTask]) {
        print(tasks)
    }
    
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, didUpdateTasks tasks: [OCKAnyTask]) {
        print(tasks)
    }
    
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, didDeleteTasks tasks: [OCKAnyTask]) {
        print(tasks)
    }
}

extension CareKitManager: OCKOutcomeStoreDelegate {
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didAddOutcomes outcomes: [OCKAnyOutcome]) {
        print(outcomes)
    }
    
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didUpdateOutcomes outcomes: [OCKAnyOutcome]) {
        print(outcomes)
    }
    
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didDeleteOutcomes outcomes: [OCKAnyOutcome]) {
        print(outcomes)
    }
    
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didEncounterUnknownChange change: String) {
        print(change)
    }
}
