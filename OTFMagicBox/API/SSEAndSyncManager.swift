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
            print("Server sent event connection opened")
        }
        
        OTFTheraforgeNetwork.shared.otfNetworkService.onReceivedMessage = { event in
            print(event)
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
