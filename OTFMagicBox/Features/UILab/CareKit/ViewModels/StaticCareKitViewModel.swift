/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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

import OTFUtilities
import OTFCareKitStore
import OTFTemplateBox
import Contacts

final class StaticCareKitViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName = "StaticCareKitConfiguration"
    }

    // MARK: - Publishers

    @Published private(set) var config: StaticCareKitConfiguration = .fallback
    @Published private(set) var views: [CareKitViewType] = []

    // MARK: - Properties

    private let decoder: OTFYAMLDecoding
    private let logger = OTFLogger.logger()

    // MARK: - Init

    init(decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine(), ockStore: OCKStore = OCKStoreManager.shared.coreDataStore) {
        self.decoder = decoder
        load()
        ockStore.add(contact: config.contact)
        ockStore.add(task: config.task)
    }

    // MARK: - Methods

    func load() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: StaticCareKitConfiguration.self)
        } catch {
            logger.error("StaticCareKit YAML decode error: \(error)")
            config = .fallback
        }
    }
}

// MARK: Helper
private extension OCKStore {

    func add(task: StaticTask) {
        let thisMorning = Calendar.current.startOfDay(for: Date())

        let schedules = task.schedules.map { schedule in

            let start = Calendar.current.date(byAdding: .hour, value: schedule.startHour, to: thisMorning) ?? Date()

            return OCKScheduleElement(
                start: start,
                end: nil,
                interval: DateComponents(day: schedule.intervalDay),
                text: schedule.text.localized.isEmpty ? schedule.text.localized : nil,
                targetValues: [],
                duration: .allDay
            )
        }

        var ockTask = OCKTask(id: task.id, title: task.title.localized, carePlanUUID: nil, schedule: OCKSchedule(composing: schedules))
        ockTask.instructions = task.instructions.localized
        ockTask.asset = task.asset
        ockTask.impactsAdherence = task.impactsAdherence

        addTasks([ockTask])
    }

    func add(contact: StaticContact) {
        var contact1 = OCKContact(id: contact.id, givenName: contact.name, familyName: contact.surname, carePlanUUID: nil)
        contact1.asset = contact.asset
        contact1.title = contact.title
        contact1.role = contact.role.localized
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: contact.email)]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: contact.phoneNumber)]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: contact.phoneNumber)]

        contact1.address = {
            let address = OCKPostalAddress()
            address.street = contact.address.street
            address.city = contact.address.city
            address.state = contact.address.state
            address.postalCode = contact.address.postalCode
            return address
        }()

        addContacts([contact1])
    }
}
