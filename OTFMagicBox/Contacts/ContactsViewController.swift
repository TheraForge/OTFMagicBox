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
