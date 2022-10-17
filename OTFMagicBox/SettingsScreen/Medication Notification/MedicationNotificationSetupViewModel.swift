//
//  MedicationNotificationSetupViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/4/22.
//

import Foundation
import OTFCareKitStore

class MedicationNotificationSetupViewModel: ObservableObject {
    @Published var cells: [MedicationSetupCellModel] = []
    var storeManager: OCKAnyStoreProtocol = OCKStoreManager.shared.synchronizedStoreManager.store
    
    
    func loadItems() {
        print("LOAD ITEMS MED NOTIF SETUP")
        let fromDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
        let toDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
        let interval = DateInterval(start: fromDate!, end: toDate!)
        let query = OCKTaskQuery(dateInterval: interval)
        
        storeManager.fetchAnyTasks(query: query, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tasks):
                print("success: ", tasks.debugDescription)
                let filteredTask = tasks.filter({($0 as? OCKTask)?.userInfo?.contains(where: {$0.value == Constants.TaskCarePlanUUID.medication.uuidString }) ?? false })
                for task in filteredTask {
                    let medicationCell = MedicationSetupCellModel(with: (task as! OCKTask).userInfo!)
                    if let index = self.cells.firstIndex(where: {$0.id == medicationCell.id}) {
                        self.cells[index] = medicationCell
                    } else {
                        self.cells.append(medicationCell)
                    }
                }
            case .failure(let error):
                print("Error fetching tasks: ", error.errorDescription)
                self.cells = [
                    MedicationSetupCellModel(name: "Dopamine antagonist", dosage: 2, dosageFrequency: .daily),
                    MedicationSetupCellModel(name: "Amantadine", dosage: 1,  dosageFrequency: .weekly),
                    MedicationSetupCellModel(name: "Anticholinergic", dosage: 1, dosageFrequency: .biweekly, isLastCell: true) ]
            }
        }
    }
}
