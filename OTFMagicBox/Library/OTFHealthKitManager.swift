//
//  OTFHealthKitManager.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 31/08/21.
//

import Foundation
import HealthKit

class OTFHealthKitManager : NSObject {
    
    fileprivate var hkTypesToReadInBackground: Set<HKQuantityType> = []
    
    private override init() {
        let healthKitData = YmlReader().healthKitDataToRead as Array
        for requestedHKType in healthKitData {
            let id = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifier" + requestedHKType.type)
            let hkType = HKQuantityType.quantityType(forIdentifier: id)
            hkTypesToReadInBackground.insert(hkType!)
        }
    }
    
    /// Query for HealthKit Authorization
    /// - Parameter completion: (success, error)
    func getHealthAuthorization(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        /* **************************************************************
         * customize HealthKit data that will be collected
         * in the background. Choose from any HKQuantityType:
         * https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier
         * *************************************************************/
       
        // handle authorization from the OS
        ActivityManager.shared.getHealthAuthorizaton(forTypes: hkTypesToReadInBackground) { (success, error) in
            if (success) {
                let frequency = YmlReader().backgroundReadFrequency

                if frequency == HKUpdateFrequency.daily.stringValue {
                    ActivityManager.shared.startHealthKitCollectionInBackground(withFrequency: .daily)
                } else if frequency == HKUpdateFrequency.weekly.stringValue {
                    ActivityManager.shared.startHealthKitCollectionInBackground(withFrequency: .weekly)
                } else if frequency == HKUpdateFrequency.hourly.stringValue {
                    ActivityManager.shared.startHealthKitCollectionInBackground(withFrequency: .hourly)
                } else {
                    ActivityManager.shared.startHealthKitCollectionInBackground(withFrequency: .immediate)
                }
            }
            completion(success, error)
        }
    }
}


extension HKUpdateFrequency {
    var stringValue: String {
        switch self {
        case .hourly:
            return "hourly"
        
        case .daily:
            return "daily"
        
        case .weekly:
            return "weekly"
        
        default:
            return "immediate"
        }
    }
}
