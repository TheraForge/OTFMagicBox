//
//  AppDelegate.swift
//  CompletelyNewApp
//
//  Created by Miroslav Kutak on 18.04.2021.
//

import UIKit
import OTFTemplateBox
import ResearchKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        do {
            try OTFConfigManager.shared.loadDataFromFile(nil)
        } catch {
            print(error)
        }
        let tintColor = YmlReader().tintColor()

        let defaultProtection = OTFConfigManager.shared.defaultOTFProtectionLevel()

        switch defaultProtection {
        case .runToCompletionWithIn10Seconds:
            print("Default protection is set runToCompletionWithIn10Seconds")
        case .runToCompletionBeyond10Seconds:
            print("Default protection is set runToCompletionBeyond10Seconds")
        case .backgroundMode:
            print("Default protection is set background Mode")
        case .none:
            print("Default protection is not set")
        }
        
        UIView.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).tintColor = tintColor
        
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

