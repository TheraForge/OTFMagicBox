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

import OTFCareKit
import OTFCareKitStore
import OTFCloudantStore
import Contacts
#if HEALTH
import HealthKit
#endif

internal extension OCKStore {
    
    enum Tasks: String, CaseIterable {
        case doxylamine
        case nausea
        case kegels
    }
    
    enum Contacts: String, CaseIterable {
        case jane
        case matthew
    }
    
    // Adds tasks and contacts into the store
    func populateSampleData() {
        
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: thisMorning)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: thisMorning)!
        
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1)),
            
            OCKScheduleElement(start: afterLunch, end: nil,
                               interval: DateComponents(day: 2))
        ])
        
        var doxylamine = OCKTask(id: Tasks.doxylamine.rawValue, title: "Take Doxylamine",
                                 carePlanUUID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."
        doxylamine.asset = "pills"
        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], duration: .allDay)
        ])
        
        var nausea = OCKTask(id: Tasks.nausea.rawValue, title: "Track your nausea",
                             carePlanUUID: nil, schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."
        
        let kegelElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 2))
        let kegelSchedule = OCKSchedule(composing: [kegelElement])
        var kegels = OCKTask(id: Tasks.kegels.rawValue, title: "Kegel Exercises", carePlanUUID: nil, schedule: kegelSchedule)
        kegels.impactsAdherence = true
        kegels.instructions = "Perform kegel exercies"
        
        addTasks([nausea, doxylamine, kegels], callbackQueue: .main, completion: nil)
        
        var contact1 = OCKContact(id: Contacts.jane.rawValue, givenName: "Jane",
                                  familyName: "Daniels", carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@icloud.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        
        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2598 Reposa Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        var contact2 = OCKContact(id: Contacts.matthew.rawValue, givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "396 El Verano Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        addContacts([contact1, contact2])
    }
}

extension OCKHealthKitPassthroughStore {
#if HEALTH
    func populateSampleData() {
        
        let schedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil,
            duration: .hours(12), targetValues: [OCKOutcomeValue(2000.0, units: "Steps")])
        
        let steps = OCKHealthKitTask(
            id: "steps",
            title: "Steps",
            carePlanUUID: nil,
            schedule: schedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: .count()))
        
        addTasks([steps]) { result in
            switch result {
            case .success:
                OTFLog("Added tasks into HealthKitPassthroughStore!")
            case .failure(let error):
                OTFError("Error:", error.errorDescription)
            }
        }
    }
#endif
}


#if DEBUG
extension OTFCloudantStore {
    // Adds tasks and contacts into the store
    func populateSampleData() {
        
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!
        
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1)),
            
            OCKScheduleElement(start: afterLunch, end: nil,
                               interval: DateComponents(day: 2))
        ])
        
        var doxylamine = OCKTask(id: "doxylamine", title: "Take Doxylamine",
                                 carePlanUUID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."
        doxylamine.asset = "pills"
        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], duration: .allDay)
        ])
        
        var nausea = OCKTask(id: "nausea", title: "Track your nausea",
                             carePlanUUID: nil, schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."
        
        let kegelElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 2))
        let kegelSchedule = OCKSchedule(composing: [kegelElement])
        var kegels = OCKTask(id: "kegels", title: "Kegel Exercises", carePlanUUID: nil, schedule: kegelSchedule)
        kegels.impactsAdherence = true
        kegels.instructions = "Perform kegel exercies"
        
        let checkInSchedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0,
            start: Date(), end: nil,
            text: nil
        )
        
        let checkInTask = OCKTask(
            id: "checkIn",
            title: "Check In",
            carePlanUUID: nil,
            schedule: checkInSchedule
        )
        
        let nextWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: Date()
        )!
        
        let nextMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: thisMorning
        )
        
        let dailyElement = OCKScheduleElement(
            start: thisMorning,
            end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        
        let weeklyElement = OCKScheduleElement(
            start: nextWeek,
            end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        
        let rangeOfMotionCheckSchedule = OCKSchedule(
            composing: [dailyElement, weeklyElement]
        )
        
        let rangeOfMotionCheckTask = OCKTask(
            id: "rangeOfMotionCheck",
            title: "Range Of Motion",
            carePlanUUID: nil,
            schedule: rangeOfMotionCheckSchedule
        )
        
        addAnyTasks([nausea, doxylamine, kegels, checkInTask, rangeOfMotionCheckTask],
                    callbackQueue: .main, completion: nil)
        
        var contact1 = OCKContact(id: "jane", givenName: "Jane",
                                  familyName: "Daniels", carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@icloud.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        
        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2598 Reposa Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        var contact2 = OCKContact(id: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "396 El Verano Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        addContacts([contact1, contact2])
    }
    
    @discardableResult func convertUserToPatient(user: Response.User) -> OCKPatient? {
        var patient = OCKPatient(id: user.id, givenName: user.firstName ?? "", familyName: user.lastName ?? "")
        patient.uuid = UUID()
        patient.birthday = user.dateOfBirth
        patient.remoteID = user.email
        patient.sex = (user.gender == .male) ? .male : .female
        addPatient(patient)
        return patient
    }
}

extension CareKitManager {
    func populateSampleData() {
        OCKStoreManager.shared.coreDataStore.fetchTasks { result in
            switch result {
            case .success(let success):
                storeManager.store.addAnyTasks(success, callbackQueue: .main, completion: nil)
            case .failure(_):
                break
            }
        }
    }
}
#endif

import OTFCloudClientAPI

extension OTFCloudantStore {
    func getThisPatient(_ completion: @escaping OCKResultClosure<OCKPatient>) {
        guard let user = TheraForgeKeychainService.shared.loadUser() else {
            completion(.failure(.fetchFailed(reason: "User not logged in.")))
            return
        }
        CareKitManager.shared.cloudantStore?.fetchPatient(withID: user.id, completion: { result in
            completion(result)
        })
    }
}
