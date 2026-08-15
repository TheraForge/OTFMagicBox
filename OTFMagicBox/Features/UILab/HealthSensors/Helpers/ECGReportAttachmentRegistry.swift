/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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

import Foundation

final class ECGReportAttachmentRegistry {
    private enum FileConstants {
        static let pendingKeyPrefix = "ECGReportAttachmentRegistry.pending.v1"
        static let pendingDeletionKeyPrefix = "ECGReportAttachmentRegistry.pendingDeletion.v1"
        static let ownersKeyPrefix = "ECGReportAttachmentRegistry.owners.v1"
        static let anonymousNamespace = "anonymous"
    }

    private let defaults: UserDefaults
    private let namespace: () -> String
    private let lock = NSLock()

    init(
        defaults: UserDefaults = .standard,
        namespace: @escaping () -> String = {
            KeychainCloudManager.getEmailAddress
        }
    ) {
        self.defaults = defaults
        self.namespace = namespace
    }

    var pendingAttachmentIDs: Set<String> {
        pendingAttachmentIDs(in: currentNamespace)
    }

    var pendingDeletionAttachmentIDs: Set<String> {
        pendingDeletionAttachmentIDs(in: currentNamespace)
    }

    func pendingAttachmentIDs(in namespace: String) -> Set<String> {
        withLock {
            identifiers(forKey: pendingStorageKey(namespace: namespace))
        }
    }

    func pendingDeletionAttachmentIDs(in namespace: String) -> Set<String> {
        withLock {
            identifiers(forKey: pendingDeletionStorageKey(namespace: namespace))
        }
    }

    var currentNamespace: String {
        let value = namespace().trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? FileConstants.anonymousNamespace : value
    }

    func recordPending(attachmentID: String, namespace: String? = nil) {
        guard attachmentID.isEmpty == false else { return }
        withLock {
            insert(
                attachmentID,
                forKey: pendingStorageKey(namespace: namespace ?? currentNamespace)
            )
        }
    }

    func recordPendingDeletion(attachmentID: String, namespace: String? = nil) {
        guard attachmentID.isEmpty == false else { return }
        withLock {
            insert(
                attachmentID,
                forKey: pendingDeletionStorageKey(namespace: namespace ?? currentNamespace)
            )
        }
    }

    func cancelPendingDeletion(attachmentID: String, namespace: String? = nil) {
        withLock {
            remove(
                attachmentID,
                forKey: pendingDeletionStorageKey(namespace: namespace ?? currentNamespace)
            )
        }
    }

    func markCommitted(attachmentID: String, namespace: String? = nil) {
        withLock {
            remove(
                attachmentID,
                forKey: pendingStorageKey(namespace: namespace ?? currentNamespace)
            )
        }
    }

    func recordCommitted(
        attachmentID: String,
        ownerID: String,
        namespace: String? = nil
    ) {
        guard attachmentID.isEmpty == false, ownerID.isEmpty == false else { return }
        withLock {
            let namespace = namespace ?? currentNamespace
            var owners = committedOwners(namespace: namespace)
            var attachmentIDs = Set(owners[ownerID] ?? [])
            attachmentIDs.insert(attachmentID)
            owners[ownerID] = attachmentIDs.sorted()
            defaults.set(owners, forKey: ownersStorageKey(namespace: namespace))
        }
    }

    func attachmentIDs(ownerID: String) -> Set<String> {
        withLock {
            Set(committedOwners(namespace: currentNamespace)[ownerID] ?? [])
        }
    }

    func remove(attachmentID: String, namespace: String? = nil) {
        withLock {
            let namespace = namespace ?? currentNamespace
            remove(attachmentID, forKey: pendingStorageKey(namespace: namespace))
            remove(attachmentID, forKey: pendingDeletionStorageKey(namespace: namespace))
            var owners = committedOwners(namespace: namespace)
            owners.keys.forEach { ownerID in
                owners[ownerID]?.removeAll { $0 == attachmentID }
                if owners[ownerID]?.isEmpty == true {
                    owners[ownerID] = nil
                }
            }
            setCommittedOwners(owners, namespace: namespace)
        }
    }

    private func pendingStorageKey(namespace: String) -> String {
        "\(FileConstants.pendingKeyPrefix).\(namespace)"
    }

    private func pendingDeletionStorageKey(namespace: String) -> String {
        "\(FileConstants.pendingDeletionKeyPrefix).\(namespace)"
    }

    private func ownersStorageKey(namespace: String) -> String {
        "\(FileConstants.ownersKeyPrefix).\(namespace)"
    }

    private func committedOwners(namespace: String) -> [String: [String]] {
        defaults.dictionary(forKey: ownersStorageKey(namespace: namespace)) as? [String: [String]] ?? [:]
    }

    private func setCommittedOwners(_ owners: [String: [String]], namespace: String) {
        let storageKey = ownersStorageKey(namespace: namespace)
        if owners.isEmpty {
            defaults.removeObject(forKey: storageKey)
        } else {
            defaults.set(owners, forKey: storageKey)
        }
    }

    private func identifiers(forKey key: String) -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    private func insert(_ attachmentID: String, forKey key: String) {
        var values = identifiers(forKey: key)
        values.insert(attachmentID)
        defaults.set(values.sorted(), forKey: key)
    }

    private func remove(_ attachmentID: String, forKey key: String) {
        var values = identifiers(forKey: key)
        values.remove(attachmentID)
        if values.isEmpty {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set(values.sorted(), forKey: key)
        }
    }

    private func withLock<T>(_ work: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return work()
    }
}
