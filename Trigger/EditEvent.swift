// EditEvent.swift
import SwiftUI

struct EditEvent: View {
    let event: Event
    var onSave: (Event) -> Void
    var onDelete: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    // Form state initialized from the event
    @State private var title: String
    @State private var selectedDays: Set<Weekday>
    @State private var time: Date
    @State private var isEndTimeEnabled: Bool
    @State private var endTime: Date

    private let cornerRadius: CGFloat = 18

    init(event: Event, onSave: @escaping (Event) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete

        // Initialize state from event
        _title = State(initialValue: event.title)
        _selectedDays = State(initialValue: event.weekdays)
        _time = State(initialValue: event.startTime)
        let hasEnd = event.endTime != nil
        _isEndTimeEnabled = State(initialValue: hasEnd)
        _endTime = State(initialValue: event.endTime ?? event.startTime)
    }

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

                // Save
                Button {
                    var updated = event
                    updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.startTime = time
                    updated.endTime = isEndTimeEnabled ? endTime : nil
                    updated.weekdays = selectedDays
                    onSave(updated)
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

                // Delete
                Button(role: .destructive) {
                    onDelete(event.id)
                    dismiss()
                } label: {
                    Text("Delete Event")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .navigationTitle("Edit Event")
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
