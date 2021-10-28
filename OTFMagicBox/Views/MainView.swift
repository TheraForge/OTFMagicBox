//
//  MainView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 04.06.21.
//

import SwiftUI

struct MainView: View {
    
    let color: Color
    
    init() {
        self.color = Color(YmlReader().primaryColor)
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
            
            ProfileUIView().tabItem {
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
