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
        self.color = Color.red
    }
    
    var body: some View {
        TabView {
            TasksUIView(color: self.color).tabItem {
                Image("tab_tasks").renderingMode(.template)
                Text("Tasks")
            }
            
         /*   ScheduleViewController().tabItem {
                Image("tab_schedule").renderingMode(.template)
                Text("Schedule")
            }
                
            ContactsViewController().tabItem {
                Image("tab_care").renderingMode(.template)
                Text("Contact")
            }*/

          /*  ProfileUIView(color: self.color).tabItem {
                Image("tab_profile").renderingMode(.template)
                Text("Profile")
            }*/
        }
        .accentColor(self.color)
    }
}
