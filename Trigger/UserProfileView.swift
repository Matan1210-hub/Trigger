//
//  UserProfileView.swift
//  Trigger
//
//  Created by Your Name on 13/11/2025.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var eventStore: EventStore
    @EnvironmentObject private var habitStore: HabitStore

    // Formatter for "last completed" time, respects locale 12/24h
    private static let completionTimeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    var body: some View {
        ZStack {
            // App standard gradient background
            LinearGradient(
                colors: [Color("green_L1"), Color("green_L2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with back arrow and centered title
                HStack {
                    Button {
                        withAnimation(.snappy) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Profile")
                        .foregroundColor(Color.black)
                        .font(.system(.title, design: .rounded).bold())

                    Spacer()

                    // Right side spacer to balance back button width
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Space between header and content
                Spacer().frame(height: 16)

                // Center section: avatar + full name
                VStack(spacing: 16) {
                    // Placeholder avatar (keeps style consistent)
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.primary.opacity(0.9))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 96, height: 96)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                .frame(width: 96, height: 96)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

                    // Full name pulled from AuthStore (may be nil if not provided on first sign-in)
                    Text(displayName)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .accessibilityLabel("Full name")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)

                // Habits section
                VStack(spacing: 12) {
                    HStack {
                        Text("Your habits")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Glass container list
                    VStack {
                        if userHabits.isEmpty {
                            Text("No habits yet")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVStack(spacing: 10) {
                                    ForEach(userHabits) { habit in
                                        HabitRow(
                                            title: habit.title,
                                            anchorTitle: anchorTitle(for: habit),
                                            completionStatus: completionStatus(for: habit)
                                        )
                                    }
                                }
                                .padding(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)

                Spacer()

                // Bottom fixed Sign Out button
                Button {
                    withAnimation(.snappy) {
                        authStore.signOut()
                    }
                } label: {
                    Text("Sign Out")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar(.hidden, for: .navigationBar) // ensure custom header is used
        }
    }

    private var displayName: String {
        if let name = authStore.fullName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        } else {
            return "Your Name"
        }
    }

    // MARK: - Habits data

    private var userHabits: [Event] {
        eventStore.events
            .filter { $0.isHabit }
            .sorted { lhs, rhs in
                let la = anchorTitle(for: lhs)
                let ra = anchorTitle(for: rhs)
                if la != ra { return la.localizedCaseInsensitiveCompare(ra) == .orderedAscending }
                let lp = lhs.attachPosition == .before ? 0 : 1
                let rp = rhs.attachPosition == .before ? 0 : 1
                if lp != rp { return lp < rp }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private func anchorTitle(for habit: Event) -> String {
        guard let anchorID = habit.anchorEventID,
              let anchor = eventStore.events.first(where: { $0.id == anchorID }) else {
            return "Unknown event"
        }
        return anchor.title
    }

    // Build the "Last completed" status text for a habit from HabitStore
    private func completionStatus(for habit: Event) -> String {
        if let last = habitStore.habit(forEventID: habit.id)?.lastCompletedAt {
            let t = UserProfileView.completionTimeFormatter.string(from: last)
            return "Last completed: \(t)"
        } else {
            return "Not completed yet"
        }
    }
}

// MARK: - Small HabitRow used in profile

private struct HabitRow: View {
    let title: String
    let anchorTitle: String
    let completionStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                Text(completionStatus)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text("Attached to: \(anchorTitle)")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(AuthStore())
            .environmentObject(EventStore())
            .environmentObject(HabitStore())
    }
}
