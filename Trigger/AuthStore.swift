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

    private let userDefaultsKey = "appleUserID"

    init() {
        // Load persisted user ID
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey), !stored.isEmpty {
            self.appleUserID = stored
            self.isAuthenticated = true
        } else {
            self.appleUserID = nil
            self.isAuthenticated = false
        }
    }

    func setAuthenticated(userID: String) {
        self.appleUserID = userID
        UserDefaults.standard.set(userID, forKey: userDefaultsKey)
        self.isAuthenticated = true
    }

    func signOut() {
        self.appleUserID = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        self.isAuthenticated = false
    }
}

