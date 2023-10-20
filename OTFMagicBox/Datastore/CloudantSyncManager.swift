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

import Foundation
import OTFCareKit
import OTFCloudantStore
import OTFCloudClientAPI
import OTFCDTDatastore
import OTFTemplateBox
import OTFUtilities

struct Configuration {
    let targetURL: URL
    let username: String
    let password: String
    
    static var `default`: Configuration {
        let remoteURLString = Constants.API.dbProxyURL
        let remoteURL = URL(string: remoteURLString)!
        return Configuration(targetURL: remoteURL, username: "", password: "")
    }
}

enum ReplicationDirection: String {
    case push, pull
}

class CloudantSyncManager {
    static let shared = CloudantSyncManager()
    var cloudantStore: OTFCloudantStore?
    
    var storeManager: OCKSynchronizedStoreManager {
        CareKitManager.shared.synchronizedStoreManager
    }
    
    private var lastSynced: Date
    private var shouldSyncAgain: Bool {
        let secondsDiff = Date().timeIntervalSince(lastSynced)
        return secondsDiff >= 300
    }
    
    private init() {
        cloudantStore = try? StoreService.shared.currentStore()
        guard let lastDate = Calendar.current.date(byAdding: .minute, value: -10, to: Date()) else {
            lastSynced = Date()
            return
        }
        lastSynced = lastDate
    }
    
    func syncCloudantStore(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
            completion?(ForgeError.missingCredential)
            return
        }
        
        // TODO: - Implement a check to avoid synchronisation for every little change.
        // Perhaps use a timer and sync only if there are changes, perhaps.
        
        if auth.isValid() {
            startSync(notifyWhenDone: notifyWhenDone, completion: completion)
        } else {
            OTFTheraforgeNetwork.shared.refreshToken { [unowned self] result in
                switch result {
                case .success(_):
                    startSync(notifyWhenDone: notifyWhenDone, completion: completion)
                    
                case .failure(let error):
                    completion?(error)
                }
            }
        }
    }
    
    private func startSync(notifyWhenDone: Bool, completion: ((Error?) -> Void)?) {
        do {
            try replicate(direction: .push, completionBlock: { [unowned self] error in
                guard error == nil else {
                    didFinishSyncWith(error: error, completion: completion)
                    return
                }
                
                do {
                    try replicate(direction: .pull, completionBlock: { [unowned self] error in
                        if let error = error {
                            OTFError("error in cloudent manager %{public}@", error.localizedDescription)
                        }
                        else {
#if DEBUG
                            OTFLog("Synced successfully!")
#endif
                            lastSynced = Date()
                            if notifyWhenDone {
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .databaseSuccessfllySynchronized, object: nil)
                                }
                            }
                        }
                        didFinishSyncWith(error: error, completion: completion)
                    })
                } catch {
                    didFinishSyncWith(error: error, completion: completion)
                }
            })
        } catch {
            didFinishSyncWith(error: error, completion: completion)
        }
    }
    
    private func didFinishSyncWith(error: Error?, completion: ((Error?) -> Void)?) {
        DispatchQueue.main.async {
            completion?(error)
        }
    }
    
    private func replicate(direction: ReplicationDirection, completionBlock: @escaping ((Error?) -> Void)) throws {
        let store = try StoreService.shared.currentStore()
        let datastoreManager = store.datastoreManager
        let factory = CDTReplicatorFactory(datastoreManager: datastoreManager)
        
        let configuration = Configuration.default
        
        let replication: CDTAbstractReplication
        switch direction {
        case .push:
            replication = CDTPushReplication(source: store.dataStore,
                                             target: configuration.targetURL,
                                             username: configuration.username,
                                             password: configuration.password)
        case .pull:
            replication = CDTPullReplication(source: configuration.targetURL,
                                             target: store.dataStore,
                                             username: configuration.username,
                                             password: configuration.password)
        }
        
        replication.add(TheraForgeHTTPInterceptor())
        
        let replicator = try factory.oneWay(replication)
        let dataStore = try datastoreManager.datastoreNamed("local_db")
        
        replicator.sessionConfigDelegate = TheraForgeNetwork.shared
        dataStore.sessionConfigDelegate = TheraForgeNetwork.shared
        
        switch direction {
        case .push:
            dataStore.push(to: configuration.targetURL, replicator: replicator, username: configuration.username, password: configuration.password) { (error: Error?) in
                if let error = error {
                    OTFError("error while pushing dataStore %{public}@", error.localizedDescription)
                    completionBlock(error)
                } else {
                    OTFLog("Pushed Successfully")
                    completionBlock(nil)
                }
            }
            
        case .pull:
            dataStore.pull(from: configuration.targetURL, replicator: replicator, username: configuration.username, password: configuration.password) { error in
                completionBlock(error)
            }
        }
    }
}
