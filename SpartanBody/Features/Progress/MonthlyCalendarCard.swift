import SwiftUI

// Monthly calendar showing daily goal completion as fitness-ring style cells.
// Each day's ring fills based on how many goals were met that day:
// calories within target, water 8+ glasses, at least one workout.
struct MonthlyCalendarCard: View {
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var workouts = WorkoutStore.shared
    @ObservedObject private var foodLog  = FoodLogStore.shared

    @State private var displayedMonth: Date = .now

    private let calendar = Calendar.current

    var body: some View {
        SBCard {
            VStack(spacing: 14) {
                header
                weekdayHeader
                daysGrid
                summaryRow
                legend
            }
        }
    }

    // MARK: - Header (month navigation)

    private var header: some View {
        HStack {
            Text("Monthly Progress")
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextPrimary)
            Spacer()
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.sbAccent)
                    .frame(width: 30, height: 30)
                    .background(Color.sbSurfaceRaised)
                    .clipShape(Circle())
            }
            Text(monthTitle)
                .font(SBFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
                .frame(minWidth: 90)
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(canGoForward ? .sbAccent : .sbTextSecondary.opacity(0.4))
                    .frame(width: 30, height: 30)
                    .background(Color.sbSurfaceRaised)
                    .clipShape(Circle())
            }
            .disabled(!canGoForward)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: displayedMonth).capitalized
    }

    private var canGoForward: Bool {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return calendar.startOfMonth(for: next) <= calendar.startOfMonth(for: .now)
    }

    private func changeMonth(by delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.22)) { displayedMonth = d }
            HapticManager.light()
        }
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(localizedShortWeekdays, id: \.self) { day in
                Text(day)
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var localizedShortWeekdays: [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        let raw = f.veryShortStandaloneWeekdaySymbols ?? f.shortStandaloneWeekdaySymbols ?? []
        // Rotate to start at Monday if the user's locale wants Sunday-first; we use the calendar setting.
        let first = calendar.firstWeekday - 1  // 1-based -> 0-based
        return Array(raw[first...]) + Array(raw[..<first])
    }

    // MARK: - Days grid

    private var daysGrid: some View {
        let days = makeMonthDays()
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
            spacing: 6
        ) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isToday  = calendar.isDateInToday(day)
        let isFuture = day > .now
        let stats    = dayStats(day)
        let dayNum   = calendar.component(.day, from: day)

        return VStack(spacing: 2) {
            Text("\(dayNum)")
                .font(SBFont.label(10))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isFuture ? .sbTextSecondary.opacity(0.35) : .sbTextSecondary)

            ZStack {
                // Background track
                Circle()
                    .stroke(Color.sbSurfaceRaised, lineWidth: 3)
                    .frame(width: 26, height: 26)

                if !isFuture {
                    // 3 concentric arcs: outer = calories, middle = water, inner = workout (full or empty)
                    ringArc(progress: stats.calorieProgress, color: .sbAccent, diameter: 26)
                    ringArc(progress: stats.waterProgress,   color: .sbCyan,   diameter: 20)
                    ringArc(progress: stats.workoutDone ? 1 : 0,
                            color: .orange, diameter: 14)
                }

                if isToday {
                    Circle()
                        .stroke(Color.sbAccent, lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                }
            }
            .frame(height: 30)
        }
    }

    private func ringArc(progress: Double, color: Color, diameter: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: min(progress, 1.0))
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: diameter, height: diameter)
    }

    // MARK: - Day stats

    private struct DayStats {
        let calorieProgress: Double  // 0-1
        let waterProgress:   Double
        let workoutDone:     Bool
    }

    private func dayStats(_ day: Date) -> DayStats {
        let cal = calendar
        let dayKey = DateFormatter.sbDateKey.string(from: day)

        let kcal = foodLog.totalCalories(for: day)
        let calorieProgress = profile.dailyCalorieTarget > 0
            ? kcal / Double(profile.dailyCalorieTarget)
            : 0

        let glasses = UserDefaults.standard.integer(forKey: "sb_water_\(dayKey)")
        let waterProgress = Double(glasses) / 8.0

        let workoutDone = workouts.history.contains { session in
            cal.isDate(session.startedAt, inSameDayAs: day)
                && session.finishedAt != nil
        }

        return DayStats(
            calorieProgress: calorieProgress,
            waterProgress:   waterProgress,
            workoutDone:     workoutDone
        )
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        let stats = monthSummary()
        return HStack(spacing: 0) {
            statBox(value: "\(stats.workoutCount)",  label: "Workouts")
            Divider().frame(height: 32).background(Color.sbBorder)
            statBox(value: "\(stats.calorieDays)",   label: "Goal days")
            Divider().frame(height: 32).background(Color.sbBorder)
            statBox(value: "\(stats.bestStreak)",    label: "Best streak")
        }
        .padding(.top, 4)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SBFont.heading(18))
                .foregroundColor(.sbAccent)
                .monospacedDigit()
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private struct MonthSummary {
        let workoutCount: Int
        let calorieDays:  Int  // days the user logged within +/-15% of target
        let bestStreak:   Int  // longest run of consecutive "good" days
    }

    private func monthSummary() -> MonthSummary {
        let cal = calendar
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else {
            return MonthSummary(workoutCount: 0, calorieDays: 0, bestStreak: 0)
        }

        var workoutCount = 0
        var calorieDays  = 0
        var bestStreak   = 0
        var currentStreak = 0

        var day = interval.start
        while day < interval.end && day <= Date() {
            let stats = dayStats(day)
            if stats.workoutDone { workoutCount += 1 }

            let target = Double(profile.dailyCalorieTarget)
            let kcal   = foodLog.totalCalories(for: day)
            let metCalories = target > 0 && kcal >= target * 0.85 && kcal <= target * 1.15
            if metCalories { calorieDays += 1 }

            let allGoodToday = metCalories && stats.waterProgress >= 1.0 && stats.workoutDone
            if allGoodToday {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }

            day = cal.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }

        return MonthSummary(
            workoutCount: workoutCount,
            calorieDays:  calorieDays,
            bestStreak:   bestStreak
        )
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            legendDot(color: .sbAccent, label: "Calories")
            legendDot(color: .sbCyan,   label: "Water")
            legendDot(color: .orange,   label: "Workout")
        }
        .frame(maxWidth: .infinity)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().stroke(color, lineWidth: 2).frame(width: 9, height: 9)
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
    }

    // MARK: - Month days array (with leading/trailing nils to align weekday columns)

    private func makeMonthDays() -> [Date?] {
        let cal = calendar
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }

        let firstDay = interval.start
        let daysInMonth = cal.range(of: .day, in: .month, for: firstDay)?.count ?? 30

        // How many empty slots before day 1 to align with the first weekday column.
        let weekdayOfFirst = cal.component(.weekday, from: firstDay)  // 1-based, Sunday=1
        let firstWeekdayIndex = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: firstWeekdayIndex)
        for i in 0..<daysInMonth {
            cells.append(cal.date(byAdding: .day, value: i, to: firstDay))
        }
        // Pad to full weeks (multiples of 7) so the grid stays rectangular.
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

// MARK: - Helpers

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

private extension DateFormatter {
    static let sbDateKey: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
