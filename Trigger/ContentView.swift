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
    @State private var navigateToEditDebug = false

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

    // Deletion confirmation state
    @State private var eventPendingDeletion: Event? = nil
    @State private var showDeleteDialog: Bool = false

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
                        eventMinDurationMinutes: eventMinDurationMinutes,
                        onLongPressEvent: { event in
                            eventPendingDeletion = event
                            showDeleteDialog = true
                        },
                        onTapDelete: { event in
                            eventPendingDeletion = event
                            showDeleteDialog = true
                        }
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

                        // New pencil button
                        glassButton(
                            systemName: "pencil",
                            cornerRadius: buttonCornerRadius,
                            size: buttonSize
                        ) {
                            withAnimation(expandAnimation) {
                                isExpanded = false
                            }
                            navigateToEditDebug = true
                        }
                        .offset(satelliteOffset(angleDegrees: 360, distance: satelliteDistance))
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
            // Confirmation dialog for deleting an event
            .confirmationDialog(
                "Delete this event?",
                isPresented: $showDeleteDialog,
                presenting: eventPendingDeletion,
                actions: { event in
                    Button("Delete", role: .destructive) {
                        eventStore.delete(id: event.id)
                        eventPendingDeletion = nil
                    }
                    Button("Cancel", role: .cancel) {
                        eventPendingDeletion = nil
                    }
                },
                message: { event in
                    Text("“\(event.title)” will be removed from your schedule and from this device.")
                }
            )
            // Hidden navigation trigger to EditDebugView
            .background(
                NavigationLink(
                    destination: EditView()
                        .toolbar(.hidden, for: .navigationBar),
                    isActive: $navigateToEditDebug
                ) {
                    EmptyView()
                }
                .hidden()
            )
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
    var onLongPressEvent: (Event) -> Void
    var onTapDelete: (Event) -> Void

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
                        eventMinDurationMinutes: eventMinDurationMinutes,
                        onLongPressEvent: onLongPressEvent,
                        onTapDelete: onTapDelete
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
        var onLongPressEvent: (Event) -> Void
        var onTapDelete: (Event) -> Void

        var body: some View {
            // Fixed 24-hour canvas height so children do not expand the container
            let canvasHeight = minuteHeight * 60 * 24

            GeometryReader { geo in
                // Full width available for the track (includes left rail)
                let trackWidth = geo.size.width

                ZStack(alignment: .topLeading) {
                    // Absolutely position each non-habit event at its y
                    ForEach(positionedEvents) { pe in
                        EventBlock(
                            event: pe.event,
                            y: pe.y,
                            height: pe.height,
                            hourLabelWidth: hourLabelWidth,
                            onLongPress: { onLongPressEvent(pe.event) },
                            onTapDelete: { onTapDelete(pe.event) }
                        )
                        // Ensure independent absolute placement
                        .position(x: trackWidth / 2, y: pe.y + pe.height / 2)
                        .frame(width: trackWidth, height: pe.height, alignment: .topLeading)
                        .allowsHitTesting(true)
                        .zIndex(Double(pe.column))
                    }

                    // Habits are also absolutely positioned relative to their anchor’s visual frame
                    ForEach(positionedEvents) { pe in
                        ForEach(habitsAttached(to: pe.event)) { hb in
                            let habitFrame = habitFrame(for: hb, anchorY: pe.y, anchorHeight: pe.height)
                            HabitBlock(
                                habit: hb,
                                y: habitFrame.y,
                                height: habitFrame.height,
                                hourLabelWidth: hourLabelWidth,
                                rightOutset: habitRightOutset,
                                alignToTop: hb.attachPosition == .before
                            )
                            .position(x: trackWidth / 2, y: habitFrame.y + habitFrame.height / 2)
                            .frame(width: trackWidth, height: habitFrame.height, alignment: .topLeading)
                            .zIndex(Double(pe.column) + 0.5)
                        }
                    }
                }
                .frame(width: trackWidth, height: canvasHeight, alignment: .topLeading)
            }
            .frame(height: minuteHeight * 60 * 24) // lock outer height too
        }

        // MARK: - Layout constants for habits

        // Habit visual height; smaller than events
        private var habitVisualHeight: CGFloat { 28 }
        // Slight outward offset to the right
        private var habitRightOutset: CGFloat { 6 }
        // Inset from event block right edge so it appears contained
        private var habitRightInsetInsideEvent: CGFloat { 10 }
        // Inset from event block left edge so it sits on the right side
        private var habitLeftInsetInsideEvent: CGFloat { 56 }

        // MARK: - Data slicing

        private var positionedEvents: [PositionedEvent] {
            nonHabitEvents.map { e in
                let start = minutesSinceMidnight(e.startTime)
                let endMinutes = e.endTime.map { minutesSinceMidnight($0) }
                // Ensure y is always based solely on start, and duration uses a minimum when end is missing
                let minEndIfMissing = start + eventMinDurationMinutes
                let effectiveEnd = endMinutes ?? minEndIfMissing
                let duration = max(effectiveEnd - start, eventMinDurationMinutes)

                let y = CGFloat(start) * minuteHeight
                let height = CGFloat(duration) * minuteHeight
                return PositionedEvent(event: e, y: y, height: height, column: 0)
           
            }
        }

        private var nonHabitEvents: [Event] {
            events.filter { !$0.isHabit }
        }

        private func habitsAttached(to anchor: Event) -> [Event] {
            events.filter { $0.isHabit && $0.anchorEventID == anchor.id }
                .sorted { a, b in
                    // top-first for consistent stacking
                    (a.attachPosition == .before ? 0 : 1) < (b.attachPosition == .before ? 0 : 1)
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
            return (h * 60 + m)
        }

        // Compute the frame for a habit relative to its anchor event’s visual block
        private func habitFrame(for habit: Event, anchorY: CGFloat, anchorHeight: CGFloat) -> (y: CGFloat, height: CGFloat) {
            // Align to top or bottom edge depending on attachPosition
            let alignTop = (habit.attachPosition == .before)
            // Small vertical nudge: before -> up, after -> down
            let nudge: CGFloat = 8
            let baseY = alignTop ? anchorY - 1 : (anchorY + anchorHeight - habitVisualHeight + 1)
            let adjustedY = alignTop ? (baseY - nudge) : (baseY + nudge)
            return (y: adjustedY, height: habitVisualHeight)
        }
    }

    // Event block card
    private struct EventBlock: View {
        let event: Event
        let y: CGFloat
        let height: CGFloat
        let hourLabelWidth: CGFloat
        var onLongPress: () -> Void
        var onTapDelete: () -> Void

        @GestureState private var isPressed: Bool = false

        var body: some View {
            // Gesture to reflect immediate press state (for scaling)
            let pressGesture = LongPressGesture(minimumDuration: 0)
                .updating($isPressed) { current, state, _ in
                    state = current
                }

            // Actual long-press action gesture
            let actionGesture = LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }

            // Right margin to ensure the trash icon stays comfortably visible
            let rightMargin: CGFloat = 16

            // Build a single-layer container with intrinsic width equal to full track width.
            ZStack(alignment: .topLeading) {
                // Left rail spacer area (non-interactive)
                Color.clear
                    .frame(width: hourLabelWidth)
                    .frame(maxHeight: .infinity, alignment: .topLeading)

                // Event card with constrained width
                GeometryReader { geo in
                    // geo.size.width here is the width of the full track area for this row
                    let fullWidth = geo.size.width
                    // Subtract the time rail and a right margin so the card is slightly narrower
                    // Keep the existing 8pt left gap from the rail.
                    let cardWidth = max(0, fullWidth - (hourLabelWidth + 8 + rightMargin))

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(event.title)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Trash button
                            Button {
                                onTapDelete()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete event")
                            .accessibilityHint("Shows a confirmation to delete this event")
                        }
                        .padding(12)

                        Spacer(minLength: 0)
                    }
                    .frame(width: cardWidth, alignment: .leading)
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
                    .offset(x: hourLabelWidth + 8) // push card to the right of the time rail
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: max(height, 44), alignment: .topLeading)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isPressed)
            .gesture(pressGesture.simultaneously(with: actionGesture))
        }
    }

    // Habit block card (smaller, transparent green, right-aligned and slightly sticking out)
    private struct HabitBlock: View {
        let habit: Event
        let y: CGFloat
        let height: CGFloat
        let hourLabelWidth: CGFloat
        let rightOutset: CGFloat
        let alignToTop: Bool

        var body: some View {
            GeometryReader { geo in
                // Full track width available to events
                let trackWidth = geo.size.width
                // Desired intrinisic width logic retained; centered horizontally
                let leftInset: CGFloat = 56
                let rightInset: CGFloat = 10
                let availableWidth = max(120, trackWidth - leftInset - rightInset)
                let habitWidth = availableWidth * 0.7

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color("green_L5").opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.green.opacity(0.18), radius: 6, x: 0, y: 3)

                    Text(habit.title)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color("green_L5").opacity(0.9))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                }
                .frame(width: habitWidth, height: height, alignment: .leading)
                // Center horizontally within the track
                .position(x: trackWidth / 2, y: height / 2)
            }
            .frame(height: height)
            .accessibilityLabel("Habit: \(habit.title)")
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
            return ZStack(alignment: .topLeading) {
                // left rail spacer
                Color.clear
                    .frame(width: hourLabelWidth)
                Rectangle()
                    .fill(Color.red.opacity(0.9))
                    .frame(height: 2)
                    .shadow(color: .red.opacity(0.4), radius: 2, x: 0, y: 0)
                    .offset(x: hourLabelWidth + 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

