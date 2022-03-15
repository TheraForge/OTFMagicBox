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

import SwiftUI
import OTFCareKit
import OTFCareKitStore

// MARK: - Instruction Task View
struct InstructionTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKInstructionsTaskViewController
    
    let task: OCKAnyTask
    let date: Date
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIViewController(context: Context) -> OCKInstructionsTaskViewController {
        let instructionCard = OCKInstructionsTaskViewController(task: task, eventQuery: .init(for: date), storeManager: storeManager)
        return instructionCard
    }
    
    func updateUIViewController(_ uiViewController: OCKInstructionsTaskViewController, context: Context) {}
}

struct InstaructionTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let instructionTask = InstructionTaskView(task: dummyTask,
                                                  date: Date(),
                                                  storeManager: storeManager)
        return instructionTask
    }
}

// MARK: - Grid Task View
struct GridTaskView: UIViewRepresentable {
    let task: OCKAnyTask
    let date: Date
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIView(context: Context) -> some UIView {
        let gridCard = OCKGridTaskViewController(task: task, eventQuery: .init(for: date), storeManager: storeManager)
        return gridCard.view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct GridTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let gridTask = GridTaskView(task: dummyTask, date: Date(),
                                    storeManager: storeManager)
        return gridTask
    }
}

// MARK: - Simple Task View
struct SimpleTaskView: UIViewRepresentable {
    let task: OCKAnyTask
    let date: Date
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIView(context: Context) -> some UIView {
        let simpleCard = OCKSimpleTaskViewController(task: task, eventQuery: .init(for: date), storeManager: storeManager)
        return simpleCard.view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct SimpleTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let simpleTask = SimpleTaskView(task: dummyTask,
                                        date: Date(),
                                        storeManager: storeManager)
        return simpleTask
    }
}

// MARK: - Checklist Task View
struct ChecklistTaskView: UIViewRepresentable {
    let task: OCKAnyTask
    let date: Date
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIView(context: Context) -> some UIView {
        let checklistCard = OCKChecklistTaskViewController(task: task, eventQuery: .init(for: date), storeManager: storeManager)
        return checklistCard.view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct ChecklistTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let checklistTask = InstructionTaskView(task: dummyTask,
                                                date: Date(),
                                                storeManager: storeManager)
        return checklistTask
    }
}

// MARK: - Checklist Task View
struct ButtonLogTaskView: UIViewRepresentable {
    let task: OCKAnyTask
    let date: Date
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIView(context: Context) -> some UIView {
        let buttonLogCard = OCKButtonLogTaskViewController(task: task, eventQuery: .init(for: date), storeManager: storeManager)
        return buttonLogCard.view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct ButtonLogTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let buttonLogCard = ButtonLogTaskView(task: dummyTask, date: Date(), storeManager: storeManager)
        return buttonLogCard
    }
}

// MARK: - Dummy Data
var dummyTask: OCKAnyTask {
    let calendar = Calendar.current
    let thisMorning = calendar.startOfDay(for: Date())
    let aFewDaysAgo = calendar.date(byAdding: .day, value: -4,
                                    to: thisMorning)!
    let beforeBreakfast = calendar.date(byAdding: .hour,
                                        value: 8,
                                        to: aFewDaysAgo)!
    let afterLunch = calendar.date(byAdding: .hour, value: 14,
                                   to: aFewDaysAgo)!
    let schedule = OCKSchedule(composing: [
        OCKScheduleElement(start: beforeBreakfast, end: nil,
                           interval: DateComponents(day: 1)),

        OCKScheduleElement(start: afterLunch, end: nil,
                           interval: DateComponents(day: 2))
    ])
    let task = OCKTask(id: OCKStore.Tasks.doxylamine.rawValue,
                       title: OCKStore.Tasks.doxylamine.rawValue,
                       carePlanUUID: nil, schedule: schedule)
    
    return task
}

var storeManager: OCKSynchronizedStoreManager {
    OCKStoreManager.shared.synchronizedStoreManager
}
