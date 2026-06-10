import SwiftUI
import Charts

struct ProgressView: View {
    @ObservedObject private var progressStore  = ProgressStore.shared
    @ObservedObject private var workoutStore   = WorkoutStore.shared
    @ObservedObject private var foodLog        = FoodLogStore.shared
    @ObservedObject private var profile        = UserProfile.shared

    @State private var selectedPeriod: ChartPeriod = .month
    @State private var showLogWeight  = false
    @State private var weightInput    = ""

    enum ChartPeriod: String, CaseIterable {
        case week = "1W", month = "1M", threeMonths = "3M"
        var days: Int { switch self { case .week: 7; case .month: 30; case .threeMonths: 90 } }
    }

    private var weightEntries: [WeightEntry] { progressStore.entries(days: selectedPeriod.days) }
    private var recentSessions: [WorkoutSession] { Array(workoutStore.history.prefix(7).reversed()) }

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        streakCard
                        summaryRow
                        weightCard
                        workoutsCard
                        nutritionHistoryCard
                        achievementsCard
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLogWeight) { logWeightSheet }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Progress")
                .font(SBFont.display(28))
                .foregroundColor(.sbTextPrimary)
            Spacer()
            Button {
                weightInput = String(format: "%.1f",
                    progressStore.latestWeight ?? profile.weightKg)
                showLogWeight = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Log Weight")
                        .font(SBFont.caption())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.sbAccent)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        SBCard {
            HStack(spacing: 20) {
                // Current streak
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 60, height: 60)
                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                            Text("\(workoutStore.currentStreak)")
                                .font(SBFont.heading(22))
                                .foregroundColor(.orange)
                        }
                    }
                    Text("Current")
                        .font(SBFont.label(11))
                        .foregroundColor(.sbTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Streak")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)

                    if workoutStore.currentStreak == 0 {
                        Text("Train today to start your streak!")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    } else if workoutStore.currentStreak == 1 {
                        Text("Great start! Come back tomorrow.")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    } else {
                        Text("Keep it going — don't break the chain!")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#FFD700"))
                        Text("Best: \(workoutStore.longestStreak) day\(workoutStore.longestStreak == 1 ? "" : "s")")
                            .font(SBFont.label(11))
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        let unlocked = workoutStore.unlockedAchievements(
            foodLogHasEntries: !foodLog.todayEntries.isEmpty,
            weightLogged: !progressStore.weightEntries.isEmpty
        )
        let locked = Achievement.allCases.filter { !unlocked.contains($0) }

        return SBCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Achievements")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text("\(unlocked.count)/\(Achievement.allCases.count)")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }

                if unlocked.isEmpty && locked.isEmpty {
                    Text("Complete workouts and log food to earn badges.")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                } else {
                    // Unlocked first
                    let all = unlocked + locked
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(all) { achievement in
                            let isUnlocked = unlocked.contains(achievement)
                            AchievementBadge(achievement: achievement, unlocked: isUnlocked)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            SummaryPill(
                icon: "dumbbell.fill",
                value: "\(workoutStore.history.count)",
                label: "Workouts",
                color: .sbAccent
            )
            SummaryPill(
                icon: "flame.fill",
                value: "\(Int(foodLog.dailyCalories(lastDays: 7).map(\.calories).reduce(0, +) / 7)) kcal",
                label: "Avg/day",
                color: .sbGreen
            )
            SummaryPill(
                icon: "scalemass.fill",
                value: progressStore.latestWeight.map { String(format: "%.1f kg", $0) } ?? "—",
                label: "Weight",
                color: Color.orange
            )
        }
    }

    // MARK: - Weight Card

    private var weightCard: some View {
        SBCard {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Body Weight")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)

                        if let w = progressStore.latestWeight {
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", w))
                                    .font(SBFont.display(26))
                                    .foregroundColor(.sbAccent)
                                Text("kg")
                                    .font(SBFont.caption())
                                    .foregroundColor(.sbTextSecondary)
                                if let change = progressStore.weightChange {
                                    changeTag(change)
                                }
                            }
                        } else {
                            Text("Tap + to log your weight")
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                        }
                    }
                    Spacer()
                    periodPicker
                }

                if weightEntries.count >= 2 {
                    weightChart
                } else {
                    emptyChart(
                        icon: "chart.line.uptrend.xyaxis",
                        message: "Log weight on a few days to see your trend"
                    )
                }
            }
        }
    }

    private var weightChart: some View {
        Chart(weightEntries) { entry in
            AreaMark(
                x: .value("Date", entry.date),
                y: .value("kg", entry.weightKg)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.sbAccent.opacity(0.25), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", entry.date),
                y: .value("kg", entry.weightKg)
            )
            .foregroundStyle(Color.sbAccent)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            PointMark(
                x: .value("Date", entry.date),
                y: .value("kg", entry.weightKg)
            )
            .foregroundStyle(Color.sbAccent)
            .symbolSize(30)
        }
        .chartXAxis { weightXAxis }
        .chartYAxis { sbYAxis }
        .frame(height: 160)
    }

    @AxisContentBuilder
    private var weightXAxis: some AxisContent {
        let stride: Calendar.Component = .day
        let count = selectedPeriod == .week ? 2
                  : selectedPeriod == .month ? 7 : 14
        AxisMarks(values: .stride(by: stride, count: count)) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(Color.sbBorder)
            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                .foregroundStyle(Color.sbTextSecondary)
                .font(SBFont.label(10))
        }
    }

    // MARK: - Workouts Card

    private var workoutsCard: some View {
        SBCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Volume")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)
                        Text(recentSessions.isEmpty
                             ? "No workouts yet"
                             : "Last \(recentSessions.count) sessions")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(workoutStore.history.count)")
                            .font(SBFont.heading(22))
                            .foregroundColor(.sbAccent)
                        Text("total")
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                if recentSessions.isEmpty {
                    emptyChart(icon: "dumbbell.fill",
                               message: "Complete a workout to see volume stats")
                } else {
                    Chart(recentSessions) { session in
                        BarMark(
                            x: .value("Session", session.startedAt, unit: .day),
                            y: .value("Volume (kg)", session.totalVolume)
                        )
                        .foregroundStyle(Color.sbAccent.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: min(recentSessions.count, 5))) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(Color.sbTextSecondary)
                                .font(SBFont.label(10))
                        }
                    }
                    .chartYAxis { sbYAxis }
                    .frame(height: 140)
                }
            }
        }
    }

    // MARK: - Nutrition History Card

    private var nutritionHistoryCard: some View {
        let dailyData = foodLog.dailyCalories(lastDays: 7)
        let target = Double(profile.dailyCalorieTarget)
        let logged = dailyData.filter { $0.calories > 0 }
        let avg = logged.isEmpty ? 0.0 : logged.map(\.calories).reduce(0, +) / Double(logged.count)

        return SBCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calories — 7 Days")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)
                        Text(avg > 0 ? "Avg \(Int(avg)) kcal/day" : "No data this week")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(profile.dailyCalorieTarget)")
                            .font(SBFont.heading(22))
                            .foregroundColor(.sbAccent)
                        Text("kcal goal")
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                Chart {
                    ForEach(dailyData, id: \.date) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Calories", item.calories)
                        )
                        .foregroundStyle(
                            (item.calories > 0 && item.calories > target
                                ? Color.sbRed : Color.sbGreen).gradient
                        )
                        .cornerRadius(4)
                    }
                    RuleMark(y: .value("Goal", target))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .foregroundStyle(Color.sbAccent)
                        .annotation(position: .topLeading, spacing: 2) {
                            Text("Goal")
                                .font(SBFont.label(9))
                                .foregroundColor(.sbAccent)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Color.sbTextSecondary)
                            .font(SBFont.label(10))
                    }
                }
                .chartYAxis { sbYAxis }
                .frame(height: 140)
            }
        }
    }

    // MARK: - Shared helpers

    private var periodPicker: some View {
        HStack(spacing: 2) {
            ForEach(ChartPeriod.allCases, id: \.self) { p in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = p }
                } label: {
                    Text(p.rawValue)
                        .font(SBFont.label(11))
                        .foregroundColor(selectedPeriod == p ? .white : .sbTextSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(selectedPeriod == p ? Color.sbAccent : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.sbSurfaceRaised)
        .cornerRadius(9)
    }

    @AxisContentBuilder
    private var sbYAxis: some AxisContent {
        AxisMarks { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(Color.sbBorder)
            AxisValueLabel {
                if let v = value.as(Double.self) {
                    Text(v >= 1000 ? "\(Int(v / 1000))k" : "\(Int(v))")
                        .foregroundStyle(Color.sbTextSecondary)
                        .font(SBFont.label(10))
                }
            }
        }
    }

    private func emptyChart(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.sbBorder)
            Text(message)
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }

    private func changeTag(_ change: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: change <= 0 ? "arrow.down" : "arrow.up")
            Text(String(format: "%.1f", abs(change)))
        }
        .font(SBFont.label(11))
        .foregroundColor(change <= 0 ? .sbGreen : .sbRed)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((change <= 0 ? Color.sbGreen : Color.sbRed).opacity(0.12))
        .cornerRadius(6)
    }

    // MARK: - Log Weight Sheet

    private var logWeightSheet: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.sbBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Text("Log Weight")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                TextField("0.0", text: $weightInput)
                    .font(SBFont.display(52))
                    .foregroundColor(.sbAccent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
                Text("kg")
                    .font(SBFont.heading(22))
                    .foregroundColor(.sbTextSecondary)
            }

            HStack(spacing: 10) {
                ForEach([-1.0, -0.5, 0.5, 1.0], id: \.self) { delta in
                    Button {
                        let cleaned = weightInput.replacingOccurrences(of: ",", with: ".")
                        if let cur = Double(cleaned) {
                            weightInput = String(format: "%.1f", max(20, cur + delta))
                        }
                    } label: {
                        Text(delta > 0 ? "+\(String(format: "%.1f", delta))"
                                      :     String(format: "%.1f", delta))
                            .font(SBFont.caption())
                            .foregroundColor(.sbAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.sbSurfaceRaised)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            SBPrimaryButton(title: "Save") {
                let cleaned = weightInput.replacingOccurrences(of: ",", with: ".")
                if let kg = Double(cleaned), kg > 20 {
                    HapticManager.success()
                    progressStore.addEntry(weightKg: kg)
                }
                showLogWeight = false
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.sbBackground)
        .presentationDetents([.height(380)])
    }
}

// MARK: - Summary Pill

private struct SummaryPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .cornerRadius(10)
            Text(value)
                .font(SBFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder, lineWidth: 1))
    }
}

// MARK: - Achievement Badge

private struct AchievementBadge: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(unlocked ? achievement.color.opacity(0.15) : Color.sbSurfaceRaised)
                    .frame(width: 40, height: 40)
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(unlocked ? achievement.color : Color.sbBorder)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(SBFont.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(unlocked ? .sbTextPrimary : .sbTextSecondary)
                    .lineLimit(1)
                Text(achievement.description)
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(unlocked ? achievement.color.opacity(0.05) : Color.sbSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(unlocked ? achievement.color.opacity(0.3) : Color.sbBorder, lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.45)
    }
}
