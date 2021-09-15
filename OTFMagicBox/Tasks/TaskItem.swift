//
//  TaskItem.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 04.06.21.
//

import Foundation
import OTFResearchKit
import SwiftUI

/**
  The list of tasks for the user.
 */
enum TaskItem: Int {

    // Task items.
    case sampleSurvey,
         sampleActivity
    
    // Task titles.
    var title: String {
        switch self {
        case .sampleSurvey:
            return "Survey"
        case .sampleActivity:
            return "Activity"
        }
    }
    
    // Task sub titles.
    var subtitle: String {
        switch self {
        case .sampleSurvey:
            return "Sample questions and forms."
        case .sampleActivity:
            return "Sample sensor/data collection activities."
        }
    }
    
    // Icons for the tasks.
    var image: UIImage? {
        switch self {
        case .sampleSurvey:
            return getImage(named: "surveyImage")
        case .sampleActivity:
            return getImage(named: "activityImage")
        }
    }
    
    // Section titles for the tasks.
    var sectionTitle: String {
        switch self {
        case .sampleSurvey, .sampleActivity:
            return "Tasks"
        }
    }

   // Action of a each task.
    var action: some View {
        switch self {
        case .sampleSurvey:
            return AnyView(TaskViewController(tasks: TaskSamples.sampleSurveyTask))
        case .sampleActivity:
            return AnyView(TaskViewController(tasks: TaskSamples.sampleWalkingTask))
        }
    }
    
    fileprivate func getImage(named: String) -> UIImage? {
        UIImage(named: named) ?? UIImage(systemName: "questionmark.square")
    }
    
    static var allValues: [TaskItem] {
        var index = 0
        return Array (
            AnyIterator {
                let returnedElement = self.init(rawValue: index)
                index = index + 1
                return returnedElement
            }
        )
    }
    
}

