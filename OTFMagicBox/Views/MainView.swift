//
//  MainView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 04.06.21.
//

import SwiftUI
import OTFCareKitStore

struct MainView: View {
    
    let color: Color
    let user: OCKPatient
    
    init(user: OCKPatient) {
        self.user = user
        self.color = Color(YmlReader().primaryColor)
        OTFTheraforgeNetwork.shared.refreshToken { response in
            switch response {
            case .success(let data):
                SSEAndSyncManager.shared.subscribeToSSEWith(auth: data.accessToken)
                
            default:
                break
            }
        }
    }
    
    var body: some View {
        TabView {
            TasksUIView(color: self.color).tabItem {
                UIImage.loadImage(named: "tab_tasks").renderingMode(.template)
                Text("Tasks")
            }
            
            if YmlReader().useCareKit {
                ScheduleViewControllerRepresentable().tabItem {
                    UIImage.loadImage(named: "tab_schedule").renderingMode(.template)
                    Text("Schedule")
                }
                
                ContactsViewController().tabItem {
                    UIImage.loadImage(named: "tab_care").renderingMode(.template)
                    Text("Contacts")
                }
            }
            
            ProfileUIView(user: user).tabItem {
                UIImage.loadImage(named: "tab_profile").renderingMode(.template)
                Text("Profile")
            }
        }
        .accentColor(self.color)
        
    }
}


import OTFCareKitStore
import OTFCareKit
import Foundation
import UIKit

struct TasksViewController: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    
    var dataStore = OCKStore(name: "SampleAppStore", type: .inMemory)
    
    func updateUIViewController(_ taskViewController: UIViewController, context: Context) {}
    
    func makeUIViewController(context: Context) -> UIViewController {
        var healthKitStore = OCKHealthKitPassthroughStore(store: dataStore)
        let synchronizedStoreManager: OCKSynchronizedStoreManager = {
            let coordinator = OCKStoreCoordinator()
            #if HEALTH
            coordinator.attach(eventStore: healthKitStore)
            #endif
            coordinator.attach(store: dataStore)
            return OCKSynchronizedStoreManager(wrapping: coordinator)
        }()
        
        let viewController = OCKContactsListViewController(storeManager: synchronizedStoreManager)
        viewController.title = "Care Team"
        // Create the SwiftUI view that provides the window contents.
        return UINavigationController(rootViewController: viewController)
    }
}
