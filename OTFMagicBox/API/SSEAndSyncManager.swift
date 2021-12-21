//
//  SSEAndSyncManager.swift
//  OTFMagicBox
//
//  Created by Admin on 03/11/2021.
//

import Foundation
import OTFCloudClientAPI

class SSEAndSyncManager {
    static let shared = SSEAndSyncManager()
    
    // Subscribe to SSE
    public func subscribeToSSEWith(auth: Auth) {
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnOpen = { [unowned self] in
            syncDatabase()
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.onReceivedMessage = { [unowned self] event in
            print(event)
            guard event.message.count > 0 else {
                return
            }
            syncDatabase(postNotification: true)
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnComplete = { code, reconnect, error in
            print(error?.localizedDescription ?? "")
            if reconnect == true {
                TheraForgeNetwork.shared.observeOnServerSentEvents(auth: auth)
            }
        }
        
        TheraForgeNetwork.shared.observeOnServerSentEvents(auth: auth)
    }
    
    private func syncDatabase(postNotification: Bool = false) {
        CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: postNotification) { _ in
            
        }
    }
}
