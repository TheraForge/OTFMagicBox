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

import HealthKit
import OTFUtilities

@objc protocol SyncDelegate : AnyObject {
    @objc optional func didSyncWalkTests()
    @objc optional func didSyncSurveys()
    @objc optional func didSyncEvents()
    @objc optional func didCompleteSync()
}

class HealthKitManager: SyncDelegate {
    
    static let shared = HealthKitManager()
    
    lazy var healthStore: HKHealthStore = HKHealthStore()
    
    fileprivate var queryLog = [String:Date]()
    fileprivate let queryLogMutex = NSLock()
    fileprivate let timeBetweenQueries: TimeInterval = 60 //in seconds
    
    var userAuthorizedHKOnDevice : Bool? {
        get {
            return UserDefaults.standard.value(forKey: Constants.UserDefaults.HKDataShare) as? Bool
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.HKDataShare)
           // CKSession.putSecure(value: String(newValue ?? false), forKey: Constants.UserDefaults.HKDataShare)
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(HealthKitManager.syncData), name: .dataSyncRequest, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .dataSyncRequest, object: nil)
    }
    
    public func getHealthKitAuth(forTypes types: Set<HKQuantityType>, _ completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: types) {
            [weak self] success, error in
            
            guard let strongSelf = self else { return }
            strongSelf.userAuthorizedHKOnDevice = success
            
            completion(success, error as NSError?)
        }
    }
    
    public func startBackgroundDelivery(forTypes types: Set<HKQuantityType>, withFrequency frequency: HKUpdateFrequency, _ completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        self.setUpBackgroundDeliveryForDataTypes(types: types, frequency: frequency, completion)
    }
    
    public func disableHealthKit(_ completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        healthStore.disableAllBackgroundDelivery { (success, error) in
            if let error = error {
                OTFError("Unable to disable HK background delivery %{public}@", error.localizedDescription)
            }
            completion?(success, error)
        }
    }
    
}

extension HealthKitManager {
    
    fileprivate func setUpBackgroundDeliveryForDataTypes(types: Set<HKQuantityType>, frequency: HKUpdateFrequency, _ completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {

        let dispatchGroup = DispatchGroup()
        
        for type in types {
            let query = HKObserverQuery(sampleType: type, predicate: nil, updateHandler: { [weak self] (query, completionHandler, error) in
                
                guard let strongSelf = self else {
                    completionHandler()
                    return
                }
               
                dispatchGroup.enter()
                strongSelf.backgroundQuery(forType: type, completionHandler: {
                    completionHandler()
                    dispatchGroup.leave()
                })
                
            })
            
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: { (success, error) in
                if let error = error {
                    OTFError("%{public}@", error.localizedDescription)
                }
                completion?(success, error)
            })
            
        }
        
        dispatchGroup.notify(queue: .main) {
            OTFLog("Task finished.")
        }

    }
    
    //TODO: (delete) running the old data collection solution as a baseline to compare new values
    @available(*, deprecated)
    fileprivate func cumulativeBackgroundQuery(forType type: HKQuantityType, completionHandler: @escaping ()->Void) {
        
        let supportedTypes = [HKQuantityTypeIdentifier.stepCount.rawValue, HKQuantityTypeIdentifier.flightsClimbed.rawValue, HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue]
        if (!supportedTypes.contains(type.identifier)) {
            OTFLog("No cumulative query will run for type %@", type.identifier)
            completionHandler()
            return
        }
        
        guard canQuery(forType: type) else {
            OTFLog("Cannot yet query for %@, please try again in a minute.", type.identifier)
            completionHandler()
            return
        }
        DispatchQueue.main.async { //run on main queue, which exists even if the app is 100% in the background.
        
            OTFLog("[DEPRECATED] cumulative querying for type %@", type.identifier)
            
        }
        
    }
    
    fileprivate func backgroundQuery(forType type: HKQuantityType, completionHandler: @escaping ()->Void) {
        
        guard canQuery(forType: type) else {
            OTFLog("Cannot yet query for %{public}@, please try again in a minute.", type.identifier)
            completionHandler()
            return
        }
        
        DispatchQueue.main.async { //run on main queue, which exists even if the app is 100% in the background.
            
            OTFLog("Querying for type %{public}@", type.identifier)
          
        }
        
    }

    fileprivate func canQuery(forType type: HKQuantityType) -> Bool {
        queryLogMutex.lock()
        defer { queryLogMutex.unlock() }
        
        let currentDate = Date()
        guard let lastQueryDate = queryLog[type.identifier] else {
            queryLog[type.identifier] = currentDate
            return true
        }
        
        if currentDate.addingTimeInterval(-timeBetweenQueries) >= lastQueryDate {
            queryLog[type.identifier] = currentDate
            return true
        }
        
        return false
    }
    
    @objc fileprivate func syncData(forHkTypes hkTypes: Set<HKQuantityType>) {
      
    }
    
}

