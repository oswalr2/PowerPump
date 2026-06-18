import SwiftUI
import Charts

struct WeightChartCard: View {
    @ObservedObject private var progress = ProgressStore.shared
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var foodLog  = FoodLogStore.shared
    @State private var range: Range = .month

    enum Range: String, CaseIterable, Identifiable {
        case month   = "30D"
        case quarter = "90D"
        var id: String { rawValue }
        var days: Int { self == .month ? 30 : 90 }
    }

    private var entries: [WeightEntry] { progress.entries(days: range.days) }

    private var minY: Double {
        let v = entries.map(\.weightKg).min() ?? profile.weightKg
        return floor(v - 1)
    }

    private var maxY: Double {
        let v = entries.map(\.weightKg).max() ?? profile.weightKg
        return ceil(v + 1)
    }

    // Average daily calorie balance over the last 7 days → projected weekly
    // change in kg (1 kg ≈ 7700 kcal). Positive means losing.
    private var weeklyProjectionKg: Double {
        let days = foodLog.dailyCalories(lastDays: 7)
        let avgIntake = days.map(\.calories).reduce(0, +) / Double(max(days.count, 1))
        guard avgIntake > 0 else { return 0 }
        let tdee = Double(profile.dailyCalorieTarget) - Double(profile.goal.dailyCalorieAdjustment)
        let dailyDeficit = tdee - avgIntake
        return dailyDeficit * 7 / 7700.0
    }

    var body: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                if entries.isEmpty {
                    emptyState
                } else {
                    chart
                    projectionRow
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", profile.weightKg))
                        .font(SBFont.heading(22))
                        .foregroundColor(.sbTextPrimary)
                        .monospacedDigit()
                    Text("kg")
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                }
                if let delta = progress.weightChange {
                    Text(delta >= 0
                         ? String(format: "+%.1f kg", delta)
                         : String(format: "%.1f kg", delta))
                        .font(SBFont.label(11))
                        .foregroundColor(delta == 0 ? .sbTextSecondary
                                        : (delta < 0 ? .sbGreen : .sbRed))
                }
            }
            Spacer()
            rangePicker
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(Range.allCases) { r in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { range = r }
                } label: {
                    Text(r.rawValue)
                        .font(SBFont.label(11))
                        .foregroundColor(range == r ? .white : .sbTextSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(range == r ? Color.sbAccent : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.sbSurfaceRaised)
        .cornerRadius(10)
    }

    private var chart: some View {
        Chart {
            // Target weight reference line
            RuleMark(y: .value("Target", profile.targetWeightKg))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundStyle(Color.sbAccent.opacity(0.5))
                .annotation(position: .top, alignment: .leading) {
                    Text("Target")
                        .font(SBFont.label(9))
                        .foregroundColor(.sbAccent)
                }

            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightKg)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.sbAccent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightKg)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.sbAccent.opacity(0.35), Color.sbAccent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 160)
        .chartYScale(domain: minY...maxY)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.sbTextSecondary.opacity(0.18))
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text("\(Int(v))")
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary.opacity(0.7))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { val in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated),
                               centered: false)
                    .font(SBFont.label(10))
                    .foregroundStyle(Color.sbTextSecondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 28))
                .foregroundColor(.sbTextSecondary.opacity(0.5))
            Text("No weight history yet")
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
            Text("Tap Log Weight to start your history.")
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var projectionRow: some View {
        HStack(spacing: 8) {
            Image(systemName: weeklyProjectionKg >= 0 ? "arrow.down.right" : "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(weeklyProjectionKg >= 0 ? .sbGreen : .sbRed)
            Text("At current pace")
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
            Spacer()
            Text(projectionLabel)
                .font(SBFont.label(11))
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
        }
        .padding(10)
        .background(Color.sbSurfaceRaised)
        .cornerRadius(10)
    }

    private var projectionLabel: String {
        let kg = abs(weeklyProjectionKg)
        if kg < 0.05 { return "Maintaining weight" }
        let sign = weeklyProjectionKg < 0 ? "+" : "-"
        return "\(sign)\(String(format: "%.2f", kg)) kg / week"
    }
}
