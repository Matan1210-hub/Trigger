//
//  HabitStore.swift
//  Trigger
//
//  Created by Matan Cohen on 30/11/2025.
//

import Foundation
import Combine

// Standalone Habit entity that stores completion metadata for a habit
// Each Habit is keyed by the associated habit Event's id.
struct Habit: Identifiable, Hashable, Codable {
    // Use the habit Event's UUID as the Habit id for 1:1 mapping
    let id: UUID

    // Exact timestamp when the user last confirmed completion of this habit
    var lastCompletedAt: Date?
}

// Store for Habit entities, persisted to a separate JSON file.
// Mirrors EventStore's persistence approach for consistency.
final class HabitStore: ObservableObject {
    @Published private(set) var habits: [UUID: Habit] = [:] {
        didSet { saveIfNeeded() }
    }

    // MARK: - File persistence (JSON in Documents directory)

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("habits.json")
    }()

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Public API

    func habit(forEventID id: UUID) -> Habit? {
        habits[id]
    }

    func markCompleted(eventID: UUID, at date: Date = Date()) {
        var existing = habits[eventID] ?? Habit(id: eventID, lastCompletedAt: nil)
        existing.lastCompletedAt = date
        habits[eventID] = existing
    }

    // Optional helper if you ever want to clear completion
    func clearCompletion(eventID: UUID) {
        guard var existing = habits[eventID] else { return }
        existing.lastCompletedAt = nil
        habits[eventID] = existing
    }

    // MARK: - Private helpers

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedArray = try decoder.decode([Habit].self, from: data)
            let dict = Dictionary(uniqueKeysWithValues: loadedArray.map { ($0.id, $0) })
            self.habits = dict
        } catch {
            self.habits = [:]
        }
    }

    private func saveIfNeeded() {
        let snapshot = Array(habits.values)
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(snapshot)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch {
                // Handle/log as needed
            }
        }
    }
}

