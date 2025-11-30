//
//  NotificationPermissionPrompt.swift
//  Trigger
//
//  Created by Matan Cohen on 30/11/2025.
//

import SwiftUI

struct NotificationPermissionPrompt: View {
    var onAllow: () -> Void
    var onNotNow: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Title
                Text("Stay on track with reminders")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                // Description
                Text("To send habit reminders at the right time, Trigger needs permission to deliver notifications.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Buttons
                VStack(spacing: 10) {
                    Button(action: onAllow) {
                        Text("Allow Notifications")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onNotNow) {
                        Text("Not Now")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
