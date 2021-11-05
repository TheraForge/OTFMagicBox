//
//  CloudantSyncManager.swift
//  OTFMagicBox
//
//  Created by Admin on 02/11/2021.
//

import Foundation
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
    
    private init() {
        cloudantStore = try? StoreService.shared.currentStore()
    }
    
    func syncCloudantStore(_ completion: @escaping ((Error?) -> Void)) {
        guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
            completion(ForgeError.missingCredential)
            return
        }
        
        if auth.isValid() {
            startSync(completion)
        } else {
            OTFTheraforgeNetwork.shared.refreshToken { [unowned self] result in
                switch result {
                case .success(_):
                    startSync(completion)
                    
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }
    
    func startSync(_ completion: @escaping ((Error?) -> Void)) {
        do {
            try replicate(direction: .push, completionBlock: { [unowned self] error in
                guard error == nil else {
                    completion(error)
                    return
                }
                
                do {
                    try replicate(direction: .pull, completionBlock: { error in
                        completion(error)
                    })
                } catch {
                    completion(error)
                }
            })
        } catch {
            completion(error)
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
