//
//  RKTasks.swift
//  OTFCardioBox
//
//  Created by Asad Nawaz on 23/02/2022.
//

import Foundation
import SwiftUI

struct RKTasks: UIViewControllerRepresentable {
    typealias UIViewControllerType = TaskListViewController

    func makeUIViewController(context: Context) -> TaskListViewController {
        return TaskListViewController()
    }

    func updateUIViewController(_ uiViewController: TaskListViewController, context: Context) {

    }
}
