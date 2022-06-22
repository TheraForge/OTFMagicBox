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

import OTFCareKitStore
import OTFCareKit
import Foundation
import UIKit
import SwiftUI
import Combine

final class ContactsViewController: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = OCKContactsListViewController
    
    @State private var contactsListViewController: OCKContactsListViewController
    var syncStoreManager: OCKSynchronizedStoreManager
    
    init(storeManager: OCKSynchronizedStoreManager) {
        self.syncStoreManager = storeManager
        let viewController = OCKContactsListViewController(storeManager: storeManager)
        viewController.title = "Care Team"
        contactsListViewController = viewController
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStoreChangeNotification(_:)),
                                               name: .databaseSuccessfllySynchronized, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteProfileEventNotification(_:)),
                                               name: .deleteUserAccount, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateUIViewController(_ taskViewController: OCKContactsListViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> OCKContactsListViewController {
        return contactsListViewController
    }
    
    @objc private func didReceiveStoreChangeNotification(_ notification: Notification) {
        contactsListViewController.fetchContacts()
    }
    
    @objc private func deleteProfileEventNotification(_ notification: Notification) {
        
        contactsListViewController.alertView(title: "Account Deleted", message: Constants.deleteAccount) { action in
            SSEAndSyncManager().moveToOnboardingView()
        }
    }
}

struct ContactsNavigationView: View {
    let syncStoreManager: OCKSynchronizedStoreManager
    
    var body: some View {
        NavigationView {
            ContactsViewController(storeManager: syncStoreManager)
                .navigationTitle(Text("Care Team"))
        }
    }
}

extension UIViewController{
    
    func alertView(title: String , message: String, completionYes: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: completionYes)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
