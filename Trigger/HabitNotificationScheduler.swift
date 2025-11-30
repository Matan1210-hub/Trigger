//
//  HabitNotificationScheduler.swift
//  Trigger
//
//  Created by Matan Cohen on 30/11/2025.
//

import Foundation
import UserNotifications

/// Schedules and manages local notifications for habit reminders.
/// This component is self-contained and only depends on the Habit entity
/// and the Event timing data (for anchor start/end and attach position).
struct HabitNotificationScheduler {

    // MARK: - Public API

    /// Schedule a reminder notification for a habit, following the rule:
    /// - If the habit has `lastCompletedAt`, schedule 10 minutes before that time for the next day.
    /// - Otherwise, fall back to the attached event:
    ///     - If habit is before an event: 10 minutes before the event’s start time (next occurrence).
    ///     - If habit is after an event: 10 minutes before the event’s end time (next occurrence).
    ///
    /// Notes:
    /// - This schedules a single next-fire date (not a repeating schedule).
    /// - Callers are expected to have requested authorization elsewhere.
    ///
    /// - Parameters:
    ///   - habit: The Habit metadata (for lastCompletedAt).
    ///   - habitEvent: The Event that represents the habit (isHabit == true). Used for attachPosition and anchorEventID.
    ///   - anchorEvent: The non-habit Event the habit is attached to (start/end and weekdays).
    ///   - title: Optional notification title (defaults to the habitEvent.title).
    ///   - body: Optional notification body.
    static func scheduleNextReminder(
        habit: Habit,
        habitEvent: Event,
        anchorEvent: Event,
        title: String? = nil,
        body: String? = nil
    ) async {
        guard habitEvent.isHabit else { return }

        // Compute target fire date according to the rule
        guard let fireDate = nextFireDate(habit: habit, habitEvent: habitEvent, anchorEvent: anchorEvent) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title ?? habitEvent.title
        if let body = body {
            content.body = body
        }
        content.sound = .default

        // Use a stable identifier per habit to replace the pending request when rescheduling
        let identifier = notificationIdentifier(forHabitID: habit.id)

        // Date-based trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        ), repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Replace any existing request for this habit
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        do {
            try await center.add(request)
        } catch {
            // Swallow or log as needed; keeping this self-contained without external logging.
        }
    }

    /// Cancel any pending reminder for the given habit id.
    static func cancelReminder(forHabitID id: UUID) async {
        let identifier = notificationIdentifier(forHabitID: id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Internal scheduling logic

    /// Computes the next fire date for the habit notification according to the rule set.
    private static func nextFireDate(habit: Habit, habitEvent: Event, anchorEvent: Event) -> Date? {
        let calendar = Calendar.current

        // 1) If we have a lastCompletedAt, schedule 10 minutes before that time for the next day.
        if let last = habit.lastCompletedAt {
            let timeOfDay = calendar.dateComponents([.hour, .minute, .second], from: last)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())),
                  let targetTime = calendar.date(bySettingHour: timeOfDay.hour ?? 0,
                                                 minute: timeOfDay.minute ?? 0,
                                                 second: timeOfDay.second ?? 0,
                                                 of: nextDay),
                  let fire = calendar.date(byAdding: .minute, value: -10, to: targetTime)
            else { return nil }
            return fire
        }

        // 2) Otherwise, fall back to the attached event timing.
        // Determine the base time (start or end) from the next occurrence of the anchor event.
        guard let attach = habitEvent.attachPosition else {
            // Default to 'after' if unspecified (mirrors EditView fallback).
            return nextFireDateForAnchor(anchorEvent: anchorEvent, position: .after, calendar: calendar)
        }
        return nextFireDateForAnchor(anchorEvent: anchorEvent, position: attach, calendar: calendar)
    }

    /// Compute the next occurrence of the anchor event (today or future) according to its weekdays set,
    /// and return a fire date 10 minutes before the relevant anchor boundary (start or end).
    private static func nextFireDateForAnchor(anchorEvent: Event, position: Event.Position, calendar: Calendar) -> Date? {
        // Identify the next date that matches the event's weekdays.
        // If weekdays is empty, treat it as occurring today using its stored date.
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Helper to map Calendar weekday to your Weekday rawValue (1...7 with Sunday=1)
        func weekdayOf(_ date: Date) -> Int {
            calendar.component(.weekday, from: date)
        }

        // Find the next date (including today) that matches the event's weekdays
        let targetDate: Date = {
            if anchorEvent.weekdays.isEmpty {
                // No recurrence info; use the calendar date of anchorEvent.startTime if in the future,
                // otherwise move to tomorrow.
                let anchorDay = calendar.startOfDay(for: anchorEvent.startTime)
                if anchorDay >= today {
                    return anchorDay
                } else {
                    return calendar.date(byAdding: .day, value: 1, to: today) ?? today
                }
            } else {
                // Rolling search up to 14 days to be safe
                for offset in 0...14 {
                    let candidate = calendar.date(byAdding: .day, value: offset, to: today) ?? today
                    let wd = weekdayOf(candidate)
                    // Weekday is stored as Set<Weekday>; Weekday(rawValue:) should align with Calendar’s .weekday
                    if let weekdayEnum = Weekday(rawValue: wd), anchorEvent.weekdays.contains(weekdayEnum) {
                        return candidate
                    }
                }
                // Fallback: today
                return today
            }
        }()

        // Build the candidate base time on the targetDate using the anchor's stored time-of-day
        let timeSource: Date? = {
            switch position {
            case .before:
                return anchorEvent.startTime
            case .after:
                // If endTime missing, fall back to startTime
                return anchorEvent.endTime ?? anchorEvent.startTime
            }
        }()

        guard let base = timeSource else { return nil }

        let tod = calendar.dateComponents([.hour, .minute, .second], from: base)
        guard let candidateDateTime = calendar.date(bySettingHour: tod.hour ?? 0,
                                                    minute: tod.minute ?? 0,
                                                    second: tod.second ?? 0,
                                                    of: targetDate) else {
            return nil
        }

        // If candidate already passed for today, roll to the next valid day in the set.
        let adjustedDateTime: Date = {
            if candidateDateTime > now {
                return candidateDateTime
            } else {
                // Move to the next matching day after today
                if anchorEvent.weekdays.isEmpty {
                    return calendar.date(byAdding: .day, value: 1, to: candidateDateTime) ?? candidateDateTime
                } else {
                    var day = candidateDateTime
                    for _ in 1...14 {
                        day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
                        let wd = weekdayOf(day)
                        if let weekdayEnum = Weekday(rawValue: wd), anchorEvent.weekdays.contains(weekdayEnum) {
                            // Reapply the same time-of-day on this new day
                            let baseTime = calendar.dateComponents([.hour, .minute, .second], from: candidateDateTime)
                            if let rebuilt = calendar.date(bySettingHour: baseTime.hour ?? 0,
                                                           minute: baseTime.minute ?? 0,
                                                           second: baseTime.second ?? 0,
                                                           of: calendar.startOfDay(for: day)) {
                                return rebuilt
                            }
                        }
                    }
                    return candidateDateTime
                }
            }
        }()

        // Fire 10 minutes before the adjusted candidate time
        return calendar.date(byAdding: .minute, value: -10, to: adjustedDateTime)
    }

    // MARK: - Helpers

    private static func notificationIdentifier(forHabitID id: UUID) -> String {
        "habit-reminder-\(id.uuidString)"
    }
}
