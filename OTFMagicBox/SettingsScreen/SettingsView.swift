//
//  SettingsView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/24/22.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var body: some View {
        VStack(spacing: 0) {
            MainHeaderView(title: "Settings")
                .frame(height: 90)
            List {
                ForEach(viewModel.settingsCells) { sectionCells in
                    Section(header: EmptyView(), footer: EmptyView()) {
                        ForEach(sectionCells.cells) { cell in
                            VStack {
                                NavigationLink(destination: getDestinationView(for: cell.navigationDestination), tag: cell.navigationDestination.rawValue, selection: $viewModel.navigationDestinationValue) { EmptyView() }.opacity(0)
                                SettingCell(settingCell: cell).listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                            .frame(height: 60)
                            .onTapGesture {
                                viewModel.didSelectRow(at: cell.navigationDestination.rawValue)
                            }
                        }
                    }
                }
            }.listStyle(.grouped)
        }
        Spacer()
        .onAppear() {
            viewModel.loadItems()
            UITableView.appearance().separatorColor = .clear
        }
    }
    
    @ViewBuilder
    func getDestinationView(for navigationDestination: SettingsNavigation) -> some View {
        switch navigationDestination {
        case .medicationSetup:
            MedicationSetupView(viewModel: MedicationSetupViewModel()).navigationTitle("").navigationBarHidden(true)
        case .medicationNotificationSetup:
            MedicationNotificationSetupView(viewModel: MedicationNotificationSetupViewModel()).navigationTitle("").navigationBarHidden(true)
        case .surveyReminderSetup:
            SurveyReminderSetupView(viewModel: SurveyReminderSetupViewModel()).navigationTitle("").navigationBarHidden(true)
        case .fogSetup:
            SetupFogView(viewModel: SetupFogViewModel()).navigationTitle("").navigationBarHidden(true)
        case .fogTimerSetup:
            FogTimerView(viewModel: FogTimerViewModel()).navigationTitle("").navigationBarHidden(true)
        default:
            Text("\(navigationDestination.rawValue)")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
