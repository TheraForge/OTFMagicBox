//
//  SettingsViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/24/22.
//

import Foundation

class SettingsViewModel: ObservableObject {
    @Published var settingsCells: [SettingsSection] = []
    @Published var navigationDestinationValue: Int? = nil
    
    var navigationDestination: SettingsNavigation = .none {
        didSet {
            navigate()
        }
    }
    
    func loadItems() {
        navigationDestination = .none
        settingsCells = [SettingsSection(title: "", cells:
            [SettingsCellItem(title: "Medication Setup", navigationDestination: .medicationSetup), SettingsCellItem(title: "Medication Notification Setup", navigationDestination: .medicationNotificationSetup)]),
             SettingsSection(title: "", cells: [SettingsCellItem(title: "FoG Setup", navigationDestination: .fogSetup), SettingsCellItem(title: "FoG Timer Setup", navigationDestination: .fogTimerSetup)]),
             SettingsSection(title: "", cells:[SettingsCellItem(title: "Survey Reminder Setup", navigationDestination: .surveyReminderSetup)])
        ]
    }
    
    func navigate() {
        DispatchQueue.main.async {
            if self.navigationDestination != .none {
                self.navigationDestinationValue = self.navigationDestination.rawValue
            } else {
                self.navigationDestinationValue = nil
            }
        }
    }
    
    func didSelectRow(at index: Int) {
        if index == 0 {
            navigationDestination = .medicationSetup
        } else if index == 1 {
            navigationDestination = .medicationNotificationSetup
        } else if index == 2 {
            navigationDestination = .fogSetup
        } else if index == 3 {
            navigationDestination = .fogTimerSetup
        } else if index == 4 {
            navigationDestination = .surveyReminderSetup
        }
    }
}

struct SettingsSection: Identifiable {
    var id = UUID()
    var title: String
    var cells: [SettingsCellItem]
}

struct SettingsCellItem: Identifiable {
    var id = UUID()
    var title: String
    var navigationDestination: SettingsNavigation
    var isLastCell: Bool {
        return [SettingsNavigation.medicationNotificationSetup, SettingsNavigation.fogTimerSetup, SettingsNavigation.surveyReminderSetup].contains(navigationDestination)
    }
}

enum SettingsNavigation: Int {
    case medicationSetup = 0
    case medicationNotificationSetup = 1
    case fogSetup = 2
    case fogTimerSetup = 3
    case surveyReminderSetup = 4
    case none = -1
}
