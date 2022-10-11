//
//  MedicationNotificationSetupViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/4/22.
//

import Foundation

class MedicationNotificationSetupViewModel: ObservableObject {
    @Published var cells: [MedicationSetupCellModel] = []
    var storeManager: OCKStoreManager = OCKStoreManager.shared
    
    
    func loadItems() {
        storeManager.coreDataStore.fetchTasks(completion: { [weak self] result in
            switch result {
            case .success(let tasks):
                let filteredTask = tasks.filter({$0.carePlanUUID == Constants.TaskCarePlanUUID.medication})
                for task in filteredTask {
                    self?.cells.append(MedicationSetupCellModel(with: task.userInfo!))
                }
            case .failure(let error):
                print("Error fetching tasks: ", error.errorDescription)
                self?.cells = [
                    MedicationSetupCellModel(name: "Dopamine antagonist", dosage: 2, dosageFrequency: .daily),
                    MedicationSetupCellModel(name: "Amantadine", dosage: 1,  dosageFrequency: .weekly),
                    MedicationSetupCellModel(name: "Anticholinergic", dosage: 1, dosageFrequency: .biweekly, isLastCell: true) ]
            }
        })
    }
}
