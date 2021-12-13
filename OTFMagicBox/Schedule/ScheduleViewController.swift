//
//  ScheduleViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import OTFCareKit
import OTFCareKitStore
import UIKit
import SwiftUI

class ScheduleViewController: OCKDailyPageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Schedule"
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStoreChangeNotification(_:)),
                                               name: .databaseSuccessfllySynchronized, object: nil)
    }
    
    @objc private func didReceiveStoreChangeNotification(_ notification: Notification) {
        reload()
    }
    
    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {
        
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        storeManager.store.fetchAnyTasks(query: query, callbackQueue: .main) { result in
            switch result {
            case .failure(let error):
                print("Error: \(error)")
                
            case .success(let tasks):

                // Add a non-CareKit view into the list
                /*
                let tipTitle = "Customize your app!"
                let tipText = ""

                // Only show the tip view on the current date
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipView = TipView()
                    tipView.headerView.titleLabel.text = tipTitle
                    tipView.headerView.detailLabel.text = tipText
                    tipView.imageView.image = UIImage(named: "GraphicOperatingSystem")
                    listViewController.appendView(tipView, animated: false)
                }
                 */
                
                tasks.filter({ $0.id.contains("buttonLog") }).forEach { task in
                    let nauseaCard = OCKButtonLogTaskViewController(task: task, eventQuery: .init(for: date),
                                                                    storeManager: self.storeManager)
                    listViewController.appendViewController(nauseaCard, animated: false)
                }
            }
        }
    }
    
}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
