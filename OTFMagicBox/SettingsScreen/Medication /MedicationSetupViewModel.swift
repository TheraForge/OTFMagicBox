//
//  MedicationSetupViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/27/22.
//

import Foundation
import OTFCareKitStore

class MedicationSetupViewModel: ObservableObject {
    @Published var cells: [MedicationSetupCellModel] = []
    var storeManager: OCKStoreManager = OCKStoreManager.shared
    
    func loadItems() {
        storeManager.coreDataStore.fetchTasks(completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tasks):
                let filteredTask = tasks.filter({
                    $0.userInfo?.contains(where: {$0.key == Constants.TaskCarePlanUUID.userInfoKey}) ?? false})
                for task in filteredTask {
                    let medicationCell = MedicationSetupCellModel(with: task.userInfo!)
                    if !self.cells.contains(where: {
                        $0.id == medicationCell.id
                    }) {
                        self.cells.append(medicationCell)
                    }
                }
            case .failure(let error):
                print("Error fetching tasks: ", error.errorDescription)
                self.cells = [
                    MedicationSetupCellModel(name: "Dopamine antagonist", dosage: 2, dosageFrequency: .daily),
                    MedicationSetupCellModel(name: "Amantadine", dosage: 1,  dosageFrequency: .weekly),
                    MedicationSetupCellModel(name: "Anticholinergics", dosage: 1, dosageFrequency: .biweekly, isLastCell: true)
                ]
            }
        })
    }
}

struct MedicationSetupCellModel: Identifiable {
    var id: UUID = UUID()
    var name: String
    var dosage: Int
    var hours: Int = 0
    var dosageFrequency: DosageFrequency
    var notificationFrequency: DosageFrequency = .daily
    var startDate: Date = Date()
    var endDate: Date = Date() + (7 * 60 * 60 * 24)
    var titleSeparator: String = " • "
    var isLastCell: Bool = false // todo handle last cell
    var description: String = ""
    
    var titleSufix: String {
        return titleSeparator + "\(dosage) round" + (dosage > 1 ? "s" : "")// todo - localization plural
    }
    
    var subtitle: String = ""
    var title: String { return name + titleSufix }
}

enum DosageFrequency: Int, CaseIterable {
    case hourly
    case daily
    case weekly
    case biweekly
    case monthly
    
    var title: String {
        switch self {
        case .hourly:
            return "Hourly"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Biweekly"
        case .monthly:
            return "Monthly"
        }
    }
}

extension MedicationSetupCellModel {
    func toUserInfoDict() -> [String: String] {
        var dict = [String: String]()
        let otherSelf = Mirror(reflecting: self)
        for child in otherSelf.children {
            if let key = child.label {
                if let writtenValue = child.value as? String {
                    dict[key] = writtenValue
                } else if let writtenValue = child.value as? Int {
                    dict[key] = String(writtenValue)
                } else if let writtenValue = child.value as? Date {
                    dict[key] = writtenValue.toDateTimeString
                } else if let writtenValue = child.value as? Bool {
                    dict[key] = writtenValue.description
                } else if let writtenValue = child.value as? DosageFrequency {
                    dict[key] = String(writtenValue.rawValue)
                }
            }
        }
        dict[Constants.TaskCarePlanUUID.userInfoKey] = Constants.TaskCarePlanUUID.medication.uuidString
        return dict
    }
    
    init(with dict: [String: String]) {
        id = UUID()
        name = ""
        dosage = 0
        dosageFrequency = .daily
        for keyValue in dict {
            switch keyValue.key {
            case "id":
                id = UUID(uuidString: keyValue.value)!
            case "name":
                name = keyValue.value
            case "dosage" :
                dosage = Int(keyValue.value)!
            case "hours" :
                hours = Int(keyValue.value)!
            case "dosageFrequency" :
                dosageFrequency = DosageFrequency(rawValue: Int(keyValue.value)!)!
            case "notificationFrequency" :
                notificationFrequency = DosageFrequency(rawValue:  Int(keyValue.value)!)!
            case "startDate" :
                startDate = keyValue.value.toDateTime
            case "endDate":
                endDate = keyValue.value.toDateTime
            case "titleSeparator":
                titleSeparator = keyValue.value
            case "isLastCell" :
                isLastCell = Bool(keyValue.value) ?? false
            case "description" :
                description = keyValue.value
            case "subtitle" :
                subtitle = keyValue.value
            default:
                continue
            }
        }
    }
}
