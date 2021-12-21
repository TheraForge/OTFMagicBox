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
    
    init() {
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
            
            ProfileUIView().tabItem {
                UIImage.loadImage(named: "tab_profile").renderingMode(.template)
                Text("Profile")
            }
        }
        .accentColor(self.color)
        
    }
}
