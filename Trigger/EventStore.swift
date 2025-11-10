//
//  EventStore.swift
//  Trigger
//
//  Created by Matan Cohen on 02/11/2025.
//

import Foundation
import Combine

// Event model
struct Event: Identifiable, Hashable {
    let id: UUID
    var title: String
    var startTime: Date
    var endTime: Date?
    var weekdays: Set<Weekday>

    // Habit metadata
    var isHabit: Bool = false
    var anchorEventID: UUID? = nil
    // Persist attach position as raw string to avoid cross-file enum coupling
    var attachPositionRaw: String? = nil

    // Convenience to read/write attach position safely
    enum Position: String {
        case before, after
    }

    var attachPosition: Position? {
        get {
            guard let raw = attachPositionRaw else { return nil }
            return Position(rawValue: raw)
        }
        set {
            attachPositionRaw = newValue?.rawValue
        }
    }
}

// Shared store for events
final class EventStore: ObservableObject {
    @Published var events: [Event] = []

    // Compute today's weekday using the same numbering as Weekday (Sunday = 1)
    private var todayWeekday: Weekday? {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekdayNumber)
    }

    var eventsForToday: [Event] {
        guard let today = todayWeekday else { return [] }
        return events.filter { $0.weekdays.contains(today) }
            .sorted { lhs, rhs in
                if lhs.startTime != rhs.startTime {
                    return lhs.startTime < rhs.startTime
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    func add(_ event: Event) {
        events.append(event)
    }
}

