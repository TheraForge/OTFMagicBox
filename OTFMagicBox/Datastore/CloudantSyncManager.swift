//
//  CloudantSyncManager.swift
//  OTFMagicBox
//
//  Created by Admin on 02/11/2021.
//

import Foundation
import OTFCareKit
import OTFCloudantStore
import OTFCloudClientAPI
import OTFCDTDatastore
import OTFTemplateBox

struct Configuration {
    let targetURL: URL
    let username: String
    let password: String
    
    static var `default`: Configuration {
        let remoteURLString = Constants.API.dbProxyURL
        let remoteURL = URL(string: remoteURLString)!
        return Configuration(targetURL: remoteURL,
                             username: Constants.API.dbProxyEmail,
                             password: Constants.API.dbProxyPassword)
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
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        do {
            try replicate(direction: .push, completionBlock: { [unowned self] error in
                guard error == nil else {
                    didFinishSyncWith(error: error, completion: completion)
                    return
                }
                
                do {
                    try replicate(direction: .pull, completionBlock: { error in
                        if let error = error {
                            print(error)
                        }
                        else {
                            #if DEBUG
                            print("Synced successfully!")
                            #endif
                            lastSynced = Date()
                            if notifyWhenDone {
                                NotificationCenter.default.post(name: .databaseSuccessfllySynchronized, object: nil)
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
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
                    print(error)
                    completionBlock(error)
                } else {
                    print("PUSH SUCCEEDED")
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
