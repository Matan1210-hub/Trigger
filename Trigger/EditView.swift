//
//  EditView.swift
//  Trigger
//
//  Created by Matan Cohen on 18/11/2025.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var eventStore: EventStore

    // Localized time formatter for rows
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    // MARK: - Edit sheet state
    @State private var eventBeingEdited: Event? = nil
    @State private var isPresentingEdit = false

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
                // Top bar with back arrow (same design as UserProfileView) and centered title
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

                    Text("Editing area")
                        .foregroundColor(Color.black)
                        .font(.system(.title, design: .rounded).bold())

                    Spacer()

                    // Right spacer to balance back button width
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Content
                VStack(spacing: 16) {
                    // All events section
                    SectionHeader(title: "All events")
                        .padding(.horizontal, 20)

                    GlassListContainer {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 10) {
                                ForEach(allEventsSorted) { event in
                                    EventRow(event: event)
                                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .onTapGesture {
                                            eventBeingEdited = event
                                            isPresentingEdit = true
                                        }
                                }
                            }
                            .padding(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity, alignment: .top)

                    // All habits section
                    SectionHeader(title: "All habits")
                        .padding(.horizontal, 20)

                    GlassListContainer {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 10) {
                                ForEach(allHabitsSorted) { habit in
                                    HabitRow(habit: habit, anchorTitle: anchorTitle(for: habit), positionTitle: positionTitle(for: habit))
                                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .onTapGesture {
                                            eventBeingEdited = habit
                                            isPresentingEdit = true
                                        }
                                }
                            }
                            .padding(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Spacer to keep layout consistent
                // Removed extra Spacer() so the two sections can flex and scroll independently
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar(.hidden, for: .navigationBar)
        }
        // Edit modal sheet
        .sheet(isPresented: $isPresentingEdit, onDismiss: {
            eventBeingEdited = nil
        }) {
            if let event = eventBeingEdited {
                EditEvent(event: event) { updated in
                    eventStore.update(updated)
                } onDelete: { id in
                    eventStore.delete(id: id)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            } else {
                // Safety fallback to avoid presenting an empty sheet
                EmptyView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Data slices

    private var allEventsSorted: [Event] {
        eventStore.events
            .filter { !$0.isHabit }
            .sorted { lhs, rhs in
                if lhs.startTime != rhs.startTime { return lhs.startTime < rhs.startTime }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private var allHabitsSorted: [Event] {
        eventStore.events
            .filter { $0.isHabit }
            .sorted { lhs, rhs in
                // Sort by anchor title then position then habit title for stable ordering
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

    private func positionTitle(for habit: Event) -> String {
        switch habit.attachPosition {
        case .before: return "Before"
        case .after: return "After"
        case .none: return "After"
        }
    }

    // MARK: - Subviews

    private struct SectionHeader: View {
        let title: String
        var body: some View {
            HStack {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    // A reusable glass container for list areas, matching app styling
    private struct GlassListContainer<Content: View>: View {
        @ViewBuilder var content: Content

        var body: some View {
            content
                .frame(maxWidth: .infinity, minHeight: 140) // gives room for a few rows
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        }
    }

    private struct EventRow: View {
        let event: Event

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text(timeText(event))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Weekday chips (read-only)
                HStack(spacing: 6) {
                    ForEach(Weekday.sundayFirst) { day in
                        ReadonlyWeekdayChip(day: day, isSelected: event.weekdays.contains(day))
                    }
                }
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

        private func timeText(_ event: Event) -> String {
            let start = EditView.timeFormatter.string(from: event.startTime)
            if let end = event.endTime {
                return "\(start) – \(EditView.timeFormatter.string(from: end))"
            } else {
                return start
            }
        }
    }

    private struct HabitRow: View {
        let habit: Event
        let anchorTitle: String
        let positionTitle: String

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(habit.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text(positionTitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
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

    private struct ReadonlyWeekdayChip: View {
        let day: Weekday
        let isSelected: Bool

        var body: some View {
            Text(day.shortLabel)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .frame(minWidth: 26, minHeight: 26)
                .foregroundStyle(.primary)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.primary.opacity(0.6) : Color.white.opacity(0.18),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(color: .black.opacity(isSelected ? 0.12 : 0.06), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
    }
}

#Preview {
    NavigationStack {
        EditView()
            .environmentObject(EventStore())
    }
}

