//
//  MedicationNotificationSetupEntryViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/5/22.
//

import Foundation
import OTFCareKit
import OTFCareKitStore

class MedicationNotificationSetupEntryViewModel: ObservableObject {
    @Published var isEditing: Bool
    @Published var cellModel: MedicationSetupCellModel
    @Published var medications: [MedicationSetupCellModel]
    var selectedMedication: MedicationSetupCellModel?
    
    var storeManager: OCKAnyStoreProtocol = OCKStoreManager.shared.synchronizedStoreManager.store
    
    init(isEditing: Bool, cellModel: MedicationSetupCellModel?, medications: [MedicationSetupCellModel]) {
        self.isEditing = isEditing
        if let cellModel = cellModel {
            self.cellModel = cellModel
        } else {
            let newCellModel = MedicationSetupCellModel(name: "", dosage: 0, dosageFrequency: .daily)
            self.cellModel = newCellModel
        }
        self.medications = medications
        self.selectedMedication = medications.first
    }
    
    func save() {
        print("SAVE MED NOTIF SETUP ENTRY")
        if isEditing {
            storeManager.updateAnyTask(makeTask(), callbackQueue: .main, completion: {result in switch result { case .failure(let error): print("Error happened Updating task: ", error.localizedDescription) case .success( _): print("success Edit")}})
        } else {
            storeManager.addAnyTask(makeTask(), callbackQueue: .main, completion: {result in switch result { case .failure(let error): print("Error happened Updating task: ", error.localizedDescription) case .success( _): print("success Save")}})
        }
    }
    
    func deleteSelected() {
        storeManager.deleteAnyTask(makeTask(), callbackQueue: .main, completion: {result in switch result { case .failure(let error): print("Error happened Deleting task: ", error.localizedDescription) case .success( _): print("success Delete")}})
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
        print("id: ", cellModel.id.uuidString)
        if let selectedMedication = selectedMedication {
            print("SELECTED MEDICATION: ", selectedMedication.description)
            cellModel.name = selectedMedication.name
            cellModel.dosage = selectedMedication.dosage
            cellModel.dosageFrequency = selectedMedication.dosageFrequency
            cellModel.description = selectedMedication.description
            cellModel.subtitle = selectedMedication.subtitle
        }
        var stepsTask = OCKTask(id: cellModel.id.uuidString, title: "Take \(cellModel.dosage) of \(cellModel.name)", carePlanUUID: Constants.TaskCarePlanUUID.medicationNotification, schedule: schedule)
        stepsTask.instructions = cellModel.description
        var userInfoDict = cellModel.toUserInfoDict()
        userInfoDict[Constants.TaskCarePlanUUID.userInfoKey] = Constants.TaskCarePlanUUID.medicationNotification.uuidString
        stepsTask.userInfo = userInfoDict
        
        return stepsTask
    }
}
