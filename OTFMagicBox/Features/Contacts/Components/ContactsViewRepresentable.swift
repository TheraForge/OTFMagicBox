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

import SwiftUI
import OTFCareKit
import OTFCareKitStore
import OTFUtilities

struct ContactsViewRepresentable: UIViewControllerRepresentable {

    let storeManager: OCKSynchronizedStoreManager
    /// Use this token to imperatively trigger a reload from SwiftUI (change the value to refresh).
    var reloadToken: UUID
    /// Optional error callback (surfaced into SwiftUI)
    var onError: ((Error) -> Void)?
    /// Optional callback invoked on the main thread with the current number of contacts after a fetch; used to drive SwiftUI empty state.
    var onContactsCountChange: ((Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> OCKContactsListViewController {
        let controller = OCKContactsListViewController(storeManager: storeManager)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: OCKContactsListViewController, context: Context) {
        // If the reloadToken changed, force the controller to refetch.
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            uiViewController.fetchContacts()
            context.coordinator.refreshCount()
        }
    }

    final class Coordinator: NSObject, OCKContactsListViewControllerDelegate {

        private let logger = OTFLogger.logger()

        var parent: ContactsViewRepresentable
        var lastReloadToken: UUID?

        init(_ parent: ContactsViewRepresentable) {
            self.parent = parent
        }

        func refreshCount() {
            let query = OCKContactQuery(for: .now)
            parent.storeManager.store.fetchAnyContacts(query: query, callbackQueue: .main) { [weak self] result in
                switch result {
                case .success(let contacts):
                    self?.parent.onContactsCountChange?(contacts.count)
                    self?.logger.info("Contacts count: \(contacts.count)")
                case .failure(let error):
                    self?.parent.onError?(error)
                }
            }
        }

        func contactsListViewController(_ viewController: OCKContactsListViewController, didEncounterError error: Error) {
            parent.onError?(error)
        }
    }
}
