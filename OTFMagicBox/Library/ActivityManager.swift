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

public class ActivityManager: NSObject {

    public static let shared = ActivityManager()

    override public init() {
        super.init()

        _ = HealthKitManager.shared
    }

    public func load() {
        guard hasGrantedAuth && !typesToCollect.isEmpty else {
            return
        }

        getHealthAuthorizaton(forTypes: self.typesToCollect) { [weak self] (success, _) in
            if success {
                self?.startHealthKitCollectionInBackground(withFrequency: .hourly)
            }
        }
    }

    public func getHealthAuthorizaton(forTypes typesToCollect: Set<HKQuantityType>, _ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.typesToCollect = typesToCollect
        HealthKitManager.shared.getHealthKitAuth(forTypes: self.typesToCollect) { [weak self] (success, error) in
            self?.hasGrantedAuth = success
            completion(success, error)
        }
    }

    public func startHealthKitCollectionInBackground(fromStartDate startDate: Date? = nil, withFrequency frequency: HKUpdateFrequency, _ completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {

        // check for auth
        guard hasGrantedAuth else {
            let error = NSError(domain: Constants.app, code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot startHealthKitCollection without getting auth permissions first."])
            completion?(false, error)
            return
        }

        // record beginning of data collection
        if let startDate = startDate {
            UserDefaults.standard.set(startDate, forKey: Constants.UserDefaults.HKStartDate)
        }

        // and get health authorization
        HealthKitManager.shared.startBackgroundDelivery(forTypes: typesToCollect, withFrequency: frequency) { [weak self] (success, error) in
            self?.hasStartedCollection = success
            completion?(success, error)
        }
    }

    public func stopHealthKitCollection() {
        HealthKitManager.shared.disableHealthKit { [weak self] (success, _) in
            if success { // disable successfully
                self?.hasStartedCollection = false // we have disabled
            }
        }
    }

    fileprivate let keyHasStartedCollection = "hasStartedCollection"
    fileprivate let keyHasGrantedAuth = "hasGrantedAuth"
    fileprivate let keyTypesToCollect = "typesToCollect"

    fileprivate var hasStartedCollection: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyHasStartedCollection)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHasStartedCollection)
        }
    }

    fileprivate var hasGrantedAuth: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyHasGrantedAuth)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHasGrantedAuth)
        }
    }

    fileprivate var _typesToCollect = Set<HKQuantityType>()
    fileprivate var typesToCollect: Set<HKQuantityType> {
        get {
            if !_typesToCollect.isEmpty {
                return _typesToCollect
            }

            guard let typeIds = UserDefaults.standard.array(forKey: keyTypesToCollect) as? [String] else {
                return Set<HKQuantityType>() // no types to process
            }

            var types = Set<HKQuantityType>()
            for type in typeIds {
                let type = HKQuantityTypeIdentifier(rawValue: type)
                if let parsedType = HKQuantityType.quantityType(forIdentifier: type) {
                    types.insert(parsedType)
                }
            }

            if !types.isEmpty {
                _typesToCollect = types
            }
            return types
        }
        set {
            var typeIds = [String]()
            for type in newValue {
                typeIds.append(type.identifier)
            }
            UserDefaults.standard.set(typeIds, forKey: keyTypesToCollect)
            _typesToCollect = newValue
        }
    }

}
