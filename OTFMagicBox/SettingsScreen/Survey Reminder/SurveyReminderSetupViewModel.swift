//
//  SurveyReminderSetupViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/5/22.
//

import Foundation

class SurveyReminderSetupViewModel: ObservableObject {
    @Published var cellModel: SurveyReminderModel
    
    init() {
        cellModel = SurveyReminderModel(notificationsTurnedOn: true, repetation: .daily)
    }
    
    func save() {
        print("save logic")
    }
}

struct SurveyReminderModel {
    var notificationsTurnedOn: Bool
    var repetation: SurveyRepetation
    var repetationDate: Date = Date()
}

enum SurveyRepetation: Int, CaseIterable {
    case daily = 0
    case weekly
    case monthly
    
    var title: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
}
