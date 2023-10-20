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
import OTFCareKitUI
import OTFCareKitStore

struct TaskSection: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().careKitModel?.taskHeader ?? "Task").font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
            ForEach(TaskStyle.allCases, id: \.rawValue) { style in
                if style.supportsSwiftUI || style.supportsUIKit {
                    
                    NavigationLink(destination: TaskDestination(style: style)) {
                        Text(style.rawValue.capitalized)
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    }
                    .foregroundColor(.otfTextColor)
                    .listRowBackground(Color.otfCellBackground)
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                }
            }
            .listRowBackground(Color(cellbackgroundColor))
            .foregroundColor(Color(textColor))
        }
    }
}

struct TaskDestination: View {
    
    @Environment(\.storeManager) private var storeManager
    
    let style: TaskStyle
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            if style.supportsSwiftUI && style.supportsUIKit {
                PlatformPicker {
                    AdaptedTaskView(style: style, storeManager: storeManager)
                } swiftUIView: {
                    if #available(iOS 14, *) {
                        TaskView(style: style)
                    }
                }
            } else if style.supportsUIKit {
                AdaptedTaskView(style: style, storeManager: storeManager)
            } else if style.supportsSwiftUI {
                if #available(iOS 14, *) {
                    TaskView(style: style)
                }
            }
        }
        .navigationBarTitle(Text(style.rawValue.capitalized).font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight), displayMode: .inline)
    }
}

enum TaskCategory: String, Codable {
    case medication, activity, checkup, appointment
}

enum TaskStyle: String, CaseIterable, Codable {
    
    case simple, instruction, buttonLog
    case grid, checklist
    case labeledValue = "labeled value", numericProgress = "Numeric Progress"
    
    
    var rawValue: String {
         get {
             switch self {
             case .simple:
                 return ModuleAppYmlReader().careKitModel?.simple ?? ""
             case .instruction:
                 return  ModuleAppYmlReader().careKitModel?.instruction ?? ""
             case .buttonLog:
                 return  ModuleAppYmlReader().careKitModel?.buttonLog ?? ""
             case .grid:
                 return  ModuleAppYmlReader().careKitModel?.grid ?? ""
             case .checklist:
                 return  ModuleAppYmlReader().careKitModel?.checklist ?? ""
             case .labeledValue:
                 return  ModuleAppYmlReader().careKitModel?.labeledValue ?? ""
             case .numericProgress:
                 return  ModuleAppYmlReader().careKitModel?.numericProgress ?? ""
             }
         }
     }
    
    var supportsSwiftUI: Bool {
        guard #available(iOS 14, *) else { return false }
        
        switch self {
        case .simple, .instruction, .labeledValue, .numericProgress: return true
        case .grid, .checklist, .buttonLog: return false
        }
    }
    
    var supportsUIKit: Bool {
        switch self {
        case .simple, .instruction, .grid, .checklist, .buttonLog: return true
        case .labeledValue, .numericProgress: return false
        }
    }
}

@available(iOS 14.0, *)
struct TaskView: View {
    
    @Environment(\.storeManager) private var storeManager
    
    let style: TaskStyle
    
    var body: some View {
        CardBackground {
            switch style {
            case .simple:
                OTFCareKit.SimpleTaskView(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                          eventQuery: .init(for: Date()), storeManager: storeManager)
            case .instruction:
                OTFCareKit.InstructionsTaskView(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                eventQuery: .init(for: Date()), storeManager: storeManager)
            case .numericProgress:
                VStack(spacing: 16) {
                    // Linked to HealthKit data
                    OTFCareKit.NumericProgressTaskView(taskID: OCKHealthKitPassthroughStore.Tasks.steps.rawValue,
                                                       eventQuery: .init(for: Date()), storeManager: storeManager) { controller in
                        OTFCareKitUI.NumericProgressTaskView(title: Text((controller.viewModel?.title ?? "") + " (HealthKit Linked)"),
                                                             detail: controller.viewModel?.detail.map(Text.init),
                                                             progress: Text(controller.viewModel?.progress ?? ""),
                                                             goal: Text(controller.viewModel?.goal ?? ""),
                                                             instructions: controller.viewModel?.instructions.map(Text.init),
                                                             isComplete: controller.viewModel?.isComplete ?? false)
                    }
                    
                    // Static view
                    OTFCareKitUI.NumericProgressTaskView(title: Text("Steps (Static)").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                                                         progress: Text("0"),
                                                         goal: Text("100"),
                                                         isComplete: false)
                    
                    // Static view
                    OTFCareKitUI.NumericProgressTaskView(title: Text("Steps (Static)").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                                                         progress: Text("0"),
                                                         goal: Text("100"),
                                                         isComplete: true)
                }
            case .labeledValue:
                VStack(spacing: 16) {
                    
                    // HealthKit linked view
                    OTFCareKit.LabeledValueTaskView(taskID: OCKHealthKitPassthroughStore.Tasks.steps.rawValue,
                                                    eventQuery: .init(for: Date()), storeManager: storeManager) { controller in
                        OTFCareKitUI.LabeledValueTaskView(title: Text((controller.viewModel?.title ?? "") + " (HealthKit Linked)"),
                                                          detail: controller.viewModel?.detail.map(Text.init),
                                                          state: .fromViewModel(state: controller.viewModel?.state))
                    }
                    
                    // Static view
                    LabeledValueTaskView(title: Text("Heart Rate (Static)").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0)),
                                         detail: Text("Anytime").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                                         state: .complete(Text("62"), Text("BPM")))
                    
                    // Static view
                    LabeledValueTaskView(title: Text("Heart Rate (Static)").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                                         detail: Text("Anytime").font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                                         state: .incomplete(Text("NO DATA")
                                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))))
                }
            default:
                EmptyView()
            }
        }
    }
}

struct AdaptedTaskView: UIViewControllerRepresentable {
    
    let style: TaskStyle
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()
        
        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)
        
        let taskViewController: UIViewController?
        switch style {
        case .simple:
            taskViewController = OCKSimpleTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                             eventQuery: .init(for: Date()), storeManager: storeManager)
        case .instruction:
            taskViewController = OCKInstructionsTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                                   eventQuery: .init(for: Date()), storeManager: storeManager)
        case .buttonLog:
            taskViewController = OCKButtonLogTaskViewController(taskID: OCKStore.Tasks.nausea.rawValue,
                                                                eventQuery: .init(for: Date()), storeManager: storeManager)
        case .checklist:
            taskViewController = OCKChecklistTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                                eventQuery: .init(for: Date()), storeManager: storeManager)
        case .grid:
            taskViewController = OCKGridTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                           eventQuery: .init(for: Date()), storeManager: storeManager)
        case .labeledValue, .numericProgress:
            taskViewController = nil
        }
        
        taskViewController.map { listViewController.appendViewController($0, animated: false) }
        return listViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private extension LabeledValueTaskViewState {
    
    static func fromViewModel(state: LabeledValueTaskViewModel.State?) -> Self {
        guard let state = state else {
            return .incomplete(Text(""))
        }
        
        switch state {
        case let .complete(value, label):
            return .complete(Text(value), label.map(Text.init))
        case let .incomplete(label):
            return .incomplete(Text(label))
        }
    }
}


struct TasksSection: View {
    @StateObject var viewModel: TasksViewModel
    
    var body: some View {
        List {
            Section(header: Text("Simple Task")
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))) {
                if let simpleTask = self.viewModel.simpleTask {
                    SimpleTaskView(task: simpleTask, date: Date(),
                                   storeManager: viewModel.syncStoreManager)
                }
            }
            
            Section(header: Text("Instruction Task")
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))) {
                if let instructionTask = self.viewModel.simpleTask {
                    InstructionTaskView(task: instructionTask, date: Date(),
                                        storeManager: viewModel.syncStoreManager)
                }
            }
            
            Section(header: Text("Button Log Task")
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))) {
                if let buttonLogTask = self.viewModel.buttonLogTask {
                    ButtonLogTaskView(task: buttonLogTask, date: Date(),
                                      storeManager: viewModel.syncStoreManager)
                }
            }
            
            Section(header: Text("Grid Task")
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))) {
                if let gridTask = self.viewModel.checklistTask {
                    GridTaskView(task: gridTask, date: Date(),
                                 storeManager: viewModel.syncStoreManager)
                }
            }
            
            Section(header: Text("Checklist Task")
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))) {
                if let checklistTask = self.viewModel.checklistTask {
                    ChecklistTaskView(task: checklistTask, date: Date(),
                                      storeManager: viewModel.syncStoreManager)
                }
            }
        }
        .listStyle(GroupedListStyle())
//        .onLoad {
//            UITableView.appearance().backgroundColor = YmlReader().appTheme?.backgroundColor.color
//            UITableViewCell.appearance().backgroundColor = YmlReader().appTheme?.backgroundColor.color
//            UITableView.appearance().separatorColor = YmlReader().appTheme?.separatorColor.color
//        }
    }
}

struct TasksSection_Preview: PreviewProvider {
    static var previews: some View {
        let viewModel = TasksViewModel(OCKStoreManager.shared.synchronizedStoreManager)
        let tasksSection = TasksSection(viewModel: viewModel)
        return tasksSection
    }
}
