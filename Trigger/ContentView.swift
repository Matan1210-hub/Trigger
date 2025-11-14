//
//  ContentView.swift
//  Trigger
//
//  Created by Matan Cohen on 29/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false
    @State private var isPresentingAddEvent = false
    @State private var isPresentingAddHabit = false

    // Read the shared store from the environment (provided by TriggerApp)
    @EnvironmentObject private var eventStore: EventStore

    // Controls the radial distance of the satellite buttons from the main "+"
    private let satelliteDistance: CGFloat = 96
    // Corner radius used for the glass buttons
    private let buttonCornerRadius: CGFloat = 18
    // Size of the buttons
    private let buttonSize: CGFloat = 56
    // Animation for expansion/collapse
    private let expandAnimation = Animation.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2)

    // Timeline constants
    private let minuteHeight: CGFloat = 1.5 // points per minute (90 pt per hour)
    private let hourLabelWidth: CGFloat = 52
    private let trackCornerRadius: CGFloat = 16
    private let eventMinDurationMinutes: Int = 15 // visual minimum if no endTime

    // Scroll to now
    @State private var initialScrolled = false

    // Fixed 24-hour parser for any future string-to-Date conversions (not used by DatePicker flow)
    private static let fixed24hParser: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = .current
        df.dateFormat = "HH:mm"
        return df
    }()

    // Localized time formatter for UI
    private static let localizedTimeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("green_L1"), Color("green_L2")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with avatar on the left and title
                    HStack(spacing: 12) {
                        // Navigate to profile when tapping avatar
                        NavigationLink {
                            UserProfileView()
                                .toolbar(.hidden, for: .navigationBar)
                        } label: {
                            AvatarCircle()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)

                        Text("Today's Schedule")
                            .foregroundColor(Color.black)
                            .font(.system(.title, design: .rounded).bold())
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 2)
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                    // Timeline
                    TimelineDayView(
                        events: eventsForCurrentWeekday(eventStore.events),
                        minuteHeight: minuteHeight,
                        hourLabelWidth: hourLabelWidth,
                        eventMinDurationMinutes: eventMinDurationMinutes
                    )
                    .padding(.top, 12)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            // Floating action area overlay
            .overlay(alignment: .bottomTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    if isExpanded {
                        Color.black.opacity(0.0001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(expandAnimation) {
                                    isExpanded = false
                                }
                            }
                    }

                    // Satellite buttons
                    Group {
                        glassButton(
                            systemName: "calendar",
                            cornerRadius: buttonCornerRadius,
                            size: buttonSize
                        ) {
                            withAnimation(expandAnimation) {
                                isExpanded = false
                            }
                            isPresentingAddEvent = true
                        }
                        .offset(satelliteOffset(angleDegrees: 45, distance: satelliteDistance))
                        .scaleEffect(isExpanded ? 1 : 0.6)
                        .opacity(isExpanded ? 1 : 0)
                        .rotationEffect(.degrees(isExpanded ? 0 : -12))
                        .animation(expandAnimation, value: isExpanded)

                        glassButton(
                            systemName: "checkmark",
                            cornerRadius: buttonCornerRadius,
                            size: buttonSize
                        ) {
                            withAnimation(expandAnimation) {
                                isExpanded = false
                            }
                            isPresentingAddHabit = true
                        }
                        .offset(satelliteOffset(angleDegrees: 90, distance: satelliteDistance))
                        .scaleEffect(isExpanded ? 1 : 0.6)
                        .opacity(isExpanded ? 1 : 0)
                        .rotationEffect(.degrees(isExpanded ? 0 : -12))
                        .animation(expandAnimation, value: isExpanded)
                    }
                    .allowsHitTesting(isExpanded)

                    // Main "+" button
                    Button(action: {
                        withAnimation(expandAnimation) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(glassBackground(cornerRadius: buttonCornerRadius))
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            .animation(expandAnimation, value: isExpanded)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            // Present AddEvent modal as full-height sheet
            .sheet(isPresented: $isPresentingAddEvent) {
                AddEvent { newEvent in
                    // If you ever receive times as strings, convert with fixed24hParser first:
                    // let parsed = ContentView.fixed24hParser.date(from: "10:00")
                    eventStore.add(newEvent)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            // Present AddHabit modal as full-height sheet
            .sheet(isPresented: $isPresentingAddHabit) {
                AddHabit { newHabit in
                    eventStore.add(newHabit)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Helpers (kept from original)

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0), lineWidth: 1)
            )
    }

    private func glassButton(systemName: String, cornerRadius: CGFloat, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(glassBackground(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func satelliteOffset(angleDegrees: CGFloat, distance: CGFloat) -> CGSize {
        let radians = angleDegrees * .pi / 180
        let dx = -cos(radians) * distance
        let dy = -sin(radians) * distance
        return CGSize(width: dx, height: dy)
    }

    // Filter by current weekday membership, not by calendar date
    private func eventsForCurrentWeekday(_ all: [Event]) -> [Event] {
        let weekday = currentWeekday()
        return all
            .filter { $0.weekdays.contains(weekday) }
            .sorted { lhs, rhs in
                if lhs.startTime != rhs.startTime {
                    return lhs.startTime < rhs.startTime
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private func currentWeekday() -> Weekday {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
}

// MARK: - Timeline Day View

private struct TimelineDayView: View {
    let events: [Event]
    let minuteHeight: CGFloat
    let hourLabelWidth: CGFloat
    let eventMinDurationMinutes: Int

    @State private var nowID: Int? = nil // hour index to scroll to

    // Localized time formatter for UI labels (respects system 12/24 setting)
    private static let uiTimeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // Hour grid (lowest layer)
                    HourGrid(minuteHeight: minuteHeight, hourLabelWidth: hourLabelWidth)
                        .id("grid")
                        .zIndex(0)

                    // Event track overlay (above grid)
                    EventTrack(
                        events: events,
                        minuteHeight: minuteHeight,
                        hourLabelWidth: hourLabelWidth,
                        eventMinDurationMinutes: eventMinDurationMinutes
                    )
                    .zIndex(1)

                    // Now line (top-most)
                    NowLine(minuteHeight: minuteHeight, hourLabelWidth: hourLabelWidth)
                        .zIndex(2)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140) // room for FAB
            }
            .onAppear {
                // Compute the nearest hour to "now" and scroll to it once
                if nowID == nil {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
                    if let hour = comps.hour {
                        nowID = hour
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo(hourAnchorID(hour), anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func hourAnchorID(_ hour: Int) -> String {
        "hour-\(hour)"
    }

    // Hour grid with labels and separators
    private struct HourGrid: View {
        let minuteHeight: CGFloat
        let hourLabelWidth: CGFloat

        // Formatter to build hour labels per system 12h/24h preference
        private static let hourLabelFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = .current
            df.timeStyle = .short
            df.dateStyle = .none
            return df
        }()

        var body: some View {
            VStack(spacing: 0) {
                ForEach(0...24, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 8) {
                        // Left rail labels
                        Text(label(for: hour))
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: hourLabelWidth, alignment: .trailing)
                            .padding(.trailing, 6)
                            .id("hour-\(hour)")

                        // Right rail separator line spanning one hour height (except at 24)
                        Rectangle()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: hour == 24 ? 1 : minuteHeight * 60)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.22))
                                    .frame(height: 0.5)
                            }
                            .overlay(alignment: .bottom) {
                                if hour < 24 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 0.5)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }

        private func label(for hour: Int) -> String {
            // Build a Date at today's midnight and add `hour` hours, then format for UI.
            let cal = Calendar.current
            let startOfDay = cal.startOfDay(for: Date())
            if let date = cal.date(byAdding: .hour, value: hour, to: startOfDay) {
                return HourGrid.hourLabelFormatter.string(from: date)
            } else {
                return "\(hour):00"
            }
        }
    }

    // Event overlay track
    private struct EventTrack: View {
        let events: [Event]
        let minuteHeight: CGFloat
        let hourLabelWidth: CGFloat
        let eventMinDurationMinutes: Int

        var body: some View {
            ZStack(alignment: .topLeading) {
                ForEach(positionedEvents) { pe in
                    EventBlock(event: pe.event, y: pe.y, height: pe.height, hourLabelWidth: hourLabelWidth)
                        .zIndex(Double(pe.column)) // prepare for overlap columns later
                }
            }
        }

        // Prepare for overlap handling: column reserved, currently 0 for all
        private var positionedEvents: [PositionedEvent] {
            events.map { e in
                let start = minutesSinceMidnight(e.startTime) // 24h minutes since midnight
                let end = e.endTime.map { minutesSinceMidnight($0) } // 24h minutes since midnight
                let duration = max((end ?? start + eventMinDurationMinutes) - start, eventMinDurationMinutes)
                let y = CGFloat(start) * minuteHeight
                let height = CGFloat(duration) * minuteHeight
                return PositionedEvent(event: e, y: y, height: height, column: 0)
            }
        }

        private struct PositionedEvent: Identifiable {
            var id: UUID { event.id }
            let event: Event
            let y: CGFloat
            let height: CGFloat
            let column: Int
        }

        // Internal positioning math: minutes since midnight in 24-hour space
        private func minutesSinceMidnight(_ date: Date) -> Int {
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: date)
            let h = comps.hour ?? 0
            let m = comps.minute ?? 0
            return (h * 60 + m) - 710
        }
    }

    // Event block card
    private struct EventBlock: View {
        let event: Event
        let y: CGFloat
        let height: CGFloat
        let hourLabelWidth: CGFloat

        var body: some View {
            HStack(spacing: 8) {
                // Spacer to align to the track (skip label rail)
                Color.clear
                    .frame(width: hourLabelWidth)

                // The block occupying the track width
                VStack(alignment: .leading, spacing: 0) {
                    // Title only (display formatter available if times are later shown)
                    Text(event.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .contentShape(Rectangle())
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    // Darker rectangle than the hour grid
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                .frame(height: max(height, 44), alignment: .topLeading)
            }
            .offset(y: y)
        }
    }

    // Now indicator line
    private struct NowLine: View {
        let minuteHeight: CGFloat
        let hourLabelWidth: CGFloat

        var body: some View {
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: Date())
            let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            return HStack(spacing: 8) {
                Color.clear
                    .frame(width: hourLabelWidth)

                Rectangle()
                    .fill(Color.red.opacity(0.9))
                    .frame(height: 2)
                    .shadow(color: .red.opacity(0.4), radius: 2, x: 0, y: 0)
            }
            .offset(y: CGFloat(minutes) * minuteHeight)
            .accessibilityLabel("Current time")
        }
    }
}

// MARK: - Avatar Circle (kept from original)

private struct AvatarCircle: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)

            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary.opacity(0.9))
                .padding(6)
        }
        .contentShape(Circle())
        .accessibilityLabel("User profile")
    }
}

#Preview {
    ContentView()
        .environmentObject(EventStore())
}
