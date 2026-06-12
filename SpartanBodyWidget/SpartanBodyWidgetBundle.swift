import WidgetKit
import SwiftUI
import ActivityKit

@main
struct SpartanBodyWidgets: WidgetBundle {
    var body: some Widget {
        SpartanDashboardWidget()
        WorkoutLiveActivity()
    }
}

// MARK: - Shared style (self-contained — the extension doesn't link app code)

private extension Color {
    static let wAccent = Color(red: 0.04, green: 0.52, blue: 1.0)    // #0A84FF
    static let wCyan   = Color(red: 0.20, green: 0.84, blue: 0.91)   // #32D5E8
}

private let appGroupID = "group.com.oswaldo.spartanbody"

// MARK: - Dashboard widget (home screen + lock screen)

struct DashboardEntry: TimelineEntry {
    let date: Date
    let calories: Int
    let calorieTarget: Int
    let protein: Int
    let proteinTarget: Int
    let water: Int
    let streak: Int

    var progress: Double {
        calorieTarget > 0 ? min(Double(calories) / Double(calorieTarget), 1.0) : 0
    }

    static let placeholder = DashboardEntry(date: .now, calories: 1240, calorieTarget: 2900,
                                            protein: 96, proteinTarget: 150, water: 5, streak: 7)
}

struct DashboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (DashboardEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DashboardEntry>) -> Void) {
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(refresh)))
    }

    private func currentEntry() -> DashboardEntry {
        let d = UserDefaults(suiteName: appGroupID)
        return DashboardEntry(
            date: .now,
            calories:      d?.integer(forKey: "watch_calories") ?? 0,
            calorieTarget: max(d?.integer(forKey: "watch_calorieTarget") ?? 2000, 1),
            protein:       d?.integer(forKey: "watch_protein") ?? 0,
            proteinTarget: max(d?.integer(forKey: "watch_proteinTarget") ?? 150, 1),
            water:         d?.integer(forKey: "watch_water") ?? 0,
            streak:        d?.integer(forKey: "watch_streak") ?? 0
        )
    }
}

struct SpartanDashboardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpartanDashboard", provider: DashboardProvider()) { entry in
            DashboardWidgetView(entry: entry)
        }
        .configurationDisplayName("SpartanBody")
        .description("Calories, streak, and water at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct DashboardWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DashboardEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:    circularView
            case .accessoryRectangular: rectangularView
            case .accessoryInline:      Text("🔥\(entry.streak) · \(entry.calories) kcal")
            case .systemMedium:         mediumView
            default:                    smallView
            }
        }
        .widgetBackground()
    }

    // Ring used by small + medium
    private var ring: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 9)
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    AngularGradient(colors: [.wAccent, .wCyan, .wAccent], center: .center,
                                    startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(entry.calories)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("kcal")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            ring.frame(width: 84, height: 84)
            HStack(spacing: 10) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.system(size: 10)).foregroundColor(.orange)
                    Text("\(entry.streak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill").font(.system(size: 10)).foregroundColor(.wCyan)
                    Text("\(entry.water)/8")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 18) {
            ring.frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 9) {
                statRow(icon: "flame.fill", color: .orange,
                        text: "\(entry.calorieTarget - entry.calories) kcal",
                        sub: "→ \(entry.calorieTarget)")
                statRow(icon: "bolt.fill", color: .wAccent,
                        text: "\(entry.protein)g / \(entry.proteinTarget)g", sub: "P")
                HStack(spacing: 3) {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: i < entry.water ? "drop.fill" : "drop")
                            .font(.system(size: 11))
                            .foregroundColor(i < entry.water ? .wCyan : .white.opacity(0.25))
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(.orange)
                        Text("\(entry.streak)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func statRow(icon: String, color: Color, text: String, sub: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var circularView: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entry.calories)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill").font(.system(size: 11, weight: .bold))
                Text("SpartanBody").font(.system(size: 13, weight: .bold, design: .rounded))
            }
            Text("\(entry.calories) / \(entry.calorieTarget) kcal")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Text("🔥 \(entry.streak) · 💧 \(entry.water)/8")
                .font(.system(size: 12, design: .rounded))
        }
    }
}

// MARK: - Workout Live Activity (Dynamic Island + Lock Screen)

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen banner
            LockScreenWorkoutView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill").foregroundColor(.wAccent)
                        Text(context.attributes.workoutName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startedAt...Date(timeIntervalSinceNow: 86400),
                         countsDown: false)
                        .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.wCyan)
                        .frame(width: 60)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let restEnd = context.state.restEndDate, restEnd > .now {
                        HStack(spacing: 8) {
                            Image(systemName: "timer").foregroundColor(.orange)
                            Text("Rest")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Text(timerInterval: Date()...restEnd, countsDown: true)
                                .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 4)
                    } else {
                        HStack {
                            Label("\(context.state.exerciseCount)", systemImage: "list.bullet")
                            Spacer()
                            Text("\(context.state.setsDone)/\(context.state.totalSets) sets")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.wAccent)
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundColor(.wAccent)
            } compactTrailing: {
                if let restEnd = context.state.restEndDate, restEnd > .now {
                    Text(timerInterval: Date()...restEnd, countsDown: true)
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.orange)
                        .frame(width: 44)
                } else {
                    Text("\(context.state.setsDone)/\(context.state.totalSets)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.wCyan)
                }
            } minimal: {
                Image(systemName: "dumbbell.fill").foregroundColor(.wAccent)
            }
        }
    }
}

struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(Color.wAccent.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.wAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.workoutName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(context.state.setsDone)/\(context.state.totalSets) sets · \(context.state.exerciseCount) exercises")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if let restEnd = context.state.restEndDate, restEnd > .now {
                VStack(spacing: 1) {
                    Text(timerInterval: Date()...restEnd, countsDown: true)
                        .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundColor(.orange)
                        .frame(width: 70)
                    Text("rest")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                Text(timerInterval: context.attributes.startedAt...Date(timeIntervalSinceNow: 86400),
                     countsDown: false)
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.wCyan)
                    .frame(width: 80)
            }
        }
        .padding(16)
    }
}

// MARK: - Background helper (iOS 17 containerBackground / iOS 16 fallback)

private extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { Color.black }
        } else {
            background(Color.black)
        }
    }
}
