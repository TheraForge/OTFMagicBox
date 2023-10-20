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

import OTFCareKit
import OTFCareKitStore
import UIKit
import OTFUtilities
import SwiftUI

class ScheduleViewController: OCKDailyPageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.CustomiseStrings.schedule
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStoreChangeNotification(_:)),
                                               name: .databaseSuccessfllySynchronized, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteProfileEventNotification(_:)),
                                               name: .deleteUserAccount, object: nil)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .deleteUserAccount, object: nil)
    }
    
    @objc private func didReceiveStoreChangeNotification(_ notification: Notification) {
        reload()
    }
    
    @objc private func deleteProfileEventNotification(_ notification: Notification) {
        
        self.alertWithAction(title: Constants.CustomiseStrings.accountDeleted, message: Constants.deleteAccount) { action in
            OTFTheraforgeNetwork.shared.moveToOnboardingView()
        }
        
    }
    
    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {
        
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        DispatchQueue.global(qos: .default).async { [unowned self] in
            storeManager.store.fetchAnyTasks(query: query, callbackQueue: .main) { result in
                switch result {
                case .failure(let error):
                    OTFError("error in fetching fetchAnyTasks %{public}@", error.localizedDescription)
                    
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
                    
                    // Filter the tasks that exist on the given date
                    let todayTasks = tasks.filter({ $0.schedule.exists(onDay: date) })
                    
                    // If there's no task on the given date then show no tasks card
                    guard !todayTasks.isEmpty else {
                        let tipTitle = Constants.CustomiseStrings.noTasks
                        let tipText = Constants.CustomiseStrings.noTasksForThisDate
                        let tipView = TipView()
                        tipView.headerView.titleLabel.text = tipTitle
                        tipView.headerView.detailLabel.text = tipText
                        listViewController.appendView(tipView, animated: false)
                        return
                    }
                    
                    todayTasks.forEach { task in
                        guard task.schedule.exists(onDay: date) else { return }
                        if task.viewType == .instruction {
                            let instructionCard = OCKInstructionsTaskViewController(task: task, eventQuery: .init(for: date),
                                                                                    storeManager: self.storeManager)
                            listViewController.appendViewController(instructionCard, animated: false)
                        } else if task.viewType == .grid {
                            let gridCard = OCKGridTaskViewController(task: task, eventQuery: .init(for: date),
                                                                     storeManager: self.storeManager)
                            listViewController.appendViewController(gridCard, animated: false)
                        } else if task.viewType == .buttonLog {
                            let buttonLogCard = OCKButtonLogTaskViewController(task: task, eventQuery: .init(for: date),
                                                                               storeManager: self.storeManager)
                            listViewController.appendViewController(buttonLogCard, animated: false)
                        } else if task.viewType == .checklist {
                            let checklistCard = OCKChecklistTaskViewController(task: task, eventQuery: .init(for: date),
                                                                               storeManager: self.storeManager)
                            listViewController.appendViewController(checklistCard, animated: false)
                        } else {
                            let simpleCard = OCKSimpleTaskViewController(task: task, eventQuery: .init(for: date),
                                                                         storeManager: self.storeManager)
                            listViewController.appendViewController(simpleCard, animated: false)
                        }
                    }
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
