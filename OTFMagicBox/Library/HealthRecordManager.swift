/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
be used to endorse or promote products derived from this software without specific
prior written permission. No license is granted to the trademarks of the copyright
holders even if such marks are included in this software.

4. Commercial redistribution in any form requires an explicit license agreement with the
copyright holder(s). Please contact support@hippocratestech.com for further information
regarding licensing.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
 */

import Foundation
import HealthKit
import OTFCareKit
import OTFCareKitStore
import OTFUtilities

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
                    OTFError("An error occurred in uploading health record: %{public}@", error?.localizedDescription ?? "")
                    onCompletion?(false, error)
                    return
                }
                OTFLog("[HealthRecordsManager] upload() - sending %{public}@  sample(s)", samples.count)
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

