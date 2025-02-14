/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.
 
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

import UIKit
import OTFUtilities
import WatchConnectivity
import OTFCareKitStore
import OTFCloudantStore
import OTFTemplateBox
import OTFResearchKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let careKitManager = CareKitStoreManager.shared
    private(set) lazy var sessionManager: SessionManager = {
        let sessionManager = SessionManager()
        sessionManager.peer = self.careKitManager.cloudantSyncManager.peer
        sessionManager.store = self.careKitManager.cloudantStore
        return sessionManager
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        do {
            try OTFConfigManager.shared.loadDataFromFile(nil)
        } catch {
            OTFLog("error while loading data from file %{public}@", error.localizedDescription)
        }
        
        // Settig the crash logging to capture crashes
        setupCrashLogger()
        setupCrashLogging()
        
        let tintColor = YmlReader().appStyle.buttonTextColor.color

        let defaultProtection = OTFConfigManager.shared.defaultOTFProtectionLevel()
        
        switch defaultProtection {
        case .runToCompletionWithIn10Seconds:
            OTFLog("Default protection is set runToCompletionWithIn10Seconds")
        case .runToCompletionBeyond10Seconds:
            OTFLog("Default protection is set runToCompletionBeyond10Seconds")
        case .backgroundMode:
            OTFLog("Default protection is set background Mode")
        case .none:
            OTFLog("Default protection is not set")
        }
        
        OCKStoreManager.shared.coreDataStore.populateSampleData()
        
        WCSession.default.delegate = sessionManager
        WCSession.default.activate()
        
        UIView.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).tintColor = tintColor
        
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

class SessionManager: NSObject, WCSessionDelegate {
    
    fileprivate var peer: OTFWatchConnectivityPeer!
    fileprivate var store: OTFCloudantStore!
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("WCSession activation did complete: \(activationState)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        print("Did receive message from WATCHAPP! - \(message)")
        if message[databaseSyncedKey] as? String != nil {
            self.store.synchronize { error in
                print(error?.localizedDescription ?? "Successful sync!")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .databaseSuccessfllySynchronized, object: nil)
                    CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: false) { _ in }
                }
            }
        } else {
            peer.reply(to: message, store: store) { reply in
                replyHandler(reply)
            }
        }
    }
}

extension AppDelegate {
    func setupCrashLogger() {
        NSSetUncaughtExceptionHandler { exception in
            let message = "CRASH: \(exception.name) - \(exception.reason ?? "Unknown reason")"
            let stackTrace = exception.callStackSymbols.joined(separator: "\n")
            
            OTFError("%@", message)
            OTFError("%@", stackTrace)
        }
    }
}
