//
//  AddEvent.swift
//  Trigger
//
//  Created by Matan Cohen on 29/10/2025.
//

import SwiftUI

struct AddEvent: View {
    // Callback to return the created event
    var onSave: (Event) -> Void = { _ in }

    // Simple fields to illustrate a clean modal; can be expanded later
    @State private var title: String = ""
    @Environment(\.dismiss) private var dismiss

    // Multi-select weekdays state
    @State private var selectedDays: Set<Weekday> = []

    // Time selection state (hour and minute)
    @State private var time: Date = Date()

    // Optional end time
    @State private var isEndTimeEnabled: Bool = false
    @State private var endTime: Date = Date()

    private let cornerRadius: CGFloat = 18

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                EventFormCard(
                    title: $title,
                    selectedDays: $selectedDays,
                    time: $time,
                    isEndTimeEnabled: $isEndTimeEnabled,
                    endTime: $endTime,
                    cornerRadius: cornerRadius
                )

                Spacer()

                Button {
                    // Construct Event and pass it out
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let event = Event(
                        id: UUID(),
                        title: trimmed,
                        startTime: time,
                        endTime: isEndTimeEnabled ? endTime : nil,
                        weekdays: selectedDays
                    )
                    onSave(event)
                    dismiss()
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
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedDays.isEmpty)
                .opacity((title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedDays.isEmpty) ? 0.6 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .navigationTitle("Add New Event")
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
}

struct EventFormCard: View {
    @Binding var title: String
    @Binding var selectedDays: Set<Weekday>
    @Binding var time: Date
    @Binding var isEndTimeEnabled: Bool
    @Binding var endTime: Date

    let cornerRadius: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            TitleField(title: $title)

            WeekdaysSection(selectedDays: $selectedDays)

            TimeSection(
                time: $time,
                isEndTimeEnabled: $isEndTimeEnabled,
                endTime: $endTime
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

struct TitleField: View {
    @Binding var title: String

    var body: some View {
        TextField("Event title", text: $title)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .rounded))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
    }
}

struct WeekdaysSection: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekdays")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            WeekdayGrid(
                selectedDays: $selectedDays,
                cornerRadius: 12
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

struct TimeSection: View {
    @Binding var time: Date
    @Binding var isEndTimeEnabled: Bool
    @Binding var endTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                StartTimeField(time: $time, isEndTimeEnabled: $isEndTimeEnabled, endTime: $endTime)

                EndTimeField(isEndTimeEnabled: $isEndTimeEnabled, time: $time, endTime: $endTime)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

struct StartTimeField: View {
    @Binding var time: Date
    @Binding var isEndTimeEnabled: Bool
    @Binding var endTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .font(.system(.body, design: .rounded))
                .tint(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Start time")
        .accessibilityHint("Select the start time for this event")
        .onChange(of: time) { _, newValue in
            if isEndTimeEnabled, endTime < newValue {
                endTime = newValue
            }
        }
    }
}

struct EndTimeField: View {
    @Binding var isEndTimeEnabled: Bool
    @Binding var time: Date
    @Binding var endTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("End time")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Toggle("", isOn: $isEndTimeEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel("Enable end time")
            }

            Group {
                if isEndTimeEnabled {
                    HStack(spacing: 10) {
                        DatePicker(
                            "",
                            selection: $endTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .font(.system(.body, design: .rounded))
                        .tint(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onChange(of: endTime) { _, newValue in
                        if newValue < time {
                            endTime = time
                        }
                    }
                } else {
                    Text("Off")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isEndTimeEnabled ? "End time" : "End time disabled")
        .accessibilityHint(isEndTimeEnabled ? "Select the end time for this event" : "Enable to select an end time")
        .onChange(of: isEndTimeEnabled) { _, enabled in
            if enabled, endTime < time {
                endTime = time
            }
        }
    }
}

// MARK: - Weekday Model

enum Weekday: Int, CaseIterable, Hashable, Identifiable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    // Short labels for compact chips (S M T W T F S)
    var shortLabel: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    // Full names for accessibility
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    // Sunday-first ordering
    static var sundayFirst: [Weekday] {
        [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    }
}

// MARK: - Weekday Grid

struct WeekdayGrid: View {
    @Binding var selectedDays: Set<Weekday>
    let cornerRadius: CGFloat

    // Layout: 7 equal chips in a row; wraps on compact widths
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(minimum: 34), spacing: 8), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Weekday.sundayFirst) { day in
                WeekdayChip(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    cornerRadius: 10
                )
                .onTapGesture {
                    toggle(day)
                }
                .accessibilityAddTraits(selectedDays.contains(day) ? .isSelected : [])
                .accessibilityLabel(day.fullName)
                .accessibilityHint("Double tap to \(selectedDays.contains(day) ? "deselect" : "select")")
            }
        }
    }

    private func toggle(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

// MARK: - Weekday Chip

struct WeekdayChip: View {
    let day: Weekday
    let isSelected: Bool
    let cornerRadius: CGFloat

    var body: some View {
        Text(day.shortLabel)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .frame(minWidth: 34, minHeight: 34)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.primary.opacity(0.6) : Color.white.opacity(0.18),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.14 : 0.08), radius: isSelected ? 10 : 6, x: 0, y: isSelected ? 6 : 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isSelected)
    }
}

#Preview {
    AddEvent()
}
