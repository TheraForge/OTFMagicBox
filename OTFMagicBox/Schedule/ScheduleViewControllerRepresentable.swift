//
//  ScheduleViewControllerRepresentable.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import OTFCareKitStore
import OTFCareKit
import Foundation
import UIKit
import SwiftUI
import ResearchKit

struct ScheduleViewControllerRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    
    func updateUIViewController(_ taskViewController: UIViewController, context: Context) {}
    func makeUIViewController(context: Context) -> UIViewController {
        let manager = CareKitManager.shared
        let vc = ScheduleViewController(storeManager: manager.synchronizedStoreManager)
        return UINavigationController(rootViewController: vc)
    }
    
}
