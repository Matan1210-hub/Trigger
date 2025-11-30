//
//  TriggerApp.swift
//  Trigger
//
//  Created by Matan Cohen on 29/10/2025.
//

import SwiftUI

@main
struct TriggerApp: App {
    @StateObject private var eventStore = EventStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var habitStore = HabitStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.isAuthenticated {
                    ContentView()
                        .environmentObject(eventStore)
                        .environmentObject(habitStore)
                } else {
                    SignInWithAppleView()
                }
            }
            .environmentObject(authStore)
        }
    }
}

