//
//  RKList.swift
//  OTFCardioBox
//
//  Created by Asad Nawaz on 24/02/2022.
//

import SwiftUI

struct SurveysList: View {
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.surveysHeaderTitle ?? Constants.dataBucketSurveys)
                    .font(.otfheaderTitleFont)
                    .fontWeight(Font.otfheaderTitleWeight)
                    .foregroundColor(.otfHeaderColor)) {
            ForEach(TaskListRow.sections[0].rows, id: \.rawValue) { row in
                NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                    Text(String(describing: row))
                        .fontWeight(Font.otfFontWeight)
                }
                .font(Font.otfAppFont)
            }
            .listRowBackground(Color.otfCellBackground)
            .foregroundColor(.otfTextColor)
        }
    }
}

struct RKList_Previews: PreviewProvider {
    static var previews: some View {
        SurveysList()
    }
}

struct SurveyQuestionsList: View {
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.surveyQuestionHeaderTitle ?? "Survey Questions")
                    .font(.otfheaderTitleFont)
                    .fontWeight(Font.otfheaderTitleWeight)
                    .foregroundColor(.otfHeaderColor)) {
            ForEach(TaskListRow.sections[1].rows, id: \.rawValue) { row in

                NavigationLink(destination: (TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea())) {
                    Text(String(describing: row))
                        .fontWeight(Font.otfFontWeight)
                }
                .font(Font.otfAppFont)
            }
            .listRowBackground(Color.otfCellBackground)
            .foregroundColor(.otfTextColor)
        }
    }
}

struct OnboardingList: View {
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.onBoardingHeaderTitle ?? "Onboarding")
                    .font(.otfheaderTitleFont)
                    .fontWeight(Font.otfheaderTitleWeight)
                    .foregroundColor(.otfHeaderColor)) {
            ForEach(TaskListRow.sections[2].rows, id: \.rawValue) { row in
                NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                    Text(String(describing: row))
                        .fontWeight(Font.otfFontWeight)
                }
                .font(Font.otfAppFont)
            }
            .listRowBackground(Color.otfCellBackground)
            .foregroundColor(.otfTextColor)
        }
    }
}

struct ActiveTasksList: View {
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.activeTasksHeaderTitle ?? "Active Tasks")
                    .font(.otfheaderTitleFont)
                    .fontWeight(Font.otfheaderTitleWeight)
                    .foregroundColor(.otfHeaderColor)) {
            ForEach(TaskListRow.sections[3].rows, id: \.rawValue) { row in
                NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                    Text(String(describing: row))
                        .fontWeight(Font.otfFontWeight)
                }
            }
            .font(Font.otfAppFont)

            .listRowBackground(Color.otfCellBackground)
            .foregroundColor(.otfTextColor)
        }
    }
}

struct MiscellaneousList: View {
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.miscellaneousHeaderTitle ?? "Miscellaneous")
                    .font(.otfheaderTitleFont)
                    .fontWeight(Font.otfheaderTitleWeight)
                    .foregroundColor(.otfHeaderColor)) {
            ForEach(TaskListRow.sections[4].rows, id: \.rawValue) { row in
                NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                    Text(String(describing: row))
                        .fontWeight(Font.otfFontWeight)
                }
                .font(Font.otfAppFont)
            }
            .listRowBackground(Color.otfCellBackground)
            .foregroundColor(.otfTextColor)
        }
    }
}
