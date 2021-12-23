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

class OTFHealthKitManager : NSObject {
    
    public static let shared = OTFHealthKitManager()
    
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
