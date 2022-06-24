//
//  RKList.swift
//  OTFCardioBox
//
//  Created by Asad Nawaz on 24/02/2022.
//

import SwiftUI

struct SurveysList: View {
    var body: some View {
        Section(header: Text("Surveys")) {
            ForEach(TaskListRow.sections[0].rows, id: \.rawValue) {
                NavigationLink(String(describing: $0), destination: TaskViewControllerRepresentable(task: $0.representedTask).navigationBarHidden(true).ignoresSafeArea())
            }
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
        Section(header: Text("Survey Questions")) {
            ForEach(TaskListRow.sections[1].rows, id: \.rawValue) {
                NavigationLink(String(describing: $0), destination: TaskViewControllerRepresentable(task: $0.representedTask).navigationBarHidden(true).ignoresSafeArea())
            }
        }
    }
}

struct OnboardingList: View {
    var body: some View {
        Section(header: Text("Onboarding")) {
            ForEach(TaskListRow.sections[2].rows, id: \.rawValue) {
                NavigationLink(String(describing: $0), destination: TaskViewControllerRepresentable(task: $0.representedTask).navigationBarHidden(true).ignoresSafeArea())
            }
        }
    }
}

struct ActiveTasksList: View {
    var body: some View {
        Section(header: Text("Active Tasks")) {
            ForEach(TaskListRow.sections[3].rows, id: \.rawValue) {
                NavigationLink(String(describing: $0), destination: TaskViewControllerRepresentable(task: $0.representedTask).navigationBarHidden(true).ignoresSafeArea())
            }
        }
    }
}

struct MiscellaneousList: View {
    var body: some View {
        Section(header: Text("Miscellaneous")) {
            ForEach(TaskListRow.sections[4].rows, id: \.rawValue) {
                NavigationLink(String(describing: $0), destination: TaskViewControllerRepresentable(task: $0.representedTask).navigationBarHidden(true).ignoresSafeArea())
            }
        }
    }
}
