//
//  HealthKitManager.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 31/08/21.
//

import HealthKit

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
        NotificationCenter.default.addObserver(self, selector: #selector(HealthKitManager.syncData), name: NSNotification.Name(rawValue: Constants.Notification.DataSyncRequest), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.DataSyncRequest),
                                                  object: nil)
    }
    
    public func getHealthKitAuth(forTypes types: Set<HKQuantityType>, _ completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
      /*  guard HKHealthStore.isHealthDataAvailable() && SessionManager.shared.userId != nil else {
            let error = NSError(domain: Constants.app, code: 2, userInfo: [NSLocalizedDescriptionKey: "Health data is not available on this device."])
            completion(false, error)
            return
        } */
        
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
                OTFError("Unable to disable HK background delivery %@", error.localizedDescription)
            }
            completion?(success, error)
        }
    }
    
}

extension HealthKitManager {
    
    fileprivate func setUpBackgroundDeliveryForDataTypes(types: Set<HKQuantityType>, frequency: HKUpdateFrequency, _ completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {

        for type in types {
            let query = HKObserverQuery(sampleType: type, predicate: nil, updateHandler: { [weak self] (query, completionHandler, error) in
                
                guard let strongSelf = self else {
                    completionHandler()
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                strongSelf.backgroundQuery(forType: type, completionHandler: {
                    dispatchGroup.leave()
                })
                
                dispatchGroup.notify(queue: .main, execute: {
                    completionHandler()
                })
                
            })
            
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: { (success, error) in
                if let error = error {
                    OTFError("%@", error.localizedDescription)
                }
                completion?(success, error)
            })
            
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

