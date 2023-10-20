//
//  CareKitListView.swift
//  OTFMagicBox Watch Watch App
//
//  Created by Tomas Martins on 13/09/23.
//

import SwiftUI
import Contacts
import OTFCareKit
import OTFCareKitUI
import OTFCareKitStore

struct CareKitListView: View {
    @ObservedObject var storeManager: OCKStoreManager = .shared
    @State var tasks: [OCKTask] = []
    
    var body: some View {
        List {
            if tasks.isEmpty {
                emptyState
            } else {
                ForEach(tasks, id: \.id) { task in
                    SimpleTaskView(isComplete: false) {
                        Text(task.title ?? "No title for task")
                    }
                }
            }
        }
        .task {
            await fetchTasksAsync()
        }
        .refreshable {
            await fetchTasksAsync()
        }
    }
    
    func fetchTasksAsync() async {
        await withCheckedContinuation { continuation in
            Task {
                storeManager.coreDataStore.populateSampleData()
                storeManager.coreDataStore.fetchTasks { result in
                    switch result {
                    case .success(let success):
                        self.tasks = success
                        continuation.resume()
                    case .failure(let error):
                        dump(error)
                        self.tasks = []
                        continuation.resume()
                    }
                }
            }
        }
    }

    var emptyState: some View {
        SimpleTaskView(title: Text(Constants.CustomiseStrings.noTasks),
                       detail: Text(Constants.CustomiseStrings.noTasksForThisDate),
                       isComplete: false)
    }
}

struct CareKitListView_Previews: PreviewProvider {
    static var previews: some View {
        CareKitListView()
    }
}

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
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!
        
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
