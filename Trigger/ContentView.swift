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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("green_L1"), Color("green_L2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header with avatar on the left and title shifted slightly right
                HStack(spacing: 12) {
                    // Placeholder avatar until we wire a real user image
                    AvatarCircle()
                        .frame(width: 36, height: 36)

                    Text("Today's Schedule")
                        .foregroundColor(Color("green_L4"))
                        .font(.system(.title, design: .rounded).bold())
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 2) // slight right shift
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)

                // Events section
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        ForEach(anchorEventsForToday) { anchor in
                            EventRowWithHabits(
                                anchor: anchor,
                                habits: habitsAttached(to: anchor.id)
                            )
                            .padding(.horizontal, 20)
                        }

                        if anchorEventsForToday.isEmpty {
                            Text("No events for today")
                                .font(.system(.callout, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 120) // leave space for FAB
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // Floating action area overlay
        .overlay(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomTrailing) {
                // Tappable dim background when expanded (optional subtlety)
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
                    // Calendar button at a 45-degree angle up-left
                    glassButton(
                        systemName: "calendar",
                        cornerRadius: buttonCornerRadius,
                        size: buttonSize
                    ) {
                        // Calendar action
                        withAnimation(expandAnimation) {
                            isExpanded = false
                        }
                        // Present AddEvent modal
                        isPresentingAddEvent = true
                    }
                    .offset(satelliteOffset(angleDegrees: 45, distance: satelliteDistance))
                    .scaleEffect(isExpanded ? 1 : 0.6)
                    .opacity(isExpanded ? 1 : 0)
                    .rotationEffect(.degrees(isExpanded ? 0 : -12))
                    .animation(expandAnimation, value: isExpanded)

                    // Checkmark button at a 0 + 90 = 90-degree angle (straight up)
                    glassButton(
                        systemName: "checkmark",
                        cornerRadius: buttonCornerRadius,
                        size: buttonSize
                    ) {
                        // Checkmark action
                        withAnimation(expandAnimation) {
                            isExpanded = false
                        }
                        // Present AddHabit modal
                        isPresentingAddHabit = true
                    }
                    .offset(satelliteOffset(angleDegrees: 90, distance: satelliteDistance))
                    .scaleEffect(isExpanded ? 1 : 0.6)
                    .opacity(isExpanded ? 1 : 0)
                    .rotationEffect(.degrees(isExpanded ? 0 : -12))
                    .animation(expandAnimation, value: isExpanded)
                }
                .allowsHitTesting(isExpanded) // only interactive when visible

                // Main "+" button (stays fixed bottom-right)
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
                        .rotationEffect(.degrees(isExpanded ? 45 : 0)) // subtle affordance
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
                // Treat habit as an Event and add it to the shared store
                eventStore.add(newHabit)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Derived data

    private var anchorEventsForToday: [Event] {
        eventStore.eventsForToday.filter { !$0.isHabit }
    }

    private func habitsAttached(to anchorID: UUID) -> [Event] {
        eventStore.eventsForToday.filter {
            $0.isHabit && $0.anchorEventID == anchorID
        }
    }

    // MARK: - Helpers

    // Creates the glass background used by all buttons
    private func glassBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0), lineWidth: 1)
            )
    }

    // A reusable glass button with a system image
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

    // Computes offset for a button placed at angle (degrees) and distance from the anchor (bottom-right)
    private func satelliteOffset(angleDegrees: CGFloat, distance: CGFloat) -> CGSize {
        let radians = angleDegrees * .pi / 180
        // Negative x to move left from bottom-right anchor, negative y to move up
        let dx = -cos(radians) * distance
        let dy = -sin(radians) * distance
        return CGSize(width: dx, height: dy)
    }
}

// MARK: - Event Row with Habit Bubbles

private struct EventRowWithHabits: View {
    let anchor: Event
    let habits: [Event]

    private let cornerRadius: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Add top/bottom padding if there are habits to clearly separate
            EventCard(event: anchor)
                .padding(.top, hasBefore ? 10 : 0)
                .padding(.bottom, hasAfter ? 10 : 0)

            // Before bubbles above the card with natural spacing
            if hasBefore {
                FlowBubbles(habits: habits.filter { $0.attachPosition == .before }, style: .before)
                    .padding(.bottom, 4)
            }

            // After bubbles below the card with natural spacing
            if hasAfter {
                FlowBubbles(habits: habits.filter { $0.attachPosition == .after }, style: .after)
                    .padding(.top, 4)
            }
        }
    }

    private var hasBefore: Bool {
        habits.contains { $0.attachPosition == .before }
    }

    private var hasAfter: Bool {
        habits.contains { $0.attachPosition == .after }
    }
}

// A simple flow layout using Wrap in an HStack/VStack combo to avoid overlap/clutter
private struct FlowBubbles: View {
    let habits: [Event]
    let style: HabitBubble.Style

    var body: some View {
        // Use a simple flexible layout that wraps if needed to avoid stacking clutter
        FlexibleWrap(data: habits, spacing: 6, lineSpacing: 6) { habit in
            HabitBubble(habit: habit, style: style)
        }
    }
}

// MARK: - Habit Bubble

private struct HabitBubble: View {
    enum Style {
        case before, after
    }

    let habit: Event
    let style: Style

    var body: some View {
        HStack(spacing: 8) {
            // Removed checkmark icon per requirement
            Text(habit.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(borderColor.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 8, x: 0, y: style == .before ? -2 : 4)
    }

    private var borderColor: Color {
        switch style {
        case .before: return .white
        case .after: return .black
        }
    }

    private var shadowColor: Color {
        switch style {
        case .before: return .black.opacity(0.08)
        case .after: return .black.opacity(0.12)
        }
    }
}

// MARK: - Event Card (glass style)

private struct EventCard: View {
    let event: Event
    private let cornerRadius: CGFloat = 18

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Time(s) on the left
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeRangeText)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 84, alignment: .trailing)

            // Title in the middle (now can use more space)
            Text(event.title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if let end = event.endTime {
            return "\(formatter.string(from: event.startTime))\n\(formatter.string(from: end))"
        } else {
            return formatter.string(from: event.startTime)
        }
    }
}

// A lightweight flexible wrap layout to keep bubbles from overlapping or stacking unreadably.
private struct FlexibleWrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (Data.Element) -> Content

    init(data: Data, spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(data) { item in
                    content(item)
                        .padding(.trailing, spacing)
                        .padding(.bottom, lineSpacing)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height + lineSpacing
                            }
                            let result = width
                            width -= d.width + spacing
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            return result
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 0)
    }
}

// MARK: - Avatar Circle (placeholder)

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
