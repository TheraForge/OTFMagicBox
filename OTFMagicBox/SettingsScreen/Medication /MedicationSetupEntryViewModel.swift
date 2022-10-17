//
//  MedicationSetupEntryViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/29/22.
//

import Foundation
import OTFCareKit
import OTFCareKitStore

class MedicationSetupEntryViewModel: ObservableObject {
    @Published var isEditing: Bool
    @Published var cellModel: MedicationSetupCellModel
    
    var storeManager: OCKAnyStoreProtocol = OCKStoreManager.shared.synchronizedStoreManager.store
    
    
    init(isEditing: Bool, cellModel: MedicationSetupCellModel?) {
        self.isEditing = isEditing
        if let cellModel = cellModel {
            self.cellModel = cellModel
        } else {
            let newCellModel = MedicationSetupCellModel(name: "", dosage: 0, dosageFrequency: .daily)
            self.cellModel = newCellModel
        }
    }
    
    func save() {
        if isEditing {
            storeManager.updateAnyTask(makeTask(), callbackQueue: .main, completion: {result in switch result { case .failure(let error): print("Error happened Updating task: ", error.localizedDescription) case .success(_): print("success Edit")}})
        } else {
            storeManager.addAnyTask(makeTask(), callbackQueue: .main, completion: {result in switch result { case .failure(let error): print("Error happened Updating task: ", error.localizedDescription) case .success(_): print("success Save")}})
        }
    }
    
    private func makeTask() -> OCKTask {
        var dateComponentInterval: DateComponents?
        switch cellModel.dosageFrequency {
        case .hourly:
            dateComponentInterval = .init(hour: 1)
        case .daily:
            dateComponentInterval = .init(day: 1)
        case .weekly:
            dateComponentInterval = .init(day: 7)
        case .biweekly:
            dateComponentInterval = .init(day: 14)
        case .monthly:
            dateComponentInterval = .init(month: 1)
        }
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: Date(),
                end: nil,
                interval: dateComponentInterval!,
                text: nil,
                targetValues: [OCKOutcomeValue(1)],
                duration: .allDay
            )
        ])
        print("*** MAKING TASK ***")
        print("id: ", cellModel.id.uuidString)
        var stepsTask = OCKTask(id: cellModel.id.uuidString, title: "Take \(cellModel.dosage) of \(cellModel.name)", carePlanUUID: Constants.TaskCarePlanUUID.medication, schedule: schedule)
        stepsTask.instructions = cellModel.description
        var userInfoDict = cellModel.toUserInfoDict()
        userInfoDict[Constants.TaskCarePlanUUID.userInfoKey] = Constants.TaskCarePlanUUID.medication.uuidString
        stepsTask.userInfo = userInfoDict
        
        return stepsTask
    }
}