//
//  HistoryView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 04/11/2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<MeditationSession> { session in
            session.completed
        },
        sort: \MeditationSession.startTime,
        order: .reverse
    ) private var completedSessions: [MeditationSession]

    @State private var selectedMonth = Date()
    @State private var selectedDate: Date? = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Card
                        StatsCard(completedSessions: completedSessions)
                            .padding(.horizontal)
                            .padding(.top)

                        // Calendar
                        VStack(spacing: 16) {
                            // Month selector
                            HStack {
                                Button {
                                    changeMonth(by: -1)
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.purple)
                                }

                                Spacer()

                                Text(monthYearString(from: selectedMonth))
                                    .font(.title3.bold())

                                Spacer()

                                Button {
                                    changeMonth(by: 1)
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal)

                            // Weekday headers
                            HStack {
                                ForEach(weekdaySymbols, id: \.self) { day in
                                    Text(day)
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)

                            // Calendar grid
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(daysInMonth, id: \.self) { date in
                                    if let date = date {
                                        DayCell(
                                            date: date,
                                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                                            sessionsCount: sessionsCount(for: date)
                                        )
                                        .onTapGesture {
                                            selectedDate = date
                                        }
                                    } else {
                                        Color.clear
                                            .frame(height: 44)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)

                        // Sessions list for selected date
                        if let selectedDate = selectedDate {
                            SessionsList(
                                date: selectedDate,
                                sessions: sessions(for: selectedDate)
                            )
                            .padding(.horizontal)
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helper Functions

    private var weekdaySymbols: [String] {
        calendar.veryShortWeekdaySymbols
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let daysCount = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 0
        var days: [Date?] = []

        // Add empty cells for days before month starts
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let emptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: emptyDays))

        // Add actual days
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(date)
            }
        }

        return days
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
            selectedDate = nil
        }
    }

    private func sessionsCount(for date: Date) -> Int {
        completedSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }.count
    }

    private func sessions(for date: Date) -> [MeditationSession] {
        completedSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let sessionsCount: Int

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .purple : .primary))

            if sessionsCount > 0 {
                Circle()
                    .fill(isSelected ? .white : .purple)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.purple : (isToday ? Color.purple.opacity(0.1) : Color.clear))
        )
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let completedSessions: [MeditationSession]

    private var totalMinutes: Int {
        completedSessions.reduce(0) { total, session in
            total + Int(session.duration / 60)
        }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedSessions = completedSessions.sorted { $0.startTime > $1.startTime }

        guard !sortedSessions.isEmpty else { return 0 }

        var streak = 0
        var currentDate = Date()

        for session in sortedSessions {
            if calendar.isDate(session.startTime, inSameDayAs: currentDate) {
                if streak == 0 {
                    streak = 1
                }
            } else if calendar.isDate(session.startTime, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                streak += 1
                currentDate = session.startTime
            } else {
                break
            }
        }

        return streak
    }

    var body: some View {
        HStack(spacing: 20) {
            StatBox(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: "Day Streak",
                color: .orange
            )

            StatBox(
                icon: "checkmark.circle.fill",
                value: "\(completedSessions.count)",
                label: "Total Sessions",
                color: .green
            )

            StatBox(
                icon: "clock.fill",
                value: "\(totalMinutes)",
                label: "Minutes",
                color: .blue
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sessions List

struct SessionsList: View {
    let date: Date
    let sessions: [MeditationSession]

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatter.string(from: date))
                .font(.headline)
                .padding(.horizontal)

            if sessions.isEmpty {
                Text("No meditation sessions on this day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: MeditationSession

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType)
                    .font(.headline)

                Text(timeFormatter.string(from: session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(session.duration / 60)) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: MeditationSession.self, inMemory: true)
}
