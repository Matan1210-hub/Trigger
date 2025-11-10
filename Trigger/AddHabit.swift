//
//  AddHabit.swift
//  Trigger
//
//  Created by Matan Cohen on 29/10/2025.
//

import SwiftUI

struct AddHabit: View {
    // Callback to return the created habit as an Event
    var onSave: (Event) -> Void = { _ in }

    // Access events to populate the picker
    @EnvironmentObject private var eventStore: EventStore

    @State private var name: String = ""
    @State private var selectedEventID: UUID?
    @State private var attachPosition: AttachPosition = .after

    @Environment(\.dismiss) private var dismiss

    private let cornerRadius: CGFloat = 18

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Glass card container
                VStack(spacing: 12) {
                    // Habit name
                    TextField("Habit name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )

                    // Event picker (dropdown)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attach to event")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        Picker("Event", selection: $selectedEventID) {
                            Text("Select an event").tag(UUID?.none)
                            ForEach(availableAnchorEvents) { event in
                                Text(event.title)
                                    .tag(UUID?.some(event.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    // Before/After segmented control
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Position")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        Picker("Position", selection: $attachPosition) {
                            ForEach(AttachPosition.allCases) { pos in
                                Text(pos.title).tag(pos)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)

                Spacer()

                Button {
                    saveHabit()
                } label: {
                    Text("Save")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .navigationTitle("Add New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
            }
            .background(
                LinearGradient(
                    colors: [Color("green_L1"), Color("green_L2")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && selectedEventID != nil
    }

    // Include all non-habit events; do not exclude events that already have habits
    private var availableAnchorEvents: [Event] {
        return eventStore.events
            .filter { !$0.isHabit }
            .sorted { lhs, rhs in
                if lhs.startTime != rhs.startTime {
                    return lhs.startTime < rhs.startTime
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private func saveHabit() {
        guard canSave,
              let eventID = selectedEventID,
              let anchor = eventStore.events.first(where: { $0.id == eventID })
        else { return }

        let calendar = Calendar.current
        let beforeTime = calendar.date(byAdding: .minute, value: -1, to: anchor.startTime) ?? anchor.startTime
        let afterBase = anchor.endTime ?? anchor.startTime
        let afterTime = calendar.date(byAdding: .minute, value: 1, to: afterBase) ?? afterBase

        let startTime = (attachPosition == .before) ? beforeTime : afterTime

        var newHabitEvent = Event(
            id: UUID(),
            title: name.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: startTime,
            endTime: nil,
            weekdays: anchor.weekdays // mirror the selected event's days
        )
        // Persist habit metadata for overlay placement
        newHabitEvent.isHabit = true
        newHabitEvent.anchorEventID = anchor.id
        newHabitEvent.attachPositionRaw = attachPosition.rawValue

        onSave(newHabitEvent)
        dismiss()
    }
}

private enum AttachPosition: String, CaseIterable, Identifiable {
    case before, after

    var id: String { rawValue }

    var title: String {
        switch self {
        case .before: return "Before"
        case .after: return "After"
        }
    }
}

#Preview {
    AddHabit()
        .environmentObject(EventStore())
}
