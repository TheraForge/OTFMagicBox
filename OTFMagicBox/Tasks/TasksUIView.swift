//
//  TasksUIView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 04.06.21.
//

import SwiftUI
//import OTFResearchKit

/**
  The Tasks view, where a patient performs activities.
 */
struct TasksUIView: View {
    
    var date = ""
    
    let color: Color
    
    let listItems = TaskItem.allValues
    var listItemsPerHeader = [String:[TaskItem]]()
    var listItemsSections = [String]()
    
    init(color: Color) {
        self.color = color
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM. d, YYYY"
        self.date = formatter.string(from: Date())
        
        if listItemsPerHeader.count <= 0 { // init
            for item in listItems {
                if listItemsPerHeader[item.sectionTitle] == nil {
                    listItemsPerHeader[item.sectionTitle] = [TaskItem]()
                    listItemsSections.append(item.sectionTitle)
                }
                
                listItemsPerHeader[item.sectionTitle]?.append(item)
            }
        }
    }
    
    var body: some View {
        VStack {
            Text(YmlReader().studyTitle)
                .font(.system(size: 28, weight:.bold))
                .foregroundColor(self.color)
                .padding(.top, 20)
            Text(self.date).font(.system(size: 18, weight: .regular)).padding()
            List {
                ForEach(listItemsSections, id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(listItemsPerHeader[key]!, id: \.self) { item in
                            TaskItemView(item: item)
                        }
                    }.listRowBackground(Color.white)
                }
            }.listStyle(GroupedListStyle())
        }
    }
}

struct TasksUIView_Previews: PreviewProvider {
    static var previews: some View {
        TasksUIView(color: Color.red)
    }
}
