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
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnOpen = {
            CloudantSyncManager.shared.syncCloudantStore { error in
                print(error ?? "Synced successfully!")
            }
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.onReceivedMessage = { event in
            print(event)
            guard event.message.count > 0 else {
                return
            }
            CloudantSyncManager.shared.syncCloudantStore { error in
                print(error ?? "Synced successfully!")
            }
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.eventSourceOnComplete = { code, reconnect, error in
            print(error?.localizedDescription ?? "")
        }
        
        TheraForgeNetwork.shared.observeOnServerSentEvents(auth: auth)
    }
}
