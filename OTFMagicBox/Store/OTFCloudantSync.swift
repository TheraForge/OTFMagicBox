//
//  OTFCloudantSync.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 27/10/21.
//

import Foundation
import OTFCDTDatastore
import OTFCloudantStore
import OTFCareKitStore
import OTFCareKit
import OTFCareKitUI

class OTFCloudantSync {
    
    static let shared = OTFCloudantSync()
    var patientId = String()
    
    private init() {
        
    }
    
    func updatePatient(firstName: String, lastName: String, gender:String, dob: Date, completionHandler: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        var patient =  OCKPatient(id: UUID().uuidString, givenName: firstName, familyName: lastName)
        patient.birthday = dob
        patient.sex = OCKBiologicalSex(rawValue: gender)
        
        do {
            try StoreService.shared.currentStore().updatePatients([patient], completion: { (result) in
                print(result)
                switch result {
                case .success(let response):
                    print(response)
                    for data in response {
                        self.patientId = data.id
                        
                        guard let gender = data.sex?.rawValue else {
                            return
                        }
                        
                        guard let dob = data.birthday?.toString() else {
                            return
                        }
                        
                        UserDefaults.standard.set(data.name.givenName, forKey: Constants.UserDefaults.patientFirstName)
                        UserDefaults.standard.set(data.name.familyName, forKey: Constants.UserDefaults.patientLastName)
                        UserDefaults.standard.set(gender, forKey: Constants.UserDefaults.patientGender)
                        UserDefaults.standard.set(dob, forKey: Constants.UserDefaults.patientDob)
                    }
                case .failure(let error):
                    print(error)
                }
                completionHandler?(result)
            })
        } catch {
            print("error: \(error)")
        }
  
    }
    
    func fetchPatientData(id: String) {
        do {
            try StoreService.shared.currentStore().fetchPatients(query: OCKPatientQuery(id: id)) { (result) in
                switch result {
                case .success(_):
                    break
                case .failure(_):
                    break
                }
            }
        } catch {
            print("Can't get the document id.")
            return
        }
    }
    
}
