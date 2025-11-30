//
//  NotificationPermissionManager.swift
//  Trigger
//
//  Created by Matan Cohen on 30/11/2025.
//

import Foundation
import UserNotifications
import UIKit

enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

struct NotificationPermissionManager {
    static let shared = NotificationPermissionManager()

    func currentStatus() async -> NotificationAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await UIApplication.shared.registerForRemoteNotificationsIfAvailable()
            }
            return granted
        } catch {
            return false
        }
    }
}

private extension UIApplication {
    func registerForRemoteNotificationsIfAvailable() async {
        await MainActor.run {
            self.registerForRemoteNotifications()
        }
    }
}
