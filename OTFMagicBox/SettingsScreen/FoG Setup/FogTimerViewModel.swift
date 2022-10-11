//
//  FogTimerViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import Foundation
import NotificationCenter

class FogTimerViewModel: ObservableObject {
    @Published var notificationsTurnedOn: Bool
    @Published var repetationDate: Date
    
    init(){
        notificationsTurnedOn = FogTimerHelper.shared.notificationsTurnedOn
        repetationDate = FogTimerHelper.shared.repetationDate ?? Date()
    }
    
    func save() {
        FogTimerHelper.shared.notificationsTurnedOn = notificationsTurnedOn
        if notificationsTurnedOn {
            FogTimerHelper.shared.repetationDate = repetationDate
            scheduleNotifications()
        } else {
            removeScheduledNotifications()
        }
    }
    
    func scheduleNotifications() {
        let content = UNMutableNotificationContent()
        content.title = "Stop FoG Daily"
        content.body = "Wake up and train your perception"
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: repetationDate)
        
        let trigger = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: FogTimerHelper.shared.notificationsId,
                    content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
           if error != nil {
              // Handle any errors.
           }
        }
    }

    func removeScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [FogTimerHelper.shared.notificationsId])
    }
}

class FogTimerHelper {
    static let shared = FogTimerHelper()
    
    private let keyNotifsOn = "notificationsTurnedOn"
    private let keyRepDate = "repetationDate"
    var notificationsId: String { return "FoGTimerNotificationID" }

    var notificationsTurnedOn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyNotifsOn)
        }
        set {
            repetationDate = newValue ? Date() : nil
            UserDefaults.standard.set(newValue, forKey: keyNotifsOn)
        }
    }
    
    var repetationDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: keyRepDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyRepDate)
        }
    }
}
