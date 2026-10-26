//
//  NotificationManager.swift
//  ios-final-coursework
//
//  Local notification support (permission request + bill-saved alert).
//

import Foundation
import UserNotifications

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    /// Call once at launch so notifications are also shown while the app is in the foreground.
    public func configure() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Requests permission to show alerts, sounds and badges. Completion is called on the main queue.
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }
    
    /// Schedules an immediate local notification, requesting permission first if it has not been decided yet.
    public func scheduleNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.deliver(title: title, body: body, identifier: identifier)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { self.deliver(title: title, body: body, identifier: identifier) }
                }
            default:
                break
            }
        }
    }
    
    /// Fires when a bill has been saved successfully.
    public func notifyBillSaved(billingMonth: String, totalKWh: String) {
        let month = billingMonth.isEmpty ? "your latest bill" : "your \(billingMonth) bill"
        let usage = totalKWh.trimmingCharacters(in: .whitespaces)
        let body = usage.isEmpty
            ? "We saved \(month). Your forecast has been updated."
            : "We saved \(month) (\(usage) kWh). Your forecast has been updated."
        scheduleNotification(title: "Bill saved", body: body)
    }
    
    private func deliver(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
