import SwiftUI

// MARK: - Weekly Recap card (shown on Mondays, otherwise hidden)

struct WeeklyRecapCard: View {
    let recap: CoachInsightsService.WeeklyRecap

    private var workoutProgress: Double {
        recap.workoutsPlanned > 0
            ? min(Double(recap.workoutsDone) / Double(recap.workoutsPlanned), 1.0)
            : 0
    }

    private var calorieProgress: Double {
        recap.calorieTarget > 0
            ? min(Double(recap.avgDailyCalories) / Double(recap.calorieTarget), 1.0)
            : 0
    }

    var body: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundColor(.sbAccent)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Your week in review")
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text(recap.weekRange)
                        .font(SBFont.label(11))
                        .foregroundColor(.sbTextSecondary)
                }

                // Highlight banner — one positive thing
                if !recap.highlight.isEmpty {
                    HStack(spacing: 8) {
                        Text("✨").font(.system(size: 16))
                        Text(LocalizedStringKey(recap.highlight))
                            .font(SBFont.body())
                            .foregroundColor(.sbTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient.sbAccentGradient.opacity(0.15))
                    .cornerRadius(12)
                }

                // Metrics
                VStack(spacing: 12) {
                    metricRow(
                        icon: "dumbbell.fill",
                        color: .sbAccent,
                        label: "Workouts",
                        value: "\(recap.workoutsDone)/\(recap.workoutsPlanned)",
                        progress: workoutProgress
                    )
                    metricRow(
                        icon: "flame.fill",
                        color: .orange,
                        label: "Avg calories/day",
                        value: recap.avgDailyCalories > 0
                            ? "\(recap.avgDailyCalories) / \(recap.calorieTarget) kcal"
                            : "—",
                        progress: calorieProgress
                    )
                    metricRow(
                        icon: "drop.fill",
                        color: .sbCyan,
                        label: "Avg water/day",
                        value: recap.avgWater > 0
                            ? String(format: "%.1f / 8", recap.avgWater)
                            : "—",
                        progress: min(recap.avgWater / 8.0, 1.0)
                    )
                    if let delta = recap.weightChange {
                        let symbol = delta < 0 ? "arrow.down" : "arrow.up"
                        let label  = delta < 0 ? "Lost this week" : "Gained this week"
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.sbAccent)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            Text(LocalizedStringKey(label))
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                            Spacer()
                            HStack(spacing: 3) {
                                Image(systemName: symbol)
                                    .font(.system(size: 11, weight: .bold))
                                Text(String(format: "%.1f kg", abs(delta)))
                                    .font(SBFont.caption())
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(delta < 0 ? .sbGreen : .orange)
                        }
                    }
                }
            }
        }
    }

    private func metricRow(icon: String, color: Color,
                            label: String, value: String,
                            progress: Double) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 13))
                    .frame(width: 18)
                Text(LocalizedStringKey(label))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                Spacer()
                Text(value)
                    .font(SBFont.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
            }
            SBProgressBar(progress: progress, color: color)
        }
    }
}

// MARK: - Coach Alert banner (proactive notification)

struct CoachAlertBanner: View {
    let alert: CoachInsightsService.CoachAlert

    private var tintColor: Color {
        switch alert.tint {
        case .info:    return .sbAccent
        case .warn:    return .orange
        case .success: return .sbGreen
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: alert.icon)
                    .foregroundColor(tintColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(alert.title))
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                Text(LocalizedStringKey(alert.body))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tintColor.opacity(0.4), lineWidth: 1.2)
        )
    }
}
