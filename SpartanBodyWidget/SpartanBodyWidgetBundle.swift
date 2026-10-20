import WidgetKit
import SwiftUI
import ActivityKit

@main
struct SpartanBodyWidgets: WidgetBundle {
    var body: some Widget {
        SpartanDashboardWidget()
        WorkoutLiveActivity()
        RunLiveActivity()
    }
}

// MARK: - Shared style (self-contained — the extension doesn't link app code)

private extension Color {
    static let wAccent = Color(red: 0.04, green: 0.52, blue: 1.0)    // #0A84FF
    static let wCyan   = Color(red: 0.20, green: 0.84, blue: 0.91)   // #32D5E8
}

private let appGroupID = "group.com.oswaldo.powerpump"

// MARK: - Texts (the extension has no string catalog; the app shares the
// language the user picked in it, which can differ from the phone's)

private let widgetTexts: [String: [String: String]] = [
    "run":       ["en": "Run", "es": "Correr", "fr": "Course", "it": "Corsa", "pt": "Corrida"],
    "walk":      ["en": "Walk", "es": "Caminar", "fr": "Marche", "it": "Camminata", "pt": "Caminhada"],
    "hike":      ["en": "Hike", "es": "Senderismo", "fr": "Randonnée", "it": "Trekking", "pt": "Trilha"],
    "paused":    ["en": "PAUSED", "es": "EN PAUSA", "fr": "EN PAUSE", "it": "IN PAUSA", "pt": "PAUSADO"],
    "rest":      ["en": "Rest", "es": "Descanso", "fr": "Repos", "it": "Riposo", "pt": "Descanso"],
    "sets":      ["en": "sets", "es": "series", "fr": "séries", "it": "serie", "pt": "séries"],
    "exercises": ["en": "exercises", "es": "ejercicios", "fr": "exercices", "it": "esercizi", "pt": "exercícios"],
    "about":     ["en": "Calories, streak and water at a glance.",
                  "es": "Calorías, racha y agua de un vistazo.",
                  "fr": "Calories, série et eau en un coup d'œil.",
                  "it": "Calorie, serie e acqua a colpo d'occhio.",
                  "pt": "Calorias, sequência e água de relance."],
]

private func WL(_ key: String) -> String {
    let code = UserDefaults(suiteName: appGroupID)?.string(forKey: "sb_language")
        ?? Locale.preferredLanguages.first ?? "en"
    let lang = String(code.prefix(2))
    return widgetTexts[key]?[lang] ?? widgetTexts[key]?["en"] ?? key
}

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
        .configurationDisplayName("PowerPump")
        .description(Text(verbatim: WL("about")))
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
                Text("PowerPump").font(.system(size: 13, weight: .bold, design: .rounded))
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
                            Text(verbatim: WL("rest"))
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
                            Text(verbatim: "\(context.state.setsDone)/\(context.state.totalSets) \(WL("sets"))")
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
                Text(verbatim: "\(context.state.setsDone)/\(context.state.totalSets) \(WL("sets")) · \(context.state.exerciseCount) \(WL("exercises"))")
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
                    Text(verbatim: WL("rest").lowercased())
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

// MARK: - Run Live Activity (Dynamic Island + Lock Screen)

struct RunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            LockScreenRunView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: runIcon(context.attributes.activityRaw))
                            .foregroundColor(.wAccent)
                        Text(runLabel(context.attributes.activityRaw))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatDistance(context.state.distanceMeters))
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.wCyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 14) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill").font(.system(size: 11, weight: .bold))
                            runClock(context.state)
                                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        }
                        .foregroundColor(.white)
                        runStat(icon: "speedometer",
                                value: formatPace(context.state.paceSecondsPerKm),
                                color: .wAccent)
                        runStat(icon: "flame.fill",
                                value: "\(context.state.calories)",
                                color: .orange)
                        Spacer()
                        if context.state.isPaused {
                            Text(verbatim: WL("paused"))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: runIcon(context.attributes.activityRaw))
                    .foregroundColor(.wAccent)
            } compactTrailing: {
                Text(formatDistance(context.state.distanceMeters))
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.wCyan)
            } minimal: {
                Image(systemName: runIcon(context.attributes.activityRaw))
                    .foregroundColor(.wAccent)
            }
        }
    }
}

struct LockScreenRunView: View {
    let context: ActivityViewContext<RunActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(Color.wAccent.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: runIcon(context.attributes.activityRaw))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.wAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(runLabel(context.attributes.activityRaw))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if context.state.isPaused {
                        Text(verbatim: WL("paused"))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 10) {
                    Text(formatDistance(context.state.distanceMeters))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.wCyan)
                    Text("· \(formatPace(context.state.paceSecondsPerKm)) /km")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text("· \(context.state.calories) kcal")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.orange.opacity(0.85))
                }
            }

            Spacer()

            runClock(context.state)
                .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90, alignment: .trailing)
                .foregroundColor(.white)
        }
        .padding(16)
    }
}

// MARK: - Formatting helpers (extension-local, no app code dependency)

private func runIcon(_ raw: String) -> String {
    switch raw {
    case "Walk": return "figure.walk"
    case "Hike": return "figure.hiking"
    default:     return "figure.run"
    }
}

private func runLabel(_ raw: String) -> String {
    switch raw {
    case "Walk": return WL("walk")
    case "Hike": return WL("hike")
    default:     return WL("run")
    }
}

/// Moving time. While running it ticks on its own (the app only updates the
/// activity on GPS fixes, so a fixed number froze between them).
@ViewBuilder
private func runClock(_ state: RunActivityAttributes.ContentState) -> some View {
    if let start = state.clockStart, !state.isPaused {
        Text(timerInterval: start...Date(timeIntervalSinceNow: 86400), countsDown: false)
    } else {
        Text(verbatim: formatTime(state.movingSeconds))
    }
}

private func formatDistance(_ meters: Double) -> String {
    let km = meters / 1000
    return km < 10 ? String(format: "%.2f km", km) : String(format: "%.1f km", km)
}

private func formatTime(_ seconds: TimeInterval) -> String {
    let s = Int(seconds)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                 : String(format: "%d:%02d", m, sec)
}

private func formatPace(_ secondsPerKm: Double) -> String {
    guard secondsPerKm > 0, secondsPerKm.isFinite else { return "--:--" }
    let s = Int(secondsPerKm)
    return String(format: "%d:%02d", s / 60, s % 60)
}

private func runStat(icon: String, value: String, color: Color) -> some View {
    HStack(spacing: 4) {
        Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(color)
        Text(value)
            .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundColor(.white)
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
