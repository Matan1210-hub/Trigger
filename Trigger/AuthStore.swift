//
//  AuthStore.swift
//  Trigger
//
//  Created by Matan Cohen on 10/11/2025.
//

import Foundation
import Combine
import AuthenticationServices

final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var appleUserID: String?
    @Published private(set) var fullName: String?

    private let userDefaultsKeyUserID = "appleUserID"
    private let userDefaultsKeyFullName = "appleFullName"
    private let userDefaultsKeyDidShowNotifPrompt = "didShowNotificationPromptForUser"

    init() {
        // Load persisted user ID
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKeyUserID), !stored.isEmpty {
            self.appleUserID = stored
            self.isAuthenticated = true
        } else {
            self.appleUserID = nil
            self.isAuthenticated = false
        }
        // Load persisted full name (may be nil if never captured)
        self.fullName = UserDefaults.standard.string(forKey: userDefaultsKeyFullName)
    }

    func setAuthenticated(userID: String) {
        self.appleUserID = userID
        UserDefaults.standard.set(userID, forKey: userDefaultsKeyUserID)
        self.isAuthenticated = true
    }

    func setFullNameIfAvailable(_ components: PersonNameComponents?) {
        guard let components else { return }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        self.fullName = name
        UserDefaults.standard.set(name, forKey: userDefaultsKeyFullName)
    }

    func signOut() {
        self.appleUserID = nil
        self.fullName = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyUserID)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyFullName)
        // Reset the notification prompt marker; next user can see it once
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyDidShowNotifPrompt)
        self.isAuthenticated = false
    }
}
