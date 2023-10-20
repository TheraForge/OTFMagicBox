//
//  RKList.swift
//  OTFCardioBox
//
//  Created by Asad Nawaz on 24/02/2022.
//

import SwiftUI

struct SurveysList: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.surveysHeaderTitle ?? Constants.dataBucketSurveys)
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
            ForEach(TaskListRow.sections[0].rows, id: \.rawValue) { row in
                NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                    Text(String(describing: row))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                }
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
            }
            .listRowBackground(Color(cellbackgroundColor))
            .foregroundColor(Color(textColor))
        }
    }
}

struct RKList_Previews: PreviewProvider {
    static var previews: some View {
        SurveysList(cellbackgroundColor: UIColor(), headerColor: UIColor(), textColor: UIColor())
    }
}

struct SurveyQuestionsList: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.surveyQuestionHeaderTitle ?? "Survey Questions")
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 13.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
                ForEach(TaskListRow.sections[1].rows, id: \.rawValue) { row in
                    
                    NavigationLink(destination: (TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea())) {
                        Text(String(describing: row))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    }
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                }
                .listRowBackground(Color(cellbackgroundColor))
                .foregroundColor(Color(textColor))
            }
    }
}

struct OnboardingList: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.onBoardingHeaderTitle ?? "Onboarding")
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
                ForEach(TaskListRow.sections[2].rows, id: \.rawValue) { row in
                    NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                        Text(String(describing: row))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    }
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                }
                .listRowBackground(Color(cellbackgroundColor))
                .foregroundColor(Color(textColor))
            }
    }
}

struct ActiveTasksList: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.activeTasksHeaderTitle ?? "Active Tasks")
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
                ForEach(TaskListRow.sections[3].rows, id: \.rawValue) { row in
                    NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                        Text(String(describing: row))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    }
                }
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                
                .listRowBackground(Color(cellbackgroundColor))
                .foregroundColor(Color(textColor))
            }
    }
}

struct MiscellaneousList: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().researchKitModel?.miscellaneousHeaderTitle ?? "Miscellaneous")
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
                ForEach(TaskListRow.sections[4].rows, id: \.rawValue) { row in
                    NavigationLink(destination: TaskViewControllerRepresentable(task: row.representedTask).navigationBarHidden(true).ignoresSafeArea()) {
                        Text(String(describing: row))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    }
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                }
                .listRowBackground(Color(cellbackgroundColor))
                .foregroundColor(Color(textColor))
            }
    }
}
