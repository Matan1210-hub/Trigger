//
//  EventStore.swift
//  Trigger
//
//  Created by Matan Cohen on 02/11/2025.
//

import Foundation
import Combine

// Event model
struct Event: Identifiable, Hashable, Codable {
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
    enum Position: String, Codable {
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
    @Published var events: [Event] = [] {
        didSet { saveIfNeeded() }
    }

    // MARK: - File persistence (JSON in Documents directory)

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("events.json")
    }()

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Public API

    // Events that occur on today's calendar date (local time zone).
    // This satisfies: only show events scheduled for today’s date,
    // and enables immediate live updates in ContentView since `events` is @Published.
    var eventsForToday: [Event] {
        let calendar = Calendar.current
        let today = Date()
        return events
            .filter { event in
                calendar.isDate(event.startTime, inSameDayAs: today)
            }
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

    func update(_ event: Event) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
        }
    }

    func delete(id: UUID) {
        events.removeAll { $0.id == id }
    }

    func delete(where predicate: (Event) -> Bool) {
        events.removeAll(where: predicate)
    }

    // MARK: - Private helpers

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loaded = try decoder.decode([Event].self, from: data)
            self.events = loaded
        } catch {
            // If file missing or decoding fails, start with empty and don't crash
            self.events = []
        }
    }

    private func saveIfNeeded() {
        let eventsSnapshot = self.events
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(eventsSnapshot)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch {
                // Handle/log errors as needed
            }
        }
    }
}
