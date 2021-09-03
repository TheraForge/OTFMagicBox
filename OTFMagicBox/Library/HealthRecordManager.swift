//
//  HealthRecordManager.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 03/09/21.
//

import Foundation
import HealthKit
import OTFCareKit
import OTFCareKitStore

class HealthRecordsManager: NSObject {
    
    static let shared = HealthRecordsManager()
    
    lazy var healthStore = HKHealthStore()
    
    fileprivate let typesById: [HKClinicalTypeIdentifier] = [
        .allergyRecord, // HKClinicalTypeIdentifierAllergyRecord
        .conditionRecord, // HKClinicalTypeIdentifierConditionRecord
        .immunizationRecord, // HKClinicalTypeIdentifierImmunizationRecord
        .labResultRecord, // HKClinicalTypeIdentifierLabResultRecord
        .medicationRecord, // HKClinicalTypeIdentifierMedicationRecord
        .procedureRecord, // HKClinicalTypeIdentifierProcedureRecord
        .vitalSignRecord // HKClinicalTypeIdentifierVitalSignRecord
    ]
    
    fileprivate var types = Set<HKClinicalType>()
    
    override init() {
        super.init()
        for id in typesById {
            print(id.rawValue)
            guard let record = HKObjectType.clinicalType(forIdentifier: id) else { continue }
            types.insert(record)
        }
    }
    
    func getAuth(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: types) { (success, error) in
            completion(success, error)
        }
    }
    
    func upload(_ onCompletion: ((Bool, Error?) -> Void)? = nil) {
        for type in types {
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                
                guard let samples = samples as? [HKClinicalRecord] else {
                    print("*** An error occurred: \(error?.localizedDescription ?? "nil") ***")
                    onCompletion?(false, error)
                    return
                }
                
                print("[HealthRecordsManager] upload() - sending \(samples.count) sample(s)")
                for sample in samples {
                    guard let resource = sample.fhirResource else { continue }
                        _ = resource.data
                        _ = resource.resourceType.rawValue + "-" + resource.identifier
                }
                
                UserDefaults.standard.set(Date(), forKey: Constants.prefHealthRecordsLastUploaded)
                onCompletion?(true, nil)
            }
            healthStore.execute(query)
        }
    }
    
}

